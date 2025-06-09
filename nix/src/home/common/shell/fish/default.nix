{ lib, pkgs, ... }: {
  # home.packages = with pkgs; [ fish ];
  programs.fish = let
    inherit (lib.strings) fileContents;
    skim_key_bindings_file = builtins.fetchurl {
      # make sure using skim version
      # $ sk --version
      # sk 0.16.0
      url =
        "https://raw.githubusercontent.com/skim-rs/skim/refs/tags/v0.16.0/shell/key-bindings.fish";
      sha256 =
        "2626d29aef4c0d4df2b9ff9ef2ec7306e84f3fa95ff30efa793fe8aa8aa295c1";
    };
    skim_key_bindings_fileContent = builtins.readFile skim_key_bindings_file;
  in {
    enable = true;
    shellAliases = {
      ".." = "cd ..";
      "cl" = "clear";
      "ls" = "eza";
      "ll" = "eza -lh";
      "la" = "eza -alh";
    };

    shellAbbrs = {
      "g" = "git";
      "ga" = "git add";
      "gc" = "git commit";
      "gd" = "git diff";
      "gl" = "git log";
      "gs" = "git status";
      "gps" = "git push";
      "gpl" = "git pull";
      "gsw" = "git switch";

      "k" = "kubectl";

      "zl" = "zellij";
      "zgh" = "z ~/workspace/github.com";
    };

    shellInit = ''
      set -Ux COLOERTERM truecolor
      set -Ux SKIM_DEFAULT_COMMAND 'rg --files --hidden --follow --glob \"!.git/*\"'
      set -Ux SKIM_DEFAULT_OPTIONS "--color=fg:#e6e6fa,fg+:#333333,bg+:#dda0dd,pointer:#ff0000,hl:#dda0dd,hl+:#dda0dd --height=30% --layout=reverse"
      set -Ux GOPATH $HOME/go
      set -Ux GOROOT /usr/local/go

      set -Ux GH_REPO_HOME $HOME/workspace/github.com

      fish_add_path /usr/local/go/bin
      fish_add_path /nix/var/nix/profiles/default/bin
      fish_add_path $HOME/.nix-profile/bin
      fish_add_path $GOPATH/bin
    '';

    interactiveShellInit = ''
      set -Ux TERM xterm-256color
      skim_key_bindings
      bind \cr sk_history
      bind \cf sk_bat
      bind \cd sk_zoxide
      bind \cu sk_zoxide_gh
      bind \cv sk_code_repo

      tools_version_init
    '';

    functions = {
      fish_greeting = "";
      skim_key_bindings = skim_key_bindings_fileContent;

      sk_history = ''
        function sk_history
          history merge
          set cmd (history -z | sk --read0 --prompt="" --header=QUERY)
          if test -n "$cmd"
            commandline -- $cmd
            commandline -f repaint
          end
        end
      '';

      sk_zoxide = ''
        function sk_zoxide
          set dir (fd --type=d | sk --prompt="" --header=DIR)
          if test -n "$dir"
            z $dir
          end
        end
      '';

      sk_bat = ''
        function sk_bat
          set file (fd --type=file | sk --prompt="" --header=FILE)
          if test -n "$file"
            commandline -- "bat $file"
            commandline -f repaint
          end
        end
      '';

      sk_zoxide_gh = ''
        function sk_zoxide_gh
          set repo (fd --type=d --max-depth 2 . $GH_REPO_HOME | sk --prompt="" --header=REPO)
          if test -n "$repo"
            z $repo
          end
        end
      '';

      sk_code_repo = ''
        function sk_code_repo
          set repo (fd --type=d --max-depth 2 . $GH_REPO_HOME | sk --prompt="" --header=REPO)
          if test -n "$repo"
            code $repo
          end
        end
      '';

      clone = ''
        function clone -d "clone <owner>/<name>"
          if test (count $argv) -eq 0
            echo "Specify owner/repo"
            exit 1
          end
          set p $argv[1]
          if test (count (string split "/" $p)) -ne 2
            echo "Set default owner: terassyi"
            set p "terassyi/$p"
          end

          set full_path "$GH_REPO_HOME/$p"

          echo "Clone repository: $full_path"
          gh repo clone $p $full_path

        end
      '';

    };
  };

  xdg.configFile."fish/functions" = {
    source = ./functions;
    recursive = true;
  };
}
