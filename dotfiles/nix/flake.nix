{
  description = "Dotfiles Nix configurations for fonts and desktop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Default user config
        userInfo = {
          name = "terassyi";
          hostname = "dev";
          email = "iscale821@gmail.com";
        };

        # allow unfree software
        allowUnfree = { nixpkgs.config.allowUnfree = true; };

        # nixpkgs
        pkgs = import nixpkgs { inherit system; };

        # OS name detection
        os = let
          arch_os =
            nixpkgs.legacyPackages.${system}.lib.strings.split "-" system;
        in if builtins.length arch_os > 1 then
          builtins.elemAt arch_os 2
        else
          system;

        # for Home Manager (fonts and desktop only)
        mkHomeConfiguration = { gui ? "none", username, email ? "" }:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              userConfig = {
                name = username;
                inherit email system gui;
              };
            };
            modules = [
              allowUnfree
              ./home/common
            ] ++ (if os == "linux" then [ ./home/linux/common ] else [ ])
              ++ (if os == "darwin" then [ ./home/darwin/common ] else [ ]);
          };
      in {
        # Home configurations for different setups
        legacyPackages.homeConfigurations = {
          # ===== Personal hosts (terassyi) =====
          # Development container/VM (no GUI)
          "terassyi@dev" = mkHomeConfiguration {
            gui = "none";
            username = "terassyi";
            email = "dev@terassyi.net";
          };

          # GitHub Actions / CI runner (no GUI)
          "runner@dev" = mkHomeConfiguration {
            gui = "none";
            username = "runner";
            email = "dev@terassyi.net";
          };

          # Development VM with GNOME
          "terassyi@devvm" = mkHomeConfiguration {
            gui = "gnome";
            username = userInfo.name;
            email = userInfo.email;
          };

          # Personal desktop with GNOME
          "terassyi@teradev" = mkHomeConfiguration {
            gui = "gnome";
            username = userInfo.name;
            email = userInfo.email;
          };

          # ===== Work hosts (terashima) =====
          # Work development (no GUI)
          "terashima@dev" = mkHomeConfiguration {
            gui = "none";
            username = "terashima";
            email = "tomoya-terashima@cybozu.co.jp";
          };

          # Work desk (no GUI)
          "terashima@fukdesk" = mkHomeConfiguration {
            gui = "none";
            username = "terashima";
            email = "tomoya-terashima@cybozu.co.jp";
          };

          # macOS (darwin1)
          "terashima@darwin1" = mkHomeConfiguration {
            gui = "mac";
            username = "terashima";
            email = userInfo.email;
          };

          # macOS (darwin2)
          "terashima@darwin2" = mkHomeConfiguration {
            gui = "mac";
            username = "terashima";
            email = userInfo.email;
          };
        };

        # Packages output for nix profile install
        packages = {
          default = pkgs.buildEnv {
            name = "dotfiles-fonts";
            paths = import ./home/common/font/packages.nix { inherit pkgs; };
          };
        };
      });
}
