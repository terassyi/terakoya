{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      # https://github.com/numtostr/comment.nvim/
      comment-nvim
      # https://github.com/windwp/nvim-autopairs/
      nvim-autopairs
      # https://github.com/easymotion/vim-easymotion
      vim-easymotion
      # https://github.com/kylechui/nvim-surround
      nvim-surround
      # https://github.com/nvim-lualine/lualine.nvim/
      lualine-nvim
      # https://github.com/lukas-reineke/indent-blankline.nvim/
      indent-blankline-nvim
      # https://github.com/folke/which-key.nvim/
      which-key-nvim
      # https://github.com/folke/tokyonight.nvim/
      tokyonight-nvim
    ];

    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
