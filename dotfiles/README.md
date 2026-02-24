# dotfiles

[chezmoi](https://www.chezmoi.io/) + [tomei](https://github.com/terassyi/tomei) による dotfiles 管理。

## サポート環境

| OS | Arch |
|---|---|
| Linux | amd64, arm64 |
| macOS (Darwin) | arm64 |

## ディレクトリ構成

```
dotfiles/
├── .chezmoi.toml.tmpl          # chezmoi 設定テンプレート
├── .chezmoidata.toml.tmpl      # ホスト判定ロジック（テンプレートデータ）
├── .chezmoiignore              # chezmoi 除外パターン
├── Dockerfile                  # テスト用 Ubuntu コンテナ
├── Makefile                    # ローカル開発・テスト用コマンド
├── dot_config/
│   ├── fish/
│   │   └── config.fish.tmpl    # fish shell 設定
│   └── tomei/
│       ├── cue.mod/            # CUE モジュール（tomei cue init で生成）
│       ├── tomei_platform.cue  # プラットフォーム @tag 宣言
│       └── common-tools.cue    # CLI ツール定義
└── README.md
```

## セットアップ

```sh
# chezmoi で dotfiles を適用
chezmoi init --apply --source=./dotfiles

# tomei でツールをインストール
tomei apply dotfiles/dot_config/tomei/
```

## テスト

Docker コンテナ内で chezmoi と tomei の動作を検証する。

```sh
make build    # テスト用イメージをビルド
make test     # chezmoi init/diff + tomei validate を実行
make shell    # デバッグ用にコンテナへ入る（bash）
make run      # fish シェルでコンテナ起動
make clean    # イメージ削除
```

## CI

`.github/workflows/dotfiles.yml` で `dotfiles/` 配下の変更時に自動テストが走る。

- **validate**: chezmoi テンプレート検証、tomei マニフェスト検証、fish 構文チェック
- **test**: container モード + native モードのマトリックス（linux/amd64, linux/arm64, macOS/arm64）

## tomei マニフェスト

`dot_config/tomei/` 配下の `.cue` ファイルにツール定義を追加する。
CUE モジュールの初期化は `tomei cue init` で行う（手動で `cue.mod/` を作成しない）。

ツールのインストールパターンは 3 種類。`installerRef`, `runtimeRef`, `commands` のいずれか 1 つを指定する。

### aqua レジストリ経由（個別）

```cue
fd: {
    apiVersion: "tomei.terassyi.net/v1beta1"
    kind:       "Tool"
    metadata: name: "fd"
    spec: {
        installerRef: "aqua"
        version:      "v10.3.0"
        package:      "sharkdp/fd"
    }
}
```

### プリセット + ToolSet（複数ツールをまとめて定義）

```cue
import "tomei.terassyi.net/presets/aqua"

cliTools: aqua.#AquaToolSet & {
    metadata: name: "cli-tools"
    spec: tools: {
        rg:  {package: "BurntSushi/ripgrep", version: "15.1.0"}
        fd:  {package: "sharkdp/fd", version: "v10.3.0"}
        jq:  {package: "jqlang/jq", version: "1.8.1"}
        bat: {package: "sharkdp/bat", version: "v0.26.1"}
    }
}
```

### Runtime 経由（Go, Rust など）

```cue
import gopreset "tomei.terassyi.net/presets/go"

goRuntime: gopreset.#GoRuntime & {
    platform: {os: _os, arch: _arch}
    spec: version: "1.26.0"
}

gopls: {
    apiVersion: "tomei.terassyi.net/v1beta1"
    kind:       "Tool"
    metadata: name: "gopls"
    spec: {
        runtimeRef: "go"
        package:    "golang.org/x/tools/gopls"
        version:    "v0.21.0"
    }
}
```

### カスタムコマンド

```cue
myTool: {
    apiVersion: "tomei.terassyi.net/v1beta1"
    kind:       "Tool"
    metadata: name: "my-tool"
    spec: commands: {
        install: ["curl -fsSL https://example.com/install.sh | sh"]
        check:   ["my-tool --version"]
        remove:  ["rm -f ~/.local/bin/my-tool"]
    }
}
```
