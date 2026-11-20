package e2e

import (
	"fmt"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// gatewayStatus is the part of a Gateway's status that the tests read.
type gatewayStatus struct {
	Status struct {
		Addresses []struct {
			Value string `json:"value"`
		} `json:"addresses"`
		Conditions []struct {
			Type   string `json:"type"`
			Status string `json:"status"`
		} `json:"conditions"`
	} `json:"status"`
}

// waitGatewayVIP waits until the Gateway is Programmed and returns its address.
func waitGatewayVIP(t *testing.T, cluster, ns, name string) string {
	t.Helper()
	var vip string
	require.EventuallyWithT(t, func(ct *assert.CollectT) {
		var gw gatewayStatus
		if !assert.NoError(ct, getResource(cluster, ns, "gateway", name, &gw)) {
			return
		}
		programmed := false
		for _, c := range gw.Status.Conditions {
			programmed = programmed || (c.Type == "Programmed" && c.Status == "True")
		}
		assert.True(ct, programmed, "gateway %s/%s is not Programmed", ns, name)
		if assert.NotEmpty(ct, gw.Status.Addresses, "gateway %s/%s has no address", ns, name) {
			vip = gw.Status.Addresses[0].Value
		}
	}, eventuallyTimeout, eventuallyTick)
	return vip
}

// TestGateway checks the edge Gateway with a backend in edge (docs/envoy-gateway.md 4.1).
func TestGateway(t *testing.T) {
	vip := waitGatewayVIP(t, "edge", "demo", "gw")
	// deploy-gateway does not wait for the route; the host reaches the VIP through spine0.
	require.EventuallyWithT(t, func(ct *assert.CollectT) {
		routes, err := bgpRoutes("spine0")
		if assert.NoError(ct, err) {
			assert.NotEmpty(ct, activeNexthops(routes[vip+"/32"]), "spine0 %s/32", vip)
		}
	}, eventuallyTimeout, eventuallyTick)

	// The host reaches the echo in edge through the Gateway VIP.
	t.Run("gateway-01", func(t *testing.T) {
		out, err := hostCurl("-sS", "--max-time", "10", "-w", "\n%{http_code}",
			"-H", "Host: echo-local.mcs.example", fmt.Sprintf("http://%s/", vip))
		require.NoError(t, err, "%s", out)
		body, code, _ := strings.Cut(strings.TrimSpace(string(out)), "\n")
		assert.Equal(t, "200", code)
		assert.True(t, strings.HasPrefix(body, "node=edge-"), "body: %q", body)
	})
}
