
-- Load lazy.nvim
vim.cmd [[set runtimepath+=~/.config/nvim/lazy]]

vim.cmd [[ autocmd BufWritePre * lua vim.lsp.buf.format() ]]

require("vim-options")
require("lazy").setup("plugins")

