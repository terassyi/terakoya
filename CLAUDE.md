# Terakoya

開発環境・インフラ構成管理リポジトリ。
tomei + chezmoi による dotfiles 管理、NixOS システム設定、Kubernetes 関連のコンテナ・マニフェストを管理する。

## 基本理念

- **TDD**: テストを先に書く。CI で検証できない変更は入れない
- **宣言的**: 手順ではなく望ましい状態を記述する（tomei CUE マニフェスト、chezmoi テンプレート）
- **冪等**: 何度実行しても同じ結果になる。`chezmoi apply` と `tomei apply` は繰り返し安全

## ディレクトリ構成

- `nix/src/` - Nix Flake 本体（flake.nix）。home-manager, NixOS, nix-darwin の設定
  - `home/` - home-manager 設定（common, darwin, linux の各ホスト別）
  - `hosts/` - NixOS ホスト設定
  - `overlays/` - Nixpkgs オーバーレイ
- `containers/` - Docker コンテナ定義（terakoya, test-server, bpf-utils）
- `kindcluster/` - Kind クラスタのテスト設定
- `manifest/` - Kubernetes マニフェスト
- `.github/` - GitHub Actions ワークフロー・Dependabot 設定
- `dotfiles/` - chezmoi + tomei による dotfiles 管理
  - `Dockerfile` - テスト用 Ubuntu コンテナ（chezmoi + tomei 入り）
  - `Makefile` - ローカル開発: build, run, test, shell, clean, install
  - `dot_config/tomei/` - tomei CUE マニフェスト（ツール定義）
  - `dot_config/fish/` - fish shell 設定テンプレート

## ワークフロー

- **コミットはユーザーの指示があるまで行わない**
- ローカルで `tomei apply`, `tomei init`, `chezmoi apply`, `chezmoi init` を実行しない
- テストはコンテナ内（`make test`）で行う

## コードスタイル

- Nix: `nixfmt` でフォーマット
- Nix / JSON / YAML: インデント 2 スペース
- 言語: Nix, Go, Rust, Fish shell, YAML

## よく使うコマンド

```sh
# home-manager の適用（nix/src/ ディレクトリで実行）
home-manager switch --flake .#<user>@<host>

# NixOS の適用
sudo nixos-rebuild switch --flake .#<host>

# Nix Flake の更新
nix flake update

# justfile のレシピ（nix/ ディレクトリ）
just docker    # Docker イメージビルド
just run       # 開発コンテナ起動
```

## CI/CD

- `container.yaml`: `containers/` 配下の変更時のみコンテナをビルド・プッシュ（ghcr.io）
- `dotfiles.yml`: `dotfiles/` 配下の変更時に validate → test（matrix: container/native × arch）
- Dependabot: GitHub Actions の自動更新（週次、PR 集約）

## dotfiles テスト

```sh
# dotfiles/ ディレクトリで実行
make build    # テスト用 Docker イメージをビルド
make test     # chezmoi init/diff + tomei validate をコンテナ内で実行
make shell    # デバッグ用にコンテナへ入る
make run      # fish シェルでコンテナ起動
make clean    # イメージ削除
```
