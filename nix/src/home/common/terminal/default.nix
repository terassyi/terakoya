{ lib, userConfig, ... }: {

  imports = if userConfig.hasGUI then [ ./alacritty ] else [ ];
}
