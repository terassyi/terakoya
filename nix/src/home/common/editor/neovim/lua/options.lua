-- Basic options

local opts = {
	encoding = "utf-8",
	shell = "fish",
	number = true,
	cursorline = true,
	cursorcolumn = true,
	termguicolors = true,
	shiftwidth = 4,
	expandtab = true,
	smarttab = true,
	autoindent = true,
	tabstop = 4,
	list = true,
	listchars = { space = "•", tab = "> " },
	mouse = "a",
	clipboard = "unnamedplus",
	hlsearch = true,
	incsearch = true,
	splitright = true,
	splitbelow = true,
}

for k, v in pairs(opts) do
	vim.opt[k] = v
end

-- For Clipboard
-- ref: https://neovim.io/doc/user/provider.html#clipboard-osc52
-- vim.g.clipboard = {
--   name = 'OSC 52',
--   copy = {
--     ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
--     ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
--   },
--   paste = {
--     ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
--     ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
--   },
-- }
