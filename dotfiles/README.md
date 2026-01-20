# Dotfiles

chezmoi + Nix home-manager + mise ベースの dotfiles 管理システムです。macOS と Linux で透過的に動作し、開発環境を宣言的に管理します。

## 特徴

- ✅ **macOS と Linux の両対応**: OS 固有の設定を自動的に切り替え
- ❄️ **Nix home-manager による CLI ツール管理**: 再現性の高いツールインストール
- 🛠️ **mise による言語ランタイム管理**: Go, Rust, Node.js, Python などのバージョン管理
- 📦 **chezmoi による設定ファイル管理**: テンプレート機能でデバイス固有の設定に対応
- 🔌 **krew/pnpm プラグイン管理**: YAML 設定で宣言的に管理
- 🧪 **Docker でのテスト環境**: Ubuntu 24.04 ベースのコンテナで安全にテスト
- 🔄 **CI/CD 対応**: GitHub Actions で自動テスト

## ツール管理の役割分担

### Nix home-manager
CLI ツール・フォント管理
- starship
- ripgrep
- fd
- bat
- eza
- zoxide
- delta
- yq
- jq
- neovim
- etc.

### mise
言語ランタイム・k8s ツール管理
- go
- node
- python
- rust
- kubectl
- helm
- kind
- krew
- pnpm

### krew
kubectl プラグイン管理
- stern
- whoami
- mft (カスタムインデックス)

### pnpm
グローバル npm パッケージ管理
- claude-code
- gemini-cli

### chezmoi
設定ファイル・スクリプト管理
- fish
- nvim
- zed
- tmux
- git
- starship

## 管理対象

- **シェル**: fish shell (設定、関数)
- **エディタ**: VSCode, Neovim, Zed (設定、キーバインド)
- **ターミナル**: Ghostty, tmux, zellij
- **ツール**:
  - Git (gitconfig, delta)
  - Starship (プロンプト)
  - GitHub CLI
  - Kubernetes ツール (kubectl, helm, kind, krew plugins)
  - AI CLI (claude-code, gemini-cli)

## 必要要件

- **macOS**: macOS 12 以降
- **Linux**: Ubuntu 22.04 以降、または同等のディストリビューション
- **その他**: curl, git, sudo 権限

## セットアップ

### 新しいマシンでの初回セットアップ

```bash
# dotfiles リポジトリをクローン
git clone https://github.com/terassyi/terakoya.git
cd terakoya/dotfiles

# インストールを実行
make install
```

これは以下を自動的に実行します:

1. chezmoi のインストール
2. 基本パッケージのインストール (curl, git, fish, etc.)
3. Nix のインストールと home-manager の設定
4. mise のインストール
5. dotfiles の適用
6. 各種ツールのインストール (Nix → mise → krew → pnpm の順)
7. fish shell をデフォルトシェルに設定

### GITHUB_TOKEN の設定（推奨）

GitHub API のレート制限を回避するため、`GITHUB_TOKEN` を設定することをお勧めします。

```bash
# オプション 1: gh CLI で認証してから実行
gh auth login  # 初回のみ必要
export GITHUB_TOKEN=$(gh auth token)
make install TARGET=terassyi@dev

# オプション 2: GitHub トークンを直接指定
export GITHUB_TOKEN=<your-github-token>
make install TARGET=terassyi@dev
```

**注**: `GITHUB_TOKEN` がない場合、`mise install` が GitHub API のレート制限に引っかかる可能性があります。

### Nix 設定名の指定

Nix home-manager の設定名を `TARGET` 変数で指定できます:

```bash
# 設定名を指定してインストール
make install TARGET=terassyi@dev

# Nix のみ適用
make nix-apply TARGET=terassyi@dev
```

利用可能な設定名は `nix/flake.nix` で定義されています（例: `terassyi@dev`, `terashima@darwin1`）。
指定しない場合は、ホスト名とユーザー名から自動検出されます。

### Docker でのテスト

安全に設定をテストしたい場合は、Docker 環境を使用できます:

```bash
# テスト環境をビルド
make build

# 対話的なテスト環境を起動 (GITHUB_TOKEN があれば自動で渡される)
make test-interactive

# コンテナ内で dotfiles をインストール
make install

# 自動テストを実行
make test

# クリーンアップ
make clean
```

## 使い方

### dotfiles の更新

```bash
# 変更を確認
chezmoi diff

# 変更を適用
chezmoi apply

# 強制的に再適用
chezmoi apply --force
```

### Nix ツールの管理

```bash
# nix/home/common/tools/default.nix を編集してツールを追加
# 変更後に適用
home-manager switch --flake ~/dotfiles/nix
```

### mise ツールの管理

```bash
# .mise.toml を編集してツール/バージョンを変更
mise install
```

### krew プラグインの追加

`.chezmoitemplates/packages/krew.yaml` を編集:

```yaml
indexes:
  - name: mft
    url: https://github.com/terassyi/mft.git

plugins:
  - whoami
  - stern
  - mft/mft  # カスタムインデックスのプラグイン
```

### pnpm グローバルパッケージの追加

`.chezmoitemplates/packages/pnpm.yaml` を編集:

```yaml
packages:
  - "@anthropic-ai/claude-code"
  - "@google/gemini-cli"
```

