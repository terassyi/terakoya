{ userConfig, ... }: {
  imports = if userConfig.hasGUI then [ ./desktop ] else [ ];
}
