# Terakoya

Nix ベースの開発環境・インフラ構成管理リポジトリ。
NixOS / nix-darwin / home-manager によるマルチマシン構成管理と、Kubernetes 関連のコンテナ・マニフェストを管理する。

## ディレクトリ構成

- `nix/src/` - Nix Flake 本体（flake.nix）。home-manager, NixOS, nix-darwin の設定
  - `home/` - home-manager 設定（common, darwin, linux の各ホスト別）
  - `hosts/` - NixOS ホスト設定
  - `overlays/` - Nixpkgs オーバーレイ
- `containers/` - Docker コンテナ定義（terakoya, test-server, bpf-utils）
- `kindcluster/` - Kind クラスタのテスト設定
- `manifest/` - Kubernetes マニフェスト
- `.github/` - GitHub Actions ワークフロー・Dependabot 設定
- `dotfiles/` - chezmoi による dotfiles 管理

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
- Dependabot: GitHub Actions の自動更新（週次、PR 集約）