## ディレクトリ構造

```
dotfiles/
├── .mise.toml                        # mise ツールバージョン定義
├── .chezmoi.toml.tmpl                # chezmoi 基本設定
├── .chezmoidata.toml.tmpl            # デバイス固有設定テンプレート
├── .chezmoiscripts/                  # chezmoi セットアップスクリプト
│   ├── run_once_before_*.sh.tmpl     # 初回のみ実行 (Nix, mise インストール)
│   └── run_onchange_after_*.sh.tmpl  # 変更時に実行 (ツールインストール)
├── .chezmoitemplates/packages/       # パッケージ定義
│   ├── apt.txt                       # apt パッケージリスト
│   ├── krew.yaml                     # krew プラグイン定義
│   └── pnpm.yaml                     # pnpm グローバルパッケージ
├── nix/                              # Nix 設定
│   ├── flake.nix                     # Nix flake 定義
│   └── home/                         # home-manager 設定
│       ├── common/                   # 共通設定 (CLI ツール、フォント)
│       ├── darwin/                   # macOS 固有設定
│       └── linux/                    # Linux 固有設定
├── dot_config/                       # ~/.config/ に配置される設定
│   ├── fish/                         # fish shell 設定
│   ├── nvim/                         # Neovim 設定
│   ├── zed/                          # Zed エディタ設定
│   ├── tmux/                         # tmux 設定
│   ├── git/                          # Git 設定
│   ├── starship.toml                 # Starship プロンプト設定
│   └── Code/User/                    # VSCode 設定
├── Dockerfile                        # テスト用 Docker イメージ
└── Makefile                          # Make タスク
```

## chezmoi スクリプト実行順序

**初回のみ実行 (run_once_before)**:
- `00-setup-directories.sh` - ディレクトリ作成
- `01-install-packages.sh` - apt パッケージインストール
- `02-install-nix.sh` - Nix インストール
- `03-setup-nix-flakes.sh` - Nix flakes 設定

**変更時に実行 (run_onchange_after)**:
- `01-nix-apply.sh` - home-manager 適用
- `02-mise-install.sh` - mise ツールインストール
- `03-krew-plugins.sh` - krew プラグインインストール
- `04-pnpm-packages.sh` - pnpm パッケージインストール

**初回のみ実行 (run_once_after)**:
- `99-set-fish-shell.sh` - fish をデフォルトシェルに設定

## Make コマンド

### クイックスタート

```bash
make install           # chezmoi をインストールして dotfiles を適用
```

### chezmoi コマンド

```bash
make chezmoi           # chezmoi のみインストール
make chezmoi-apply     # dotfiles を適用
make chezmoi-diff      # 変更差分を表示
make chezmoi-update    # 最新を取得して適用
```

### Docker テスト

```bash
make build             # Docker イメージをビルド
make test              # 自動テストを実行
make test-interactive  # 対話的なテスト環境を起動
make test-fish         # fish shell 設定のテスト
make clean             # Docker リソースをクリーンアップ
```

### Nix コマンド

```bash
make nix               # Nix をインストールしてセットアップ
make nix-apply TARGET=terassyi@dev  # home-manager を適用
```

## カスタマイズ

### Nix ツールの追加

`nix/home/common/tools/default.nix` を編集:

```nix
home.packages = with pkgs; [
  # 既存のツール
  ripgrep
  fd
  # 新しいツールを追加
  htop
  tree
];
```

### fish shell のカスタマイズ

`dot_config/fish/config.fish.tmpl` を編集して、エイリアスや環境変数を追加できます。

### Zed/VSCode のカスタマイズ

- `dot_config/zed/settings.json` - Zed エディタ設定
- `dot_config/Code/User/settings.json` - VSCode 設定

### Git のカスタマイズ

`dot_config/git/config.tmpl` を編集。テンプレート変数 `{{ .name }}` と `{{ .email }}` が使用可能です。

## トラブルシューティング

### chezmoi が設定を適用しない

```bash
# chezmoi の状態を確認
chezmoi status

# 強制的に再適用
chezmoi apply --force
```

### Nix/home-manager のエラー

```bash
# Nix の状態を確認
nix doctor

# home-manager を手動で適用
home-manager switch --flake ~/dotfiles/nix

# flake.lock を更新
cd ~/dotfiles/nix && nix flake update
```

### mise のツールがインストールされない

```bash
# mise のログを確認
mise doctor

# trust を追加
mise trust

# 手動でインストール
mise install
```

### fish shell が起動しない

```bash
# fish の設定ファイルをチェック
fish -n ~/.config/fish/config.fish

# エラーがあれば修正してから再適用
chezmoi apply --force
```

### krew プラグインが見つからない

```bash
# krew の状態を確認
krew version

# インデックスを更新
krew update

# プラグインを再インストール
krew install <plugin>
```

## ライセンス

このプロジェクトは個人使用を目的としています。

## 参考リンク

- [chezmoi](https://www.chezmoi.io/)
- [Nix](https://nixos.org/)
- [home-manager](https://github.com/nix-community/home-manager)
- [mise](https://mise.jdx.dev/)
- [fish shell](https://fishshell.com/)
- [Starship](https://starship.rs/)
- [krew](https://krew.sigs.k8s.io/)
