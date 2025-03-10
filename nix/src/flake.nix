{
  description = "Terakoya Nix configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for rust tool chain
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for NixOS
    hardware.url = "github:nixos/nixos-hardware";

    # for Darwin
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for VSCode
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, darwin, fenix
    , nix-vscode-extensions, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (self) outputs;
        inherit (self) inputs;
        # default user config
        userInfo = {
          name = "terassyi";
          hostname = "dev";
          email = "iscale821@gmail.com";
        };

        # OS name
        os = let
          arch_os =
            nixpkgs.legacyPackages.${system}.lib.strings.split "-" system;
        in if builtins.length arch_os > 1 then
          builtins.elemAt arch_os 2
        else
          system;

        # allow unfree software
        allowUnfree = { nixpkgs.config.allowUnfree = true; };

        # rust tool chain
        overlays =
          [ fenix.overlays.default nix-vscode-extensions.overlays.default ];

        # nixpkgs
        pkgs = import nixpkgs { inherit system overlays; };

        # for NixOS
        mkNixosConfiguration = system: hasGUI: hostname: username:
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
              userConfig = {
                name = username;
                hostname = hostname;
              };
            };
            modules =
              [ allowUnfree ./hosts/nixos/common ./hosts/nixos/${hostname} ];
          };
        # for Darwin
        mkDarwinConfiguration = system: hostname: username:
          darwin.lib.darwinSystem {
            specialArgs = {
              inherit inputs outputs hostname;
              userConfig = {
                # inherit hasGUI;
                hasGUI = true;
                name = username;
              };
            };
            modules = [ home-manager.darwinModules.home-manager ];
          };
        # for Home Manager
        mkHomeConfiguration = system: hasGUI: hostname: username: email:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit inputs outputs;
              userConfig = {
                name = username;
                email = email;
                inherit system;
                inherit hasGUI;
              };
            };
            modules = [
              allowUnfree
              ./home/common
              ./home/${os}/common
              ./home/${os}/${hostname}
            ];
          };
      in {
        legacyPackages = {
          nixosConfigurations = {
            devvm = mkNixosConfiguration system true "devvm" "terassyi";
          };
          homeConfigurations = {
            "terassyi@dev" =
              mkHomeConfiguration system false userInfo.hostname userInfo.name
              "dev@terassyi.net";
            "terassyi@devvm" =
              mkHomeConfiguration system true "devvm" userInfo.name
              userInfo.email;
            "terashima@fukdesk" =
              mkHomeConfiguration system false "fukdesk" "terashima"
              "terashima-tomoya@cybozu.co.jp";
            "terashima@darwin1" =
              mkHomeConfiguration system "darwin1" "terashima" userInfo.email;
            "terassyi@teradev" =
              mkHomeConfiguration system true "teradev" userInfo.name
              userInfo.email;
          };
        };
      });
}

