{ userConfig, ... }: {

  imports = [
    ./desktop
  ] ++ (if userConfig.gui != "none" then [ ./gui.nix ] else [ ]);

}
