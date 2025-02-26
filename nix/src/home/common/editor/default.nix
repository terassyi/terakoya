{ userConfig, ... }: {
  imports = if userConfig.hasGUI then [
    ./vim
    ./neovim
    ./vscode
  ] else [
    ./vim
    ./neovim
  ];
}
