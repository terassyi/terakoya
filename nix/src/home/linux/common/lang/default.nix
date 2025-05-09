{ pkgs, ... }: {
  home.packages = with pkgs; [
    # clang
    llvmPackages_20.clang-unwrapped
    # llvm toolchain
    llvmPackages_20.libllvm
    # lldb
    lldb_20
  ];
}
