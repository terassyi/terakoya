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
    };

    shellInit = ''
      set -Ux COLOERTERM truecolor
      set -Ux SKIM_DEFAULT_COMMAND 'rg --files --hidden --follow --glob \"!.git/*\"'
      set -Ux SKIM_DEFAULT_OPTIONS "--color=fg:#e6e6fa,fg+:#333333,bg+:#dda0dd,pointer:#ff0000,hl:#dda0dd,hl+:#dda0dd --height=30% --layout=reverse"
    '';

    interactiveShellInit = ''
      skim_key_bindings
      bind \cr sk_history
      bind \cf sk_bat
      bind \cd sk_zoxide
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

    };
  };

  xdg.configFile."fish/functions" = {
    source = ./functions;
    recursive = true;
  };
}
