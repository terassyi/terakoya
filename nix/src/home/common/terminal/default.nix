{ lib, userConfig, ... }: {

  imports = if userConfig.gui != "none" then [ ./alacritty ] else [ ];
}
