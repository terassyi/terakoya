{ config, pkgs, userConfig, ... }: {
  imports = [ ./shell ./lang ./editor ./terminal ./tools ./font ];
  home.username = userConfig.name;
  home.homeDirectory = if pkgs.stdenv.isDarwin then
    "/Users/${userConfig.name}"
  else
    "/home/${userConfig.name}";
  home.stateVersion = "25.05";
}
