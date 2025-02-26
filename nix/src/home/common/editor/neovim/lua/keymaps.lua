-- Key maps

-- Change learder from '\' to ' '
vim.g.mapleader = " "

-- For saving file
vim.keymap.set('n', '<leader>w', ':w<CR>')

-- For exiting nvim
vim.keymap.set('n', '<leader>q', ':q')

-- For moving buffers
vim.keymap.set('n', '<leader>u', '<cmd>bnext<CR>', { desc = "Next buffer" })
vim.keymap.set('n', '<leader>y', '<cmd>bprevious<CR>', { desc = "Previous buffer" })

-- For moving windows
vim.keymap.set('n', '<leader>l', '<C-w>l', { desc = "Move to a right window" })
vim.keymap.set('n', '<leader>h', '<C-w>h', { desc = "Move to a left window" })
vim.keymap.set('n', '<leader>j', '<C-w>j', { desc = "Move to a bottom window" })
vim.keymap.set('n', '<leader>k', '<C-w>k', { desc = "Move to a upper window" })

-- For moving cursor
vim.keymap.set('n', '<C-}>', '<C-i>', { desc = "Jump forward"})
vim.keymap.set('n', '<C-{>', '<C-o>', { desc = "Jump back"})

-- For Bufferlilne
vim.keymap.set('n', '<leader>wall', '<cmd>BufferLineCloseOthers<CR>')
vim.keymap.set('n', '<leader>bs', '<cmd>BufferLineSortByDirectory<CR>')


-- For telescope
local telescope = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', telescope.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', telescope.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', telescope.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', telescope.help_tags, { desc = 'Telescope help tags' })

-- For Gitsigns
local gitsigns = require('gitsigns')
vim.keymap.set('n', '<leader>gb', function()
	gitsigns.blame_line({ full = true })
end, { desc = "Git blame" })

-- For Diffview
vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen HEAD~1', { desc = "Show git diff" })
