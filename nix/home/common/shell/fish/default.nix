{ pkgs, ... }: {
  home.packages = with pkgs; [ fish ];
  programs.fish = {
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
  };
  # xdg.configFile."fish/functions" = {
  #   source = ./functions;
  #   recursive = true;
  # };
}
