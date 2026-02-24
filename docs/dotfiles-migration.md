# dotfiles 刷新: nix/home-manager → tomei + chezmoi 移行計画

## Context

terakoya リポジトリの開発環境管理を nix/home-manager 一本から、以下の構成に移行する:

- **tomei**: ユーザーレベルの CLI ツール・ランタイムのインストール（CUE マニフェスト）
- **chezmoi**: dotfiles（設定ファイル）のデプロイとテンプレート化
- **nix**: NixOS システム設定のみ（最小スコープ）。GUI アプリは手動管理

新ブランチ `feature/dotfiles-chezmoi-tomei` で作業する。

---

## 1. 責務の分離

### 1.1 tomei が管理するもの（ツールバイナリ）

| カテゴリ | ツール | インストールパターン |
|---|---|---|
| 共通 CLI ツール | bat, eza, bottom, skim, fd, tokei, ripgrep, delta, hugo, just, jq, yq, gh, grpcurl, unzip, gnumake | aqua ToolSet |
| エディタ | neovim | aqua |
| Go | Go runtime + gopls | GoRuntime + GoToolSet |
| Rust | rustup + stable toolchain + rust-analyzer + stylua | RustRuntime + BinstallToolSet |
| Node.js | pnpm + Node.js LTS | PnpmRuntime |
| Nix ツール | nixd, nixfmt | aqua |
| プロンプト・ターミナル | starship, zoxide, zellij, tmux | aqua ToolSet |
| Git 関連 | delta, gh, gitui | aqua ToolSet |
| Linux CLI ツール | iproute2, bpftools, clang/llvm, gcc, mold | システムパッケージ (apt 等) or chezmoi スクリプト |
| Darwin 専用 | google-cloud-sdk, docker CLI, docker-credential-helpers | aqua + commands |
| Darwin2 専用 | ffmpeg, ttyd, python (uv) | aqua + UvRuntime |

### 1.2 chezmoi が管理するもの（設定ファイル）

| カテゴリ | ファイル |
|---|---|
| Fish shell | config.fish, functions/\*, conf.d/ (starship, zoxide init) |
| Git | ~/.config/git/config (テンプレート: name, email) |
| Starship | ~/.config/starship.toml |
| Zellij | ~/.config/zellij/config.kdl |
| Neovim | ~/.config/nvim/init.lua, lua/\*.lua (lazy.nvim ベース) |
| VSCode | settings.json, keybindings.json |
| Ghostty | ~/.config/ghostty/config (Linux GUI のみ) |
| Hyprland | hyprland.conf, hypridle, hyprlock, hyprpaper (Linux Hyprland のみ) |
| Waybar/Wofi | config + style (Linux Hyprland のみ) |
| 壁紙 | ~/.config/wallpapers/\*.jpg |

### 1.3 nix に残すもの（最小スコープ）

NixOS のシステム設定のみ。home-manager は廃止。

| カテゴリ | 理由 |
|---|---|
| NixOS システム設定 | ブートローダー、ネットワーク、ユーザー、サービス、ロケール |
| NixOS デスクトップ基盤 | Hyprland/GNOME セッション、Pipewire、seatd、IME (fcitx5/ibus) |
| NixOS システムパッケージ | linuxHeaders, libbpf (overlay), youki |
| Fish ログインシェル登録 | `programs.fish.enable = true` (NixOS レベル) |

### 1.4 手動管理に移行するもの

- GUI アプリ全般: VSCode, Google Chrome, Slack, Discord, Zoom, Wireshark
- VSCode 拡張機能 → VSCode Marketplace / Settings Sync
- フォント → OS のフォント管理 or chezmoi スクリプト
- GNOME 拡張機能 → GNOME Extensions サイト
- Ghostty → 公式インストーラー or tomei

---

## 2. ディレクトリ構成

### 2.1 dotfiles/ (chezmoi ソース)

