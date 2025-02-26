{ pkgs, ... }: {
  # Dynamic tiling Wayland compositor that doesn't sacrifice on its looks
  programs.hyprland = { enable = true; };
  services.xserver.updateDbusEnvironment = true;

  environment.systemPackages = with pkgs; [
    # Hyprland's GPU-accelerated screen locking utility
    hyprlock
    # Blazing fast wayland wallpaper utility
    hyprpaper
    # Hyprland's idle daemon
    hypridle

  ];
}
