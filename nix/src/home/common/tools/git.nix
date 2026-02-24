{ pkgs, userConfig, ... }: {
  programs.git = {
    enable = true;

    userName = userConfig.name;
    userEmail = userConfig.email;

    delta.enable = true;

    extraConfig = {
      pull = { rebase = true; };
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
    };
  };

  # GitHub CLI tool
  programs.gh = {
    enable = true;
    extensions = with pkgs; [ gh-markdown-preview ];
    settings = { editor = "nvim"; };
  };

  # Blazing fast terminal-ui for Git written in Rust
  programs.gitui = { enable = true; };
}
