{ pkgs, ... }: {
  imports = [ ./hyprland ];
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
