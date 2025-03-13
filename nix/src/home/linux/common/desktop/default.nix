{ userConfig, ... }: {

  imports = if userConfig.gui == "hyprland" then [ ./hyprland ] else [ ];
}
