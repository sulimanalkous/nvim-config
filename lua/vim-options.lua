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

-- Leader key: space (thumb reach; `,` was awkward to type).
vim.g.mapleader = " "
-- Space is also a motion, so a short timeout keeps it from feeling stuck.
vim.o.timeoutlen = 300

-- Highlight the current line number
vim.api.nvim_set_hl(0, "CursorLineNr", { bold = true })

-- Windows and splits (the <leader>w group is declared in which-key.lua).
local map = vim.keymap.set
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>wq", "<C-w>q", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Close other windows" })

-- Emacs-style buffers: a visited buffer stays alive after you switch away from
-- it, so changing buffers or closing a window never forces a save first.
-- Switching by name is telescope's <leader>fb; <C-^> jumps to the last buffer.
vim.o.hidden = true

-- Kill the current buffer, keeping the window open (Emacs C-x k).
local kill_buffer = function()
  local buf = vim.api.nvim_get_current_buf()
  local force = ""
  if vim.bo[buf].modified then
    if vim.fn.confirm("Kill modified buffer?", "&Yes\n&No", 2) ~= 1 then
      return
    end
    force = "!"
  end
  vim.cmd("bdelete" .. force .. " " .. buf)
end

-- Buffer keys (the <leader>b group is declared in which-key.lua).
map("n", "<leader>bd", kill_buffer, { desc = "Kill buffer" })
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bs", "<cmd>wall<CR>", { desc = "Save all buffers" })

-- Emacs chords: the same C-x prefix Emacs uses for files, buffers and windows.
map("n", "<C-x><C-f>", "<cmd>Telescope find_files<CR>", { desc = "Find file" })
map("n", "<C-x>b", "<cmd>Telescope buffers<CR>", { desc = "Switch buffer" })
-- Cycle buffers in this window (Emacs C-x LEFT/RIGHT), n/p avoids the arrows.
map("n", "<C-x><Left>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<C-x><Right>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<C-x>p", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<C-x>n", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<C-x>k", kill_buffer, { desc = "Kill buffer" })
map("n", "<C-x><C-s>", "<cmd>write<CR>", { desc = "Save buffer" })
map("n", "<C-x>s", "<cmd>wall<CR>", { desc = "Save all buffers" })
map("n", "<C-x>2", "<C-w>s", { desc = "Split below" })
map("n", "<C-x>3", "<C-w>v", { desc = "Split right" })
map("n", "<C-x>o", "<C-w>w", { desc = "Other window" })
map("n", "<C-x>0", "<C-w>q", { desc = "Close window" })
map("n", "<C-x>1", "<C-w>o", { desc = "Close other windows" })

-- Terminal buffers: <Esc><Esc> leaves terminal mode. The built-in <C-\><C-n> is
-- often swallowed by the terminal emulator or tmux, so offer a typeable way.
-- A single <Esc> still reaches whatever runs in the shell.
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- C-x t: toggle a terminal at the bottom, like a popup vterm/eshell. The same
-- shell is kept between toggles (its history and running jobs survive); type
-- `exit` in it to end it, and the next C-x t starts a fresh one. Works from
-- inside the terminal too, so the same chord hides it again.
local term_buf
local function toggle_terminal()
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    local win = vim.fn.bufwinid(term_buf)
    if win ~= -1 then
      if #vim.api.nvim_list_wins() > 1 then
        vim.api.nvim_win_close(win, false)
      else
        vim.cmd("buffer #") -- last window: show the previous buffer instead
      end
      return
    end
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, term_buf)
  else
    vim.cmd("botright split")
    vim.cmd("terminal")
    term_buf = vim.api.nvim_get_current_buf()
    vim.bo[term_buf].buflisted = false -- keep it out of C-x b / C-x n
  end
  vim.api.nvim_win_set_height(0, math.max(10, math.floor(vim.o.lines * 0.3)))
  vim.cmd("startinsert")
end
map({ "n", "t" }, "<C-x>t", toggle_terminal, { desc = "Toggle terminal" })
