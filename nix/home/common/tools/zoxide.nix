{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      # Fast cd command that learns your habits
      zoxide
    ];
  programs.zoxide.enable = true;
}
