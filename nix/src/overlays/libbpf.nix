self: super: {
  libbpf = super.libbpf.overrideAttrs (oldAttrs: {
    postInstall = ''
      ${oldAttrs.postInstall}
      echo "Run custom overlays for post installation of libbpf"
      # mkdir -p /usr/local/include/bpf
      # ln -s $out/include/bpf /usr/local/include/bpf
    '';
  });
}
