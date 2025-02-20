{
  description = "Terakoya NIX configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, home-manager, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        legacyPackages = {
          inherit (pkgs) home-manager;
          homeConfigurations = {
            dev = home-manager.lib.homeManagerConfiguration {
              pkgs = pkgs;
              modules = [ ./home/common/home.nix ./home/dev/home.nix ];
            };
          };

        };
      });
}
