{ pkgs, userConfig, ... }: {

  imports = [
    ./font
    ./tools
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = userConfig.name;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then
      "/Users/${userConfig.name}"
    else
      "/home/${userConfig.name}";

  # This value determines the Home Manager release
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
