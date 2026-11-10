-- Bootstrap lazy.nvim
vim.loader.enable()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" },
      { "\nPress any key to continue..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- bootstrap.sh installs zls, c3c, c3fmt and c3lsp into ~/.local/bin. Make
-- sure nvim sees them even when the shell's PATH doesn't include it.
local local_bin = vim.fn.expand("~/.local/bin")
if not vim.tbl_contains(vim.split(vim.env.PATH or "", ":"), local_bin) then
  vim.env.PATH = local_bin .. ":" .. (vim.env.PATH or "")
end

require("vim-options")
require("quickfix")
require("c3") -- after quickfix: overrides c3 makeprg for loose files
require("lazy").setup("plugins")

-- After the plugins are loaded: apply the saved theme and map <leader>tt.
require("theme").setup()
