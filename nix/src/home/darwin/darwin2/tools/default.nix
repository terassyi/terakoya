{ pkgs, ... }: {
  home.packages = with pkgs; [
    google-cloud-sdk
    docker
    docker-credential-helpers
  ];
}
