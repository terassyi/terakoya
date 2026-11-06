package e2e

import (
	"fmt"
	"os"
	"testing"
)

// TestMain skips the whole suite unless MCSGW_E2E=1 is set, so that
// `go test ./...` and `go vet` work without a running lab.
// `task test` and `task lint` set the variable.
func TestMain(m *testing.M) {
	if os.Getenv("MCSGW_E2E") != "1" {
		fmt.Fprintln(os.Stderr, "MCSGW_E2E is not set; skipping e2e tests (use `task test`)")
		os.Exit(0)
	}
	os.Exit(m.Run())
}
