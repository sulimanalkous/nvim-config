return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    -- Runs at startup, before netrw can load — makes neo-tree the only
    -- file explorer. Also auto-opens the tree when nvim is started with a
    -- directory argument (e.g. `nvim .`).
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local args = vim.fn.argv()
          if #args > 0 and vim.fn.isdirectory(args[1]) == 1 then
            vim.cmd("Neotree filesystem reveal left")
          end
        end,
      })
    end,
    cmd = "Neotree",
    keys = {
      { "<C-n>", "<cmd>Neotree filesystem reveal left<CR>", desc = "File explorer" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
      })
    end,
  },
}
