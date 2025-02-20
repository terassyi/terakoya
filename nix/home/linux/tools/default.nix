{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      # Open source project to pack, ship and run any application as a lightweight container
      docker
    ];
}
