{ config, pkgs, ... }: {
  imports = [ ./shell ./lang ./editor ./terminal ./tools ./font ];
  home.username = "terassyi";
  home.homeDirectory = "/home/terassyi";
  home.stateVersion = "25.05";
}
