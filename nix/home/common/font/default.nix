{ pkgs, ... }: {

  fonts.fontconfig.enable = true;
  # Font list is here
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
  home.packages = with pkgs; [ nerd-fonts.noto ];

}
