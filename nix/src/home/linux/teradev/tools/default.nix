{ pkgs, ... }: {
  home.packages =
    with pkgs; [ # Desktop user interface for managing virtual machines
      virt-manager
      # Toolkit to interact with the virtualization capabilities of recent versions of Linux and other OSes
      libvirt
      # Viewer for remote virtual machines
      virt-viewer
    ];
}
