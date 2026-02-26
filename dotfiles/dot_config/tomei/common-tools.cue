package tomei

import "tomei.terassyi.net/presets/aqua"

cliTools: aqua.#AquaToolSet & {
	metadata: name: "cli-tools"
	spec: tools: {
		rg:  {package: "BurntSushi/ripgrep", version: "15.1.0"}
		fd:  {package: "sharkdp/fd", version: "v10.3.0"}
		jq:  {package: "jqlang/jq", version: "1.8.1"}
		bat: {package: "sharkdp/bat", version: "v0.26.1"}
		sk:     {package: "skim-rs/skim", version: "v0.16.0"}
		zellij: {package: "zellij-org/zellij", version: "v0.43.1"}
	}
}
