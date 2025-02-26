{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      # Minimal, blazing fast, and extremely customizable prompt for any shell
      starship
    ];

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
  xdg.configFile."starship.toml" = { source = ./starship.toml; };
}
