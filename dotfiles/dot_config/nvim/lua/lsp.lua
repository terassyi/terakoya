-- LSP settings
require('fidget').setup()

-- LSP keymaps
vim.keymap.set('n', 'gl', '<cmd>lua vim.lsp.buf.references()<CR>')
vim.keymap.set('n', 'gk', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', 'gj', '<cmd>lua vim.lsp.buf.declaration()<CR>')
vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.implementation()<CR>')
vim.keymap.set('n', 'gp', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.rename()<CR>')
vim.keymap.set('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>')
vim.keymap.set('n', 'gu', '<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n', 'g]', '<cmd>lua vim.diagnostic.goto_next()<CR>')
vim.keymap.set('n', 'g[', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
vim.keymap.set('n', 'gf', '<cmd>lua vim.lsp.buf.formatting()<CR>')

-- For Formatting
require('conform').setup({
	formatters_by_ft = {
		rust = { "rustfmt", lsp_format = "fallback" },
		go = { "goimports", "gofmt" },
		lua = { "stylua" },
		nix = { "nixfmt" },
	},

	format_on_save = {
		lsp_format = "fallback",
		timeout_ms = 500,
	},
	notify_on_error = true,
})

-- For Completion
local cmp = require('cmp')
cmp.setup({
	sources = {
		{ name = "nvim_lsp" },
	},
	mapping = cmp.mapping.preset.insert({
		['<C-j>'] = cmp.mapping.select_next_item(),
		['<C-k>'] = cmp.mapping.select_prev_item(),
		["<C-'>"] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.abort(),
		['<CR>'] = cmp.mapping.confirm { select = true },
	}),
	['<CR>'] = cmp.mapping(function(fallback)
		if cmp.visible() then
			if luasnip.expandable() then
				luasnip.expand()
			else
				cmp.confirm({
					select = true,
				})
			end
		else
			fallback()
		end
	end),

	['<Tab>'] = cmp.mapping(function(fallback)
		if cmp.visible() then
			cmp.select_next_item()
		elseif luasnip.locally_jumpable(1) then
			luasnip.jump(1)
		else
			fallback()
		end
	end, { "i", "s" }),

	['<S-Tab>'] = cmp.mapping(function(fallback)
		if cmp.visible() then
			cmp.select_prev_item()
		elseif luasnip.locally_jumpable(-1) then
			luasnip.jump(-1)
		else
			fallback()
		end
	end, { "i", "s" }),
})

local lspconfig = require('lspconfig')

-- For Rust
lspconfig.rust_analyzer.setup {
	settings = {
		['rust-analyzer'] = {},
	},
}

-- For Go
lspconfig.gopls.setup {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmlp" },
	root_dir = lspconfig.util.root_pattern("go.work", "go.mod"),
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
}

-- For Nix
lspconfig.nixd.setup {}
