{ userConfig, ... }: {

  imports = if userConfig.gui == "hyprland" then
    [ ./hyprland ]
  else if userConfig.gui == "gnome" then
    [ ./gnome ]
  else
    [ ];
}
