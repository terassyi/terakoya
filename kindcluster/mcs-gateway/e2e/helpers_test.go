package e2e

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

// Defaults for assert.EventuallyWithT.
const (
	eventuallyTimeout = 5 * time.Minute
	eventuallyTick    = 1 * time.Second
)

// clusters are the kind cluster names. The kube context is "kind-<cluster>".
var clusters = []string{"edge", "core1", "core2"}

// run executes a command and returns its stdout.
// On failure, the error includes the command line and stderr.
func run(input []byte, name string, args ...string) ([]byte, error) {
	cmd := exec.Command(name, args...)
	if input != nil {
		cmd.Stdin = bytes.NewReader(input)
	}
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return stdout.Bytes(), fmt.Errorf("%s %s: %w: %s", name, strings.Join(args, " "), err, stderr.String())
	}
	return stdout.Bytes(), nil
}

// kubectl runs kubectl against the given cluster. input is passed as stdin if not nil.
func kubectl(cluster string, input []byte, args ...string) ([]byte, error) {
	return run(input, "kubectl", append([]string{"--context", "kind-" + cluster}, args...)...)
}

func mustKubectl(t *testing.T, cluster string, input []byte, args ...string) []byte {
	t.Helper()
	out, err := kubectl(cluster, input, args...)
	require.NoError(t, err)
	return out
}

// getResource reads `kubectl get -o json` into obj. ns may be empty for
// cluster-scoped resources. If name is empty, obj must be a list type.
func getResource(cluster, ns, resource, name string, obj any) error {
	args := []string{"get", resource, "-o", "json"}
	if ns != "" {
		args = append(args, "-n", ns)
	}
	if name != "" {
		args = append(args, name)
	}
	out, err := kubectl(cluster, nil, args...)
	if err != nil {
		return err
	}
	return json.Unmarshal(out, obj)
}

// kubectlExec runs a command in a pod.
func kubectlExec(cluster, ns, pod string, cmd ...string) ([]byte, error) {
	return kubectl(cluster, nil, append([]string{"exec", "-n", ns, pod, "--"}, cmd...)...)
}

// dockerExec runs a command in a container.
func dockerExec(container string, cmd ...string) ([]byte, error) {
	return run(nil, "docker", append([]string{"exec", container}, cmd...)...)
}

// nodeExec runs a command in a kind node container (e.g. "edge-worker").
func nodeExec(node string, cmd ...string) ([]byte, error) {
	return dockerExec(node, cmd...)
}

// vtyshJSON runs `vtysh -c '<cmd> json'` on a FRR router of the lab and reads the output into obj.
func vtyshJSON(router, cmd string, obj any) error {
	out, err := dockerExec("clab-mcsgw-"+router, "vtysh", "-c", cmd+" json")
	if err != nil {
		return err
	}
	return json.Unmarshal(out, obj)
}

// hostCurl runs curl on the host.
func hostCurl(args ...string) ([]byte, error) {
	return run(nil, "curl", args...)
}

// applyManifest applies a manifest and registers its deletion with t.Cleanup.
func applyManifest(t *testing.T, cluster, manifest string) {
	t.Helper()
	mustKubectl(t, cluster, []byte(manifest), "apply", "-f", "-")
	t.Cleanup(func() {
		if _, err := kubectl(cluster, []byte(manifest), "delete", "--ignore-not-found", "--wait", "-f", "-"); err != nil {
			t.Logf("cleanup: %v", err)
		}
	})
}
