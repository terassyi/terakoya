{ pkgs, ... }: {

  fonts.fontconfig.enable = true;

  # Font packages are defined in packages.nix
  home.packages = import ./packages.nix { inherit pkgs; };

}
