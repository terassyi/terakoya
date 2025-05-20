self: super: {
  libbpf = super.libbpf.overrideAttrs (oldAttrs: {
    postInstall =
      ''echo "Run custom overlays for post installation of libbpf"'';
  });
}
