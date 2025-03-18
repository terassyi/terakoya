{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Container runtime written in Rust
    youki
    # Header files and scripts for Linux kernel
    linuxHeaders
    # Library for loading eBPF programs and reading and manipulating eBPF objects from user-space
    libbpf
  ];
}
