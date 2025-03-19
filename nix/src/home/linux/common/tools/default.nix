{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Collection of utilities for controlling TCP/IP networking and traffic controll in Linux
    iproute2
    # Set of small useful utilities for Linux networking
    iputils
    # Debugging/program analysis tools for the eBPF subsystem
    bpftools
    # Library for loading eBPF programs and reading and manipulating eBPF objects from user-space
    libbpf
  ];
}
