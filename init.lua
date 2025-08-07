
-- Load lazy.nvim
vim.cmd [[set runtimepath+=~/.config/nvim/lazy]]

vim.cmd [[ autocmd BufWritePre * lua vim.lsp.buf.format() ]]

require("vim-options")
require("lazy").setup("plugins")

-- Load avante_lib (required for the llama-support fork)
require('avante_lib').load()

