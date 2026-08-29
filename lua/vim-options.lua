-- Editor basics
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.o.clipboard = "unnamedplus"

-- Indentation (2 spaces)
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true

-- Leader key
vim.g.mapleader = ","

-- Highlight the current line number
vim.api.nvim_set_hl(0, "CursorLineNr", { bold = true })
