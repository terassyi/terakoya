package e2e

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestFabric checks the containerlab fabric (docs/network.md 6).
// fabric-10 and fabric-11 are checked by the reproducibility procedure.
func TestFabric(t *testing.T) {
	// spine0 has Established sessions with all ToRs.
	t.Run("fabric-01", func(t *testing.T) {
		tors := []string{"10.255.0.1", "10.255.0.3", "10.255.0.5"}
		assert.EventuallyWithT(t, func(c *assert.CollectT) {
			var sum struct {
				IPv4Unicast struct {
					Peers map[string]struct {
						State string `json:"state"`
					} `json:"peers"`
				} `json:"ipv4Unicast"`
			}
			if !assert.NoError(c, vtyshJSON("spine0", "show bgp summary", &sum)) {
				return
			}
			assert.Len(c, sum.IPv4Unicast.Peers, len(tors))
			for _, ip := range tors {
				assert.Equal(c, "Established", sum.IPv4Unicast.Peers[ip].State, "peer %s", ip)
			}
		}, eventuallyTimeout, eventuallyTick)
	})

	// Every node has its address on node0.
	t.Run("fabric-02", func(t *testing.T) {
		for _, n := range labNodes() {
			out, err := sidecarExec(n.name, "ip", "-j", "-4", "addr", "show", "dev", "node0")
			require.NoError(t, err)
			var links []struct {
				AddrInfo []struct {
					Local     string `json:"local"`
					PrefixLen int    `json:"prefixlen"`
				} `json:"addr_info"`
			}
			require.NoError(t, json.Unmarshal(out, &links))
			require.Len(t, links, 1, n.name)
			var addrs []string
			for _, a := range links[0].AddrInfo {
				addrs = append(addrs, a.Local)
			}
			assert.Contains(t, addrs, n.ip, n.name)
		}
	})

	// Every node's default route goes to its ToR via node0.
	t.Run("fabric-03", func(t *testing.T) {
		for _, n := range labNodes() {
			out, err := sidecarExec(n.name, "ip", "-j", "-4", "route", "show", "default")
			require.NoError(t, err)
			var routes []struct {
				Gateway string `json:"gateway"`
				Dev     string `json:"dev"`
			}
			require.NoError(t, json.Unmarshal(out, &routes))
			require.Len(t, routes, 1, n.name)
			assert.Equal(t, n.gw, routes[0].Gateway, n.name)
			assert.Equal(t, "node0", routes[0].Dev, n.name)
		}
	})

	// Every node reaches its ToR GW.
	t.Run("fabric-04", func(t *testing.T) {
		for _, n := range labNodes() {
			_, err := sidecarExec(n.name, "ping", "-c", "1", "-W", "2", n.gw)
			assert.NoError(t, err, n.name)
		}
	})

	// edge-worker reaches nodes of the other clusters through spine0.
	t.Run("fabric-05", func(t *testing.T) {
		for _, dst := range []string{"core1-worker", "core2-worker"} {
			_, err := sidecarExec("edge-worker", "ping", "-c", "1", "-W", "2", findNode(t, dst).ip)
			assert.NoError(t, err, dst)
		}
	})

	// The host reaches spine0.
	t.Run("fabric-06", func(t *testing.T) {
		_, err := run(nil, "ping", "-c", "1", "-W", "2", "172.30.0.2")
		assert.NoError(t, err)
	})

	// The host reaches every node.
	t.Run("fabric-07", func(t *testing.T) {
		for _, n := range labNodes() {
			_, err := run(nil, "ping", "-c", "1", "-W", "2", n.ip)
			assert.NoError(t, err, n.name)
		}
	})

	// The INTERNAL-IP of every Node is its node0 address.
	t.Run("fabric-08", func(t *testing.T) {
		want := map[string]string{}
		for _, n := range labNodes() {
			want[n.name] = n.ip
		}
		for _, c := range clusters {
			var list struct {
				Items []struct {
					Metadata struct {
						Name string `json:"name"`
					} `json:"metadata"`
					Status struct {
						Addresses []struct {
							Type    string `json:"type"`
							Address string `json:"address"`
						} `json:"addresses"`
					} `json:"status"`
				} `json:"items"`
			}
			require.NoError(t, getResource(c, "", "nodes", "", &list))
			require.Len(t, list.Items, 3, c)
			for _, node := range list.Items {
				var internal []string
				for _, a := range node.Status.Addresses {
					if a.Type == "InternalIP" {
						internal = append(internal, a.Address)
					}
				}
				assert.Equal(t, []string{want[node.Metadata.Name]}, internal, node.Metadata.Name)
			}
		}
	})

	// Nodes reach the internet through the NAT on spine0 (image pulls take this path).
	t.Run("fabric-09", func(t *testing.T) {
		for _, c := range clusters {
			out, err := sidecarExec(c+"-control-plane", "curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}",
				"--max-time", "15", "https://registry.k8s.io/v2/")
			if assert.NoError(t, err, c) {
				code := strings.TrimSpace(string(out))
				assert.NotEqual(t, "000", code, c)
			}
		}
	})
}
