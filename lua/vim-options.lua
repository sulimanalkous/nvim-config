vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")


vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline= true
vim.opt.termguicolors = true
vim.o.clipboard = "unnamedplus"

-- Set leader Key
vim.g.mapleader = ","

-- Set highlight for the current line number
vim.api.nvim_set_hl(0, "CursorLineNr", { bold = true })