```
dotfiles/
├── .chezmoi.toml.tmpl                # chezmoi 基本設定 (editor=nvim, pager=delta)
├── .chezmoidata.toml.tmpl            # ホスト別データ (hostname→gui, git name/email)
├── .chezmoiignore                    # OS/GUI 条件で不要ファイルを除外
├── Makefile                          # make install → chezmoi init --apply
│
├── .chezmoiscripts/
│   ├── run_once_before_00-bootstrap-dirs.sh.tmpl
│   ├── run_once_before_01-install-packages.sh.tmpl
│   ├── run_once_before_02-install-tomei.sh.tmpl
│   ├── run_onchange_after_01-apply-tomei.sh.tmpl
│   ├── run_once_after_90-set-fish-default-shell.sh.tmpl
│   └── run_once_after_91-gnome-dconf.sh.tmpl
│
├── .chezmoitemplates/
│   └── fish_keybinds.fish            # skim key-bindings (インライン)
│
├── dot_config/
│   ├── fish/
│   │   ├── config.fish.tmpl          # テンプレート (OS別PATH, エイリアス, 環境変数)
│   │   ├── conf.d/
│   │   │   ├── starship.fish         # starship init fish | source
│   │   │   └── zoxide.fish           # zoxide init fish | source
│   │   └── functions/
│   │       ├── clone.fish
│   │       ├── gh_release.fish
│   │       ├── sk_bat.fish
│   │       ├── sk_history.fish
│   │       ├── sk_zoxide.fish
│   │       ├── sk_zoxide_gh.fish
│   │       └── sk_code_repo.fish
│   ├── git/
│   │   └── config.tmpl               # テンプレート (name, email, gpg signing)
│   ├── gh/
│   │   └── config.yml
│   ├── starship.toml
│   ├── zellij/
│   │   └── config.kdl
│   ├── nvim/
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── keymaps.lua
│   │       ├── lsp.lua
│   │       ├── options.lua
│   │       └── plugins.lua           # lazy.nvim ベース
│   ├── Code/
│   │   └── User/
│   │       ├── settings.json
│   │       └── keybindings.json
│   ├── ghostty/
│   │   └── config
│   ├── hypr/
│   │   ├── hyprland.conf.tmpl        # ホスト別モニター設定
│   │   ├── hypridle.conf
│   │   ├── hyprlock.conf.tmpl
│   │   └── hyprpaper.conf.tmpl
│   ├── waybar/
│   │   ├── config.json
│   │   └── style.css
│   ├── wofi/
│   │   ├── config
│   │   └── style.css
│   └── wallpapers/
│       ├── fukuoka-night.jpg
│       ├── interstellar.jpg
│       └── nix-wallpaper-binary-blue.png
│
└── dot_config/tomei/                 # tomei CUE マニフェスト
    ├── cue.mod/
    │   └── module.cue
    ├── tomei_platform.cue            # @tag(os), @tag(arch), @tag(headless)
    ├── runtimes.cue                  # Go, Rust, pnpm
    ├── common-tools.cue              # aqua ToolSet (全プラットフォーム共通)
    ├── lang-tools.cue                # gopls, stylua
    ├── darwin-tools.cue              # gcloud, docker CLI (enabled: _os == "darwin")
    └── darwin2-extras.cue.tmpl       # ffmpeg, ttyd, python (chezmoi テンプレート)
```

### 2.2 nix/src/ (大幅縮小)

- `home/` → **全削除**（home-manager 廃止）
- `hosts/nixos/` → 維持（NixOS システム設定）
  - GUI アプリ (chrome, slack, discord, zoom, wireshark) は `environment.systemPackages` から削除
  - GNOME 拡張機能パッケージも削除
- `overlays/libbpf.nix` → 維持（NixOS hosts が依存）
- `flake.nix` → home-manager, fenix, nix-vscode-extensions, darwin の input を削除。NixOS 用のみ残す

---

## 3. chezmoi テンプレート戦略

### 3.1 .chezmoidata.toml.tmpl

ホスト名から gui タイプ、git identity を自動判定する。

