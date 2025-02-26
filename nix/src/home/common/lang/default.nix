{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Official language server for the Go language
    gopls
    # rust
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer-nightly
    # nix LSP
    nixd
    # clang
    clang
    # Powerful, fast, lightweight, embeddable scripting language
    lua
    # Opinionated Lua code formatter
    stylua

  ];

}
