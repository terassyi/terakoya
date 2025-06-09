{ pkgs, userConfig, ... }: {
  # home.packages = with pkgs; [ hyprpaper ];

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/home/${userConfig.name}/.config/wallpapers/nix-wallpaper-binary-blue.png"
        "/home/${userConfig.name}/.config/wallpapers/interstellar.jpg"
      ];
      wallpaper = [
        ",/home/${userConfig.name}/.config/wallpapers/interstellar.jpg"

      ];
    };
  };

  xdg.configFile."wallpapers" = {
    source = ../wallpapers;
    recursive = true;
  };
}
