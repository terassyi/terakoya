{ pkgs, userConfig, ... }: {

  imports = if userConfig.gui != "none" then [
    ./shell
    ./desktop
    ./tools
  ] else [
    ./shell
    ./tools
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    ${userConfig.name} = {
      isNormalUser = true;
      description = "terassyi";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      shell = pkgs.fish;
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # OpenSSH Daemon
  services.openssh.enable = true;

  environment.localBinInPath = true;
  # Create /usr/local
  systemd.tmpfiles.rules = [ "d /usr/local 0755 root root -" ];

  system.stateVersion = "24.11"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
