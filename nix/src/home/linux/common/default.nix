{ config, pkgs, userConfig, ... }: {
  imports = if userConfig.gui == "none" then [
    ./tools
    ./terminal
    ./lang
  ] else [
    ./tools
    ./terminal
    ./lang
    ./desktop
  ];
}
