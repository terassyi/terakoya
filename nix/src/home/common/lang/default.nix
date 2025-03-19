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
    nixfmt
    # clang
    llvmPackages_20.clang-unwrapped
    # llvm toolchain
    llvmPackages_20.libllvm
    # lldb
    lldb_20
    # Powerful, fast, lightweight, embeddable scripting language
    lua
    # Opinionated Lua code formatter
    stylua

  ];

}
