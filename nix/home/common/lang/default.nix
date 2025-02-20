{ pkgs, ... }: { home.packages = with pkgs; [ rustup go ]; }
