{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      # https://github.com/folke/lazy.nvim/
      # lazy-nvim
      # https://github.com/numtostr/comment.nvim/
      comment-nvim
      # https://github.com/akinsho/bufferline.nvim
      bufferline-nvim
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
      # https://github.com/nvim-telescope/telescope.nvim/
      telescope-nvim
      # https://github.com/lewis6991/gitsigns.nvim/
      gitsigns-nvim
      # https://github.com/sindrets/diffview.nvim/
      diffview-nvim
      # https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file
      (nvim-treesitter.withPlugins (p: [
        p.bash
        p.c
        p.dockerfile
        p.fish
        p.go
        p.json
        p.just
        p.lua
        p.make
        p.markdown
        p.nix
        p.proto
        p.python
        p.rust
        p.toml
        p.yaml
        p.query
      ]))
      # https://github.com/williamboman/mason.nvim/
      # mason-nvim
      # https://github.com/neovim/nvim-lspconfig/
      nvim-lspconfig
      # https://github.com/williamboman/mason-lspconfig.nvim/
      # mason-lspconfig-nvim
      # https://github.com/hrsh7th/nvim-cmp/
      nvim-cmp
      # https://github.com/hrsh7th/cmp-nvim-lsp/
      cmp-nvim-lsp
      # https://github.com/j-hui/fidget.nvim
      fidget-nvim
      # https://github.com/L3MON4D3/LuaSnip
      luasnip
      # https://github.com/stevearc/conform.nvim
      conform-nvim
    ];
  };

  xdg.configFile."nvim/init.lua" = {
    source = ./init.lua;
    recursive = true;
  };

  xdg.configFile."nvim/lua" = {
    source = ./lua;
    recursive = true;
  };
}
