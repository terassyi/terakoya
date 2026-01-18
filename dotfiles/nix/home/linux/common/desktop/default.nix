{ userConfig, ... }: {

  imports = if userConfig.gui == "gnome" then
    [ ./gnome ]
  else
    [ ];
}
