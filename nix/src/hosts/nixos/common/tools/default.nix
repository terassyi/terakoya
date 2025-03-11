{ pkgs, ... }: {
  environment.systemPackages = with pkgs;
    [
      # Container runtime written in Rust
      youki
    ];
}
