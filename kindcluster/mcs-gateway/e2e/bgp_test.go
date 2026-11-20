package e2e

import (
	"fmt"
	"net/netip"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test namespaces (docs/cilium.md 7.2). bgpTestNS is selected by the routable pool
// (cilium/ipam/<cluster>.yaml); bgpDefaultNS uses the default pool.
const (
	bgpTestNS    = "bgp-test"
	bgpDefaultNS = "bgp-default"
)

type bgpSummary struct {
	IPv4Unicast struct {
		Peers map[string]struct {
			State string `json:"state"`
		} `json:"peers"`
	} `json:"ipv4Unicast"`
}

type ciliumNodeList struct {
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

type lbService struct {
	Status struct {
		LoadBalancer struct {
			Ingress []struct {
				IP string `json:"ip"`
			} `json:"ingress"`
		} `json:"loadBalancer"`
	} `json:"status"`
}

// nodeBlocks returns the blocks of a pool allocated to each node of a cluster, keyed by node name.
func nodeBlocks(t *testing.T, cluster, pool string) map[string][]string {
	t.Helper()
	var list ciliumNodeList
	require.NoError(t, getResource(cluster, "", "ciliumnodes", "", &list))
	blocks := map[string][]string{}
	for _, n := range list.Items {
		for _, a := range n.Spec.IPAM.Pools.Allocated {
			if a.Pool == pool {
				blocks[n.Metadata.Name] = append(blocks[n.Metadata.Name], a.CIDRs...)
			}
		}
	}
	return blocks
}

// waitLBIP waits for the LoadBalancer IP of a Service.
func waitLBIP(t *testing.T, cluster, ns, name string) string {
	t.Helper()
	var ip string
	require.EventuallyWithT(t, func(c *assert.CollectT) {
		var s lbService
		if !assert.NoError(c, getResource(cluster, ns, "service", name, &s)) {
			return
		}
		if assert.Len(c, s.Status.LoadBalancer.Ingress, 1) {
			ip = s.Status.LoadBalancer.Ingress[0].IP
		}
	}, eventuallyTimeout, eventuallyTick)
	return ip
}

// lbPool returns the LB IPAM pool of a cluster (docs/network.md 3.1).
func lbPool(t *testing.T, cluster string) netip.Prefix {
	t.Helper()
	return netip.MustParsePrefix(fmt.Sprintf("10.%d.0.0/24", 80+clusterIndex(t, cluster)))
}

// clusterNodeIPs returns the node0 addresses of a cluster.
func clusterNodeIPs(cluster string) []string {
	var ips []string
	for _, n := range labNodes() {
		if n.cluster == cluster {
			ips = append(ips, n.ip)
		}
	}
	return ips
}

// TestBGP checks BGP, LB IPAM, the pools and the spine0 ACL (docs/cilium.md 7.2).
func TestBGP(t *testing.T) {
	for _, c := range clusters {
		applyManifest(t, c, testPodsManifest(bgpTestNS, c, true, "LoadBalancer"))
		applyManifest(t, c, testPodsManifest(bgpDefaultNS, c, false, ""))
	}
	pods := map[string]map[string]string{} // cluster -> "<ns>/<pod>" -> Pod IP
	vips := map[string]string{}
	for _, c := range clusters {
		for _, ns := range []string{bgpTestNS, bgpDefaultNS} {
			mustKubectl(t, c, nil, "-n", ns, "wait", "--for", "condition=Ready", "pod", "--all", "--timeout", "5m")
		}
		pods[c] = map[string]string{}
		for _, p := range []struct{ ns, name, pool string }{
			{bgpTestNS, "agnhost", "routable"},
			{bgpTestNS, "netshoot", "routable"},
			{bgpDefaultNS, "netshoot", "default"},
		} {
			var info podInfo
			require.NoError(t, getResource(c, p.ns, "pod", p.name, &info))
			ip := netip.MustParseAddr(info.Status.PodIP)
			// The pools are selected by namespace (docs/cilium.md 3); every later check relies on it.
			require.True(t, poolCIDR(t, c, p.pool).Contains(ip), "%s %s/%s: %s not in the %s pool", c, p.ns, p.name, ip, p.pool)
			pods[c][p.ns+"/"+p.name] = ip.String()
		}
		vips[c] = waitLBIP(t, c, bgpTestNS, "agnhost")
	}
	// deploy-bgp does not wait for the routes. Wait here, so that each subtest can also run alone
	// (task test ID=...); bgp-01..03 check the details of the routes.
	var prefixes []string
	for _, c := range clusters {
		for _, blocks := range nodeBlocks(t, c, "routable") {
			prefixes = append(prefixes, blocks...)
		}
		prefixes = append(prefixes, vips[c]+"/32")
	}
	require.EventuallyWithT(t, func(ct *assert.CollectT) {
		for _, r := range []string{"spine0", "tor-edge", "tor-core1", "tor-core2"} {
			routes, err := bgpRoutes(r)
			if !assert.NoError(ct, err) {
				return
			}
			for _, p := range prefixes {
				assert.NotEmpty(ct, activeNexthops(routes[p]), "%s %s", r, p)
			}
		}
	}, eventuallyTimeout, eventuallyTick)

	// Every node of a cluster has a session with its ToR.
	t.Run("bgp-01", func(t *testing.T) {
		for _, c := range clusters {
			subnet := netip.MustParsePrefix(fmt.Sprintf("10.69.%d.0/24", clusterIndex(t, c)))
			assert.EventuallyWithT(t, func(ct *assert.CollectT) {
				var sum bgpSummary
				if !assert.NoError(ct, vtyshJSON("tor-"+c, "show bgp summary", &sum)) {
					return
				}
				var nodes []string
				for ip := range sum.IPv4Unicast.Peers {
					if a, err := netip.ParseAddr(ip); err == nil && subnet.Contains(a) {
						nodes = append(nodes, ip)
					}
				}
				assert.ElementsMatch(ct, clusterNodeIPs(c), nodes, c)
				for _, ip := range clusterNodeIPs(c) {
					assert.Equal(ct, "Established", sum.IPv4Unicast.Peers[ip].State, "%s %s", c, ip)
				}
			}, eventuallyTimeout, eventuallyTick)
		}
	})

	// The ToR and spine0 have the routable blocks, and neither has the default blocks.
	t.Run("bgp-02", func(t *testing.T) {
		for _, c := range clusters {
			routable := nodeBlocks(t, c, "routable")
			def := nodeBlocks(t, c, "default")
			// A pool's block is allocated only to nodes that run Pods of the pool (docs/cilium.md 3).
			require.NotEmpty(t, routable, c)
			assert.EventuallyWithT(t, func(ct *assert.CollectT) {
				tor, err := bgpRoutes("tor-" + c)
				if !assert.NoError(ct, err) {
					return
				}
				spine, err := bgpRoutes("spine0")
				if !assert.NoError(ct, err) {
					return
				}
				for node, blocks := range routable {
					for _, b := range blocks {
						assert.Equal(ct, []string{findNode(t, node).ip}, activeNexthops(tor[b]), "tor-%s %s (%s)", c, b, node)
						assert.Equal(ct, []string{torUplink(t, c)}, activeNexthops(spine[b]), "spine0 %s (%s)", b, node)
					}
				}
				for node, blocks := range def {
					for _, b := range blocks {
						assert.NotContains(ct, tor, b, "tor-%s default block of %s", c, node)
						assert.NotContains(ct, spine, b, "spine0 default block of %s", node)
					}
				}
			}, eventuallyTimeout, eventuallyTick)
		}
	})

	// The VIP comes from the cluster's LB pool; the ToR has it by ECMP to all nodes.
	t.Run("bgp-03", func(t *testing.T) {
		for _, c := range clusters {
			vip := netip.MustParseAddr(vips[c])
			assert.True(t, lbPool(t, c).Contains(vip), "%s: %s not in %s", c, vip, lbPool(t, c))
			prefix := vip.String() + "/32"
			assert.EventuallyWithT(t, func(ct *assert.CollectT) {
				tor, err := bgpRoutes("tor-" + c)
				if !assert.NoError(ct, err) {
					return
				}
				spine, err := bgpRoutes("spine0")
				if !assert.NoError(ct, err) {
					return
				}
				assert.ElementsMatch(ct, clusterNodeIPs(c), activeNexthops(tor[prefix]), "tor-%s %s", c, prefix)
				assert.Equal(ct, []string{torUplink(t, c)}, activeNexthops(spine[prefix]), "spine0 %s", prefix)
			}, eventuallyTimeout, eventuallyTick)
		}
	})

	// edge routable Pods reach core routable Pods without SNAT (also checks skip-masquerade).
	t.Run("bgp-04", func(t *testing.T) {
		for _, dst := range []string{"core1", "core2"} {
			out, err := podCurl("edge", bgpTestNS, fmt.Sprintf("http://%s:8080/clientip", pods[dst][bgpTestNS+"/agnhost"]))
			if assert.NoError(t, err, dst) {
				assert.Equal(t, pods["edge"][bgpTestNS+"/netshoot"], clientIP(t, out), dst)
			}
		}
	})

	// core routable Pods do not open connections to edge or to the other core.
	t.Run("bgp-05", func(t *testing.T) {
		for _, p := range [][2]string{{"core1", "edge"}, {"core1", "core2"}, {"core2", "edge"}, {"core2", "core1"}} {
			assertRejected(t, func() error {
				_, err := podCurl(p[0], bgpTestNS, fmt.Sprintf("http://%s:8080/clientip", pods[p[1]][bgpTestNS+"/agnhost"]))
				return err
			}, "%s -> %s", p[0], p[1])
		}
	})

	// default Pods do not reach Pods of other clusters (SNATed to the node, then rejected).
	t.Run("bgp-06", func(t *testing.T) {
		assertRejected(t, func() error {
			_, err := podCurl("edge", bgpDefaultNS, fmt.Sprintf("http://%s:8080/clientip", pods["core1"][bgpTestNS+"/agnhost"]))
			return err
		})
	})

	// L4LB between all clusters, from both pools.
	t.Run("bgp-07", func(t *testing.T) {
		for _, src := range clusters {
			for _, dst := range clusters {
				if src == dst {
					continue
				}
				for _, ns := range []string{bgpTestNS, bgpDefaultNS} {
					_, err := podCurl(src, ns, fmt.Sprintf("http://%s/clientip", vips[dst]))
					assert.NoError(t, err, "%s/%s -> %s VIP", src, ns, dst)
				}
			}
		}
	})

	// The host reaches the edge VIP only.
	t.Run("bgp-08", func(t *testing.T) {
		for _, c := range clusters {
			curl := func() error {
				_, err := hostCurl("-sS", "--max-time", "10", fmt.Sprintf("http://%s/clientip", vips[c]))
				return err
			}
			if c == "edge" {
				assert.NoError(t, curl(), c)
			} else {
				assertRejected(t, curl, c)
			}
		}
	})

	// Deleting a LoadBalancer Service withdraws its VIP.
	t.Run("bgp-09", func(t *testing.T) {
		manifest := fmt.Sprintf(`apiVersion: v1
kind: Service
metadata:
  name: withdraw
  namespace: %s
spec:
  type: LoadBalancer
  selector:
    app: agnhost
  ports:
    - port: 80
      targetPort: 8080
`, bgpTestNS)
		applyManifest(t, "edge", manifest)
		prefix := waitLBIP(t, "edge", bgpTestNS, "withdraw") + "/32"
		routed := func(present bool) {
			assert.EventuallyWithT(t, func(ct *assert.CollectT) {
				for _, r := range []string{"tor-edge", "spine0"} {
					routes, err := bgpRoutes(r)
					if !assert.NoError(ct, err) {
						return
					}
					if present {
						assert.Contains(ct, routes, prefix, r)
					} else {
						assert.NotContains(ct, routes, prefix, r)
					}
				}
			}, eventuallyTimeout, eventuallyTick)
		}
		routed(true)
		mustKubectl(t, "edge", []byte(manifest), "delete", "--wait", "-f", "-")
		routed(false)
	})

	// routable Pods reach the internet through the spine NAT.
	t.Run("bgp-10", func(t *testing.T) {
		out, err := podCurl("edge", bgpTestNS, "-o", "/dev/null", "-w", "%{http_code}", "https://registry.k8s.io/v2/")
		if assert.NoError(t, err) {
			assert.NotEqual(t, "000", strings.TrimSpace(string(out)))
		}
	})
}
