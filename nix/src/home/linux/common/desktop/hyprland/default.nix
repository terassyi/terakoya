{ pkgs, ... }: {
  imports =
    [ ./wofi.nix ./waybar.nix ./hypridle.nix ./hyprlock.nix ./hyprpaper.nix ];
  home.packages = with pkgs; [ networkmanager networkmanagerapplet ];
}
