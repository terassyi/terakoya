{ ... }: {
  programs.git = {
    enable = true;

    userName = "terassyi";
    userEmail = "iscale821@gmail.com";

    delta.enable = true;

    extraConfig = { pull = { rebase = true; }; };
  };
}