```toml
{{- $hostname := .chezmoi.hostname -}}
{{- $os := .chezmoi.os -}}
{{- $username := .chezmoi.username -}}

{{- /* CI runner フォールバック */ -}}
{{- if eq $username "runner" -}}
  {{- $username = "terassyi" -}}
  {{- $hostname = "dev" -}}
{{- end -}}

{{- /* GUI タイプ判定: "none" | "gnome" | "hyprland" | "mac" */ -}}
{{- $gui := "none" -}}
{{- if eq $os "darwin" -}}
  {{- $gui = "mac" -}}
{{- else if or (eq $hostname "teracarbon") (eq $hostname "teradev") -}}
  {{- $gui = "hyprland" -}}
{{- else if eq $hostname "devvm" -}}
  {{- $gui = "gnome" -}}
{{- end -}}

{{- /* Git identity (ホスト別) */ -}}
{{- $gitName := "terassyi" -}}
{{- $gitEmail := "iscale821@gmail.com" -}}
{{- if eq $hostname "fukdesk" -}}
  {{- $gitName = "terashima" -}}
  {{- $gitEmail = "tomoya-terashima@cybozu.co.jp" -}}
{{- else if eq $hostname "dev" -}}
  {{- $gitEmail = "dev@terassyi.net" -}}
{{- else if or (eq $hostname "darwin1") (eq $hostname "darwin2") -}}
  {{- $gitName = "terashima" -}}
{{- end -}}

[data]
hostname  = "{{ $hostname }}"
username  = "{{ $username }}"
os        = "{{ $os }}"
gui       = "{{ $gui }}"
is_darwin = {{ eq $os "darwin" }}
is_linux  = {{ eq $os "linux" }}
has_gui   = {{ ne $gui "none" }}

[data.git]
name  = "{{ $gitName }}"
email = "{{ $gitEmail }}"
```

### 3.2 .chezmoiignore

```
*.swp
.DS_Store

{{ if ne .gui "hyprland" }}
dot_config/hypr
dot_config/waybar
dot_config/wofi
{{ end }}

{{ if eq .gui "none" }}
dot_config/Code
dot_config/ghostty
{{ end }}

{{ if eq .os "darwin" }}
dot_config/ghostty
{{ end }}
```

---

## 4. スクリプト実行順序

| 順序 | スクリプト | 内容 |
|---|---|---|
| before 00 | bootstrap-dirs | ~/workspace ディレクトリ作成 |
| before 01 | install-packages | 最低限の OS パッケージ (curl, git, fish) |
| before 02 | install-tomei | tomei バイナリを ~/.local/bin にダウンロード |
| (ファイル適用) | chezmoi がドットファイルを配置 | |
| after 01 | apply-tomei | tomei init + apply (マニフェスト hash 変更時のみ再実行) |
| after 90 | set-fish-default-shell | chsh -s fish |
| after 91 | gnome-dconf | dconf load (GNOME のみ) |

---

## 5. CI テスト戦略

### GitHub Actions ワークフロー (`dotfiles.yml`)

```yaml
name: Dotfiles
on:
  pull_request:
    paths: ['dotfiles/**']
  push:
    branches: [main]
    paths: ['dotfiles/**']

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Install chezmoi
        run: sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
      - name: Validate chezmoi templates
        run: |
          find dotfiles -name "*.tmpl" | while read f; do
            chezmoi execute-template --source=dotfiles < "$f" > /dev/null 2>&1 || exit 1
          done
      - name: Install tomei
        run: curl -fsSL https://github.com/terassyi/tomei/releases/latest/... -o /usr/local/bin/tomei && chmod +x /usr/local/bin/tomei
      - name: Validate tomei manifests
        run: tomei validate dotfiles/dot_config/tomei/
      - name: Tomei plan (dry-run)
        run: tomei plan dotfiles/dot_config/tomei/

  integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Full apply test in Docker
        run: |
          docker build -t dotfiles-test -f dotfiles/Dockerfile dotfiles
          docker run --rm dotfiles-test chezmoi apply --source=/dotfiles --no-tty
          docker run --rm dotfiles-test bash -c "
            test -f ~/.config/fish/config.fish &&
            test -f ~/.config/nvim/init.lua &&
            test -f ~/.config/starship.toml &&
            test -f ~/.config/git/config
          "
```

---

## 6. Neovim プラグイン管理

home-manager 廃止に伴い、neovim プラグインを nixpkgs.vimPlugins から **lazy.nvim** に移行する。

