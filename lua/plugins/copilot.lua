return {
  {
    "github/copilot.vim",
    config = function()
      -- Tab to accept suggestion
      vim.g.copilot_no_tab_map = true
      vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false
      })
      
      -- Navigate suggestions
      vim.keymap.set("i", "<C-H>", "<Plug>(copilot-previous)")
      vim.keymap.set("i", "<C-L>", "<Plug>(copilot-next)")
      vim.keymap.set("i", "<C-K>", "<Plug>(copilot-dismiss)")
    end,
  }
}