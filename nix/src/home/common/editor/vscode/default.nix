{ pkgs, ... }: {
  programs.vscode = {
    enable = true;

    profiles = {
      default = {
        enableUpdateCheck = false;
        userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
        keybindings = builtins.fromJSON (builtins.readFile ./keybindings.json);
        extensions = with pkgs.vscode-marketplace; [
          jnoortheen.nix-ide
          golang.go
          rust-lang.rust-analyzer
          panicbit.cargo
          ms-vscode.cpptools
          zxh404.vscode-proto3
          sumneko.lua
          bmalehorn.vscode-fish
          redhat.vscode-yaml
          zainchen.json
          timonwong.shellcheck
          idanp.checkpatch
          davidanson.vscode-markdownlint
          tamasfe.even-better-toml
          ms-vscode.hexeditor
          ms-vscode.makefile-tools
          skellock.just
          fill-labs.dependi
          streetsidesoftware.code-spell-checker
          shardulm94.trailing-spaces
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-containers
          ms-vscode.remote-explorer
          ms-azuretools.vscode-docker
          github.vscode-pull-request-github
          eamodio.gitlens
          ms-ceintl.vscode-language-pack-ja
          asvetliakov.vscode-neovim
          enkia.tokyo-night
        ];
      };
    };
  };
}
