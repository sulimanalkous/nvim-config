-- Send any command's output to the quickfix list, like Emacs compilation-mode:
-- every "file:line: message" line becomes an entry you can jump to.
-- <CR> opens the entry, <leader>cn / <leader>cp walk the list.
local function to_quickfix(cmd)
  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 and #lines == 0 then
    vim.notify(("command failed (%d): %s"):format(vim.v.shell_error, cmd), vim.log.levels.WARN)
    return
  end
  vim.fn.setqflist({}, " ", { lines = lines, title = cmd })
  local n = #vim.fn.getqflist()
  if n == 0 then
    vim.notify("no file:line entries in output", vim.log.levels.INFO)
    return
  end
  vim.cmd("copen")
end

vim.api.nvim_create_user_command("Run", function(opts)
  to_quickfix(opts.args)
end, { nargs = "+", complete = "shellcmd", desc = "Run a shell command into the quickfix list" })

local map = vim.keymap.set
map("n", "<leader>cn", "<cmd>cnext<CR>", { desc = "Next error" })
map("n", "<leader>cp", "<cmd>cprev<CR>", { desc = "Previous error" })
map("n", "<leader>co", "<cmd>copen<CR>", { desc = "Open error list" })
map("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "Close error list" })

-- Zig puts a "referenced by:" trace after each error, which would land in the
-- quickfix list as noise. Keep only real diagnostics; drop every other line.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "zig",
  callback = function()
    vim.bo.makeprg = "zig build"
    vim.bo.errorformat = table.concat({
      "%f:%l:%c: error: %m",
      "%f:%l:%c: note: %m",
      "%-G%.%#",
    }, ",")
  end,
})

vim.keymap.set("n", "<leader>cb", "<cmd>make<CR>", { desc = "Build (make) and fill error list" })
