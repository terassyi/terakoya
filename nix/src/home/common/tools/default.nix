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
    gh
    # Tool to control the generation of non-source files from sources
    gnumake
    # Cloudflare Tunnel daemon, Cloudflare Access toolkit, and DNS-over-HTTPS client
    # cloudflared
    # Faster drop-in replacement for existing Unix linkers (unwrapped)
    mold
    # Google's data interchange format
    protobuf
    # Go support for Google's protocol buffers
    protoc-gen-go
    # Go language implementation of gRPC. HTTP/2 based RPC
    protoc-gen-go-grpc
    # Like cURL, but for gRPC: Command-line tool for interacting with gRPC servers
    grpcurl
    # Tool to access the X clipboard from a console application
    # xclip
    wl-clipboard
  ];
}
