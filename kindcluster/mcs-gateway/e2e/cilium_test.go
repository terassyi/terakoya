package e2e

import (
	"encoding/json"
	"fmt"
	"net/netip"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test images (docs/cilium.md 7). Pinned by digest.
const (
	agnhostImage  = "registry.k8s.io/e2e-test-images/agnhost:2.61@sha256:101f3357d1ad890c3090e78ea6c6a47dc5137cbe19836796e13d5dcb2b84d2e6"
	netshootImage = "nicolaka/netshoot:v0.16@sha256:b09d9b21381f47a79b3cbcb30da25266dc17186ea00ae65e99fdc51396f48e70"
)

const ciliumTestNS = "cilium-test"

// podPool returns the CIDR of the default CiliumPodIPPool of a cluster (docs/network.md 3.1).
func podPool(t *testing.T, cluster string) netip.Prefix {
	t.Helper()
	for i, c := range clusters {
		if c == cluster {
			return netip.MustParsePrefix(fmt.Sprintf("10.%d.0.0/16", 100+i))
		}
	}
	t.Fatalf("unknown cluster %q", cluster)
	return netip.Prefix{}
}

// ciliumTestManifest places agnhost on worker2 and netshoot on worker, and
// exposes agnhost with a NodePort Service (it also has a ClusterIP).
func ciliumTestManifest(cluster string) string {
	return fmt.Sprintf(`apiVersion: v1
kind: Namespace
metadata:
  name: %[1]s
---
apiVersion: v1
kind: Pod
metadata:
  name: agnhost
  namespace: %[1]s
  labels:
    app: agnhost
spec:
  nodeName: %[2]s-worker2
  containers:
    - name: agnhost
      image: %[3]s
      args: ["netexec", "--http-port=8080"]
      ports:
        - containerPort: 8080
      readinessProbe:
        httpGet:
          path: /healthz
          port: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: netshoot
  namespace: %[1]s
spec:
  nodeName: %[2]s-worker
  containers:
    - name: netshoot
      image: %[4]s
      command: ["sleep", "infinity"]
---
apiVersion: v1
kind: Service
metadata:
  name: agnhost
  namespace: %[1]s
spec:
  type: NodePort
  selector:
    app: agnhost
  ports:
    - port: 80
      targetPort: 8080
`, ciliumTestNS, cluster, agnhostImage, netshootImage)
}

type podInfo struct {
	Status struct {
		PodIP string `json:"podIP"`
	} `json:"status"`
}

type serviceInfo struct {
	Spec struct {
		ClusterIP string `json:"clusterIP"`
		Ports     []struct {
			NodePort int `json:"nodePort"`
		} `json:"ports"`
	} `json:"spec"`
}

// netshootCurl runs curl in the netshoot test Pod of a cluster.
func netshootCurl(cluster string, args ...string) ([]byte, error) {
	return kubectlExec(cluster, ciliumTestNS, "netshoot", append([]string{"curl", "-sS", "--max-time", "10"}, args...)...)
}

// clientIP returns the host part of agnhost's /clientip response ("ip:port").
func clientIP(t *testing.T, out []byte) string {
	t.Helper()
	ap, err := netip.ParseAddrPort(strings.TrimSpace(string(out)))
	require.NoError(t, err, "clientip response %q", out)
	return ap.Addr().String()
}

// TestCilium checks Cilium with KPR and multi-pool IPAM (docs/cilium.md 7.1).
func TestCilium(t *testing.T) {
	// All nodes are Ready.
	t.Run("cilium-01", func(t *testing.T) {
		for _, c := range clusters {
			var list struct {
				Items []struct {
					Metadata struct {
						Name string `json:"name"`
					} `json:"metadata"`
					Status struct {
						Conditions []struct {
							Type   string `json:"type"`
							Status string `json:"status"`
						} `json:"conditions"`
					} `json:"status"`
				} `json:"items"`
			}
			require.NoError(t, getResource(c, "", "nodes", "", &list))
			assert.Len(t, list.Items, 3, c)
			for _, n := range list.Items {
				ready := ""
				for _, cond := range n.Status.Conditions {
					if cond.Type == "Ready" {
						ready = cond.Status
					}
				}
				assert.Equal(t, "True", ready, n.Metadata.Name)
			}
		}
	})

	// cilium status is OK.
	t.Run("cilium-02", func(t *testing.T) {
		for _, c := range clusters {
			_, err := run(nil, "cilium", "status", "--wait", "--wait-duration", "2m", "--context", "kind-"+c)
			assert.NoError(t, err, c)
		}
	})

	// kube-proxy is absent and every agent runs with KPR.
	t.Run("cilium-03", func(t *testing.T) {
		for _, c := range clusters {
			_, err := kubectl(c, nil, "-n", "kube-system", "get", "ds", "kube-proxy")
			if assert.Error(t, err, c) {
				assert.Contains(t, err.Error(), "NotFound", c)
			}

			var pods struct {
				Items []struct {
					Metadata struct {
						Name string `json:"name"`
					} `json:"metadata"`
				} `json:"items"`
			}
			require.NoError(t, json.Unmarshal(mustKubectl(t, c, nil, "-n", "kube-system", "get", "pods", "-l", "k8s-app=cilium", "-o", "json"), &pods))
			assert.Len(t, pods.Items, 3, "cilium agents in %s", c)
			for _, p := range pods.Items {
				out, err := kubectl(c, nil, "-n", "kube-system", "exec", p.Metadata.Name, "-c", "cilium-agent", "--",
					"cilium-dbg", "status", "--output", "json")
				if !assert.NoError(t, err, p.Metadata.Name) {
					continue
				}
				var st struct {
					KubeProxyReplacement struct {
						Mode string `json:"mode"`
					} `json:"kube-proxy-replacement"`
				}
				require.NoError(t, json.Unmarshal(out, &st))
				assert.Equal(t, "True", st.KubeProxyReplacement.Mode, p.Metadata.Name)
			}
		}
	})

	// Every node has a /24 of the cluster's default pool.
	t.Run("cilium-04", func(t *testing.T) {
		for _, c := range clusters {
			pool := podPool(t, c)
			var list struct {
				Items []struct {
					Metadata struct {
						Name string `json:"name"`
					} `json:"metadata"`
					Spec struct {
						IPAM struct {
							Pools struct {
								Allocated []struct {
									Pool  string   `json:"pool"`
									CIDRs []string `json:"cidrs"`
								} `json:"allocated"`
							} `json:"pools"`
						} `json:"ipam"`
					} `json:"spec"`
				} `json:"items"`
			}
			require.NoError(t, getResource(c, "", "ciliumnodes", "", &list))
			assert.Len(t, list.Items, 3, c)
			for _, n := range list.Items {
				var cidrs []string
				for _, a := range n.Spec.IPAM.Pools.Allocated {
					if a.Pool == "default" {
						cidrs = append(cidrs, a.CIDRs...)
					}
				}
				if !assert.NotEmpty(t, cidrs, n.Metadata.Name) {
					continue
				}
				for _, s := range cidrs {
					p, err := netip.ParsePrefix(s)
					require.NoError(t, err)
					assert.Equal(t, 24, p.Bits(), "%s: %s", n.Metadata.Name, s)
					assert.True(t, pool.Contains(p.Addr()), "%s: %s not in %s", n.Metadata.Name, s, pool)
				}
			}
		}
	})

	// Test Pods for cilium-05 and later.
	for _, c := range clusters {
		applyManifest(t, c, ciliumTestManifest(c))
	}
	for _, c := range clusters {
		mustKubectl(t, c, nil, "-n", ciliumTestNS, "wait", "--for", "condition=Ready", "pod", "--all", "--timeout", "5m")
	}
	pods := map[string]map[string]podInfo{}
	svcs := map[string]serviceInfo{}
	for _, c := range clusters {
		pods[c] = map[string]podInfo{}
		for _, name := range []string{"agnhost", "netshoot"} {
			var p podInfo
			require.NoError(t, getResource(c, ciliumTestNS, "pod", name, &p))
			pods[c][name] = p
		}
		var s serviceInfo
		require.NoError(t, getResource(c, ciliumTestNS, "service", "agnhost", &s))
		require.Len(t, s.Spec.Ports, 1)
		svcs[c] = s
	}

	// Pod IPs are in the cluster's pool.
	t.Run("cilium-05", func(t *testing.T) {
		for _, c := range clusters {
			pool := podPool(t, c)
			for name, p := range pods[c] {
				ip, err := netip.ParseAddr(p.Status.PodIP)
				if assert.NoError(t, err, "%s/%s", c, name) {
					assert.True(t, pool.Contains(ip), "%s/%s: %s not in %s", c, name, ip, pool)
				}
			}
		}
	})

	// Pod to Pod across nodes, without SNAT.
	t.Run("cilium-06", func(t *testing.T) {
		for _, c := range clusters {
			out, err := netshootCurl(c, fmt.Sprintf("http://%s:8080/clientip", pods[c]["agnhost"].Status.PodIP))
			if assert.NoError(t, err, c) {
				assert.Equal(t, pods[c]["netshoot"].Status.PodIP, clientIP(t, out), c)
			}
		}
	})

	// ClusterIP from a Pod.
	t.Run("cilium-07", func(t *testing.T) {
		for _, c := range clusters {
			_, err := netshootCurl(c, fmt.Sprintf("http://%s/clientip", svcs[c].Spec.ClusterIP))
			assert.NoError(t, err, c)
		}
	})

	// NodePort from the host on every node, including nodes without agnhost.
	t.Run("cilium-08", func(t *testing.T) {
		for _, n := range labNodes() {
			_, err := hostCurl("-sS", "--max-time", "10", fmt.Sprintf("http://%s:%d/clientip", n.ip, svcs[n.cluster].Spec.Ports[0].NodePort))
			assert.NoError(t, err, n.name)
		}
	})

	// Pod to the API server (out via eth0, back via node0; docs/cilium.md 3.1).
	t.Run("cilium-09", func(t *testing.T) {
		for _, c := range clusters {
			out, err := netshootCurl(c, "-k", "https://kubernetes.default.svc/livez")
			if assert.NoError(t, err, c) {
				assert.Equal(t, "ok", strings.TrimSpace(string(out)), c)
			}
		}
	})

	// Pod resolves an external name through the cluster CoreDNS and dns0 (docs/cilium.md 2.4).
	t.Run("cilium-10", func(t *testing.T) {
		for _, c := range clusters {
			out, err := kubectlExec(c, ciliumTestNS, "netshoot", "dig", "+short", "+time=5", "+tries=2", "registry.k8s.io")
			if assert.NoError(t, err, c) {
				assert.NotEmpty(t, aRecords(out), "%s: %q", c, out)
			}
		}
	})

	// Pod to the internet through the eBPF masquerade and the spine NAT.
	t.Run("cilium-11", func(t *testing.T) {
		for _, c := range clusters {
			out, err := netshootCurl(c, "-o", "/dev/null", "-w", "%{http_code}", "https://registry.k8s.io/v2/")
			if assert.NoError(t, err, c) {
				assert.NotEqual(t, "000", strings.TrimSpace(string(out)), c)
			}
		}
	})
}
