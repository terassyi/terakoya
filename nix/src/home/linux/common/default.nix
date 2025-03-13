{ config, pkgs, userConfig, ... }: {
  imports = if userConfig.gui == "none" then [
    ./tools
    ./terminal
  ] else [
    ./tools
    ./terminal
    ./desktop
  ];
}