- Neovim バイナリ: tomei (aqua) でインストール
- プラグイン: lazy.nvim がランタイムで管理（init.lua + plugins.lua で宣言）
- treesitter パーサー: nvim-treesitter が自動ビルド（`:TSInstall`）
- LSP サーバー: tomei がインストール済み (gopls, rust-analyzer, nixd 等)

現在の nix 管理プラグインからの移行対象:
- comment-nvim, bufferline-nvim, nvim-autopairs, vim-easymotion, nvim-surround
- lualine-nvim, indent-blankline-nvim, which-key-nvim, tokyonight-nvim
- telescope-nvim, gitsigns-nvim, diffview-nvim
- nvim-treesitter (with grammars)
- nvim-lspconfig, nvim-cmp + cmp-nvim-lsp, fidget-nvim, luasnip
- conform-nvim

---

## 7. 実装タスク

### Phase 1: chezmoi 基盤

- [ ] ブランチ `feature/dotfiles-chezmoi-tomei` 作成
- [ ] `dotfiles/.chezmoidata.toml.tmpl` 作成
- [ ] `dotfiles/.chezmoi.toml.tmpl` 作成
- [ ] `dotfiles/.chezmoiignore` 作成
- [ ] `dotfiles/Makefile` 作成

### Phase 2: chezmoi スクリプト

- [ ] `run_once_before_00-bootstrap-dirs.sh.tmpl`
- [ ] `run_once_before_01-install-packages.sh.tmpl`
- [ ] `run_once_before_02-install-tomei.sh.tmpl`
- [ ] `run_onchange_after_01-apply-tomei.sh.tmpl`
- [ ] `run_once_after_90-set-fish-default-shell.sh.tmpl`
- [ ] `run_once_after_91-gnome-dconf.sh.tmpl`

### Phase 3: Shell 設定 (Fish)

- [ ] `dot_config/fish/config.fish.tmpl`
- [ ] `dot_config/fish/conf.d/starship.fish`
- [ ] `dot_config/fish/conf.d/zoxide.fish`
- [ ] `dot_config/fish/functions/` (既存の nix 管理関数を移植)
- [ ] `.chezmoitemplates/fish_keybinds.fish`

### Phase 4: Git・ツール設定

- [ ] `dot_config/git/config.tmpl`
- [ ] `dot_config/gh/config.yml`
- [ ] `dot_config/starship.toml` (既存 nix 設定から変換)
- [ ] `dot_config/zellij/config.kdl` (既存 nix 設定から変換)

### Phase 5: エディタ設定

- [ ] Neovim: lazy.nvim ベースの `init.lua` + `lua/*.lua` に書き換え
- [ ] VSCode: `settings.json`, `keybindings.json` を chezmoi に移植

### Phase 6: デスクトップ設定 (Linux)

- [ ] `dot_config/ghostty/config`
- [ ] `dot_config/hypr/hyprland.conf.tmpl` + 関連設定
- [ ] `dot_config/waybar/` (config + style)
- [ ] `dot_config/wofi/` (config + style)
- [ ] `dot_config/wallpapers/` (画像ファイルコピー)
- [ ] GNOME dconf スクリプト

### Phase 7: tomei CUE マニフェスト

- [ ] `dot_config/tomei/cue.mod/module.cue`
- [ ] `dot_config/tomei/tomei_platform.cue`
- [ ] `dot_config/tomei/runtimes.cue` (Go, Rust, pnpm)
- [ ] `dot_config/tomei/common-tools.cue` (aqua ToolSet)
- [ ] `dot_config/tomei/lang-tools.cue` (gopls, stylua)
- [ ] `dot_config/tomei/darwin-tools.cue`
- [ ] `dot_config/tomei/darwin2-extras.cue.tmpl`

### Phase 8: nix 縮小

- [ ] `nix/src/home/` 全削除
- [ ] `nix/src/flake.nix` から不要 input 削除
- [ ] `nix/src/hosts/nixos/` から GUI アプリ削除

### Phase 9: CI

- [ ] `.github/workflows/dotfiles.yml` 作成
- [ ] `dotfiles/Dockerfile` 作成（integration テスト用）

### Phase 10: 検証

- [ ] ローカルで `chezmoi diff` 確認
- [ ] `tomei validate` + `tomei plan` 確認
- [ ] CI パス確認
