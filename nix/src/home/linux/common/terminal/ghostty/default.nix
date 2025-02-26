{ userConfig, ... }: { programs.ghostty = { enable = userConfig.hasGUI; }; }
