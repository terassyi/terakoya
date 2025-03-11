{ pkgs, userConfig, ... }: {
  imports = if userConfig.gui == "hyprland" then
    [ ./hyprland ]
  else if userConfig.gui == "gnome" then
    [ ]
  else
    [ ];
  environment.systemPackages = with pkgs; [
    # Freeware web browser developed by Google
    google-chrome
    # Desktop client for Slack
    slack
    # All-in-one cross-platform voice and text chat for gamers
    discord
    # zoom.us video conferencing application
    zoom-us
  ];
}
