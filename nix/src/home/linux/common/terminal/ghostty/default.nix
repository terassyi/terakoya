{ userConfig, ... }: {
  programs.ghostty = { enable = userConfig.gui != "none"; };
  xdg.configFile."ghostty/config".source = ./config;
}
