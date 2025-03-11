{ pkgs, ... }: {
  # Dynamic tiling Wayland compositor that doesn't sacrifice on its looks
  programs.hyprland = { enable = true; };
  services.xserver.updateDbusEnvironment = true;

  # Enable Ozone Wayland support in Chromium and Electron based applications
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    XCURSOR_SIZE = "24";
  };

  environment.systemPackages = with pkgs; [
    # Hyprland's GPU-accelerated screen locking utility
    hyprlock
    # Blazing fast wayland wallpaper utility
    hyprpaper
    # Hyprland's idle daemon
    hypridle
    # Day/night gamma adjustments for Wayland
    wlsunset
    # Wayland based logout menu
    wlogout
    # Lightweight and customizable notification daemon
    dunst
    # Xfce file manager
    xfce.thunar
  ];
}
