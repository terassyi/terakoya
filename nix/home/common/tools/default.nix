{ pkgs, ... }: {
  imports = [ ./tmux ./zellij ./starship ./git.nix ./zoxide.nix ];

  home.packages = with pkgs; [
    # Cat(1) clone with syntax highlighting and Git integration
    bat
    # Modern, maintained replacement for ls
    eza
    # Cross-platform graphical process/system monitor with a cusomizable interface
    bottom
    # Command-line fuzzy finder written in Rust
    skim
    # Simple, fast and user-friendly alternative to find
    fd
    # Program that allows you to count your code, quickly
    tokei
    # Utility that combines the usability of The Sliver Searcher with the raw speed of grep
    ripgrep
    # Syntax-highlighting pager for git
    delta
    # Handy way to save and run project-specific commands
    just
    # Lightweight and flexible command-line JSON processor
    jq
    # Portable command-line YAML processor
    yq-go
    # GitHub CLI tool
    gh
    # Tool to control the generation of non-source files from sources
    gnumake
    # Collection of utilities for controlling TCP/IP networking and traffic controll in Linux
    iproute2
    # Cloudflare Tunnel daemon, Cloudflare Access toolkit, and DNS-over-HTTPS client
    cloudflared
    # Blazing fast terminal-ui for Git written in Rust
    gitui
  ];
}
