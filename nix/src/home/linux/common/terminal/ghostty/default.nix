{ userConfig, ... }: {
  programs.ghostty = { enable = userConfig.gui != "none"; };
}
