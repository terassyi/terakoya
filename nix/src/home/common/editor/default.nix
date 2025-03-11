{ userConfig, ... }: {
  imports = if userConfig.gui != "none" then [
    ./vim
    ./neovim
    ./vscode
  ] else [
    ./vim
    ./neovim
  ];
}
