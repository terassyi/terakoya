# CLI tools managed by Nix (version-agnostic tools)
# For versioned tools (go, node, kubectl, etc.), use mise
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # === CLI basics ===
    ripgrep # Fast grep alternative
    fd # Fast find alternative
    bat # Cat with syntax highlighting
    eza # Modern ls replacement
    jq # JSON processor
    yq # YAML processor
    sd # sed alternative
    fzf # Fuzzy finder

    # === Git tools ===
    delta # Better git diff
    gitui # Terminal git UI
    gh # GitHub CLI

    # === Shell enhancements ===
    starship # Cross-shell prompt
    zoxide # Smart cd
    shellcheck # Shell script linter

    # === Terminal multiplexer ===
    zellij # Modern terminal multiplexer
    tmux # Traditional terminal multiplexer

    # === System monitoring ===
    bottom # System monitor (btm)
    dust # Disk usage analyzer
    tokei # Code statistics

    # === Search & Navigation ===
    skim # Fuzzy finder (sk)
    broot # Directory navigator

    # === Editor ===
    neovim # Modern vim

    # === Network tools ===
    # containerlab  # Not in nixpkgs, install via mise or binary
    cloudflared # Cloudflare tunnel
    cfssl # CloudFlare SSL toolkit
    nerdctl # containerd CLI

    # === Build & Task tools ===
    just # Command runner (like make)
    hugo # Static site generator
    go-jsonnet # Jsonnet implementation
    jsonnet-bundler # Jsonnet package manager (jb)
    grpcurl # gRPC curl

    # === Version management ===
    mise # Runtime version manager

    # === Encryption ===
    rage # Modern age encryption

    # === Nix ===
    nil # Nix Language Server

    # Note: aqua is not in nixpkgs, install via mise or binary
  ];
}
