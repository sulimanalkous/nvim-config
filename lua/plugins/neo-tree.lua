return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    -- Netrw must be off before nvim reads a directory argument. neo-tree loads
    -- lazily (cmd), so it is not there yet to do it; that is what this is for.
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      -- One owner for "nvim .": this autocmd. neo-tree's own netrw hijack is
      -- disabled below, because its deferred pass ran later and replaced the
      -- window with a blank buffer right after a file was opened from the tree.
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local args = vim.fn.argv()
          if #args > 0 and vim.fn.isdirectory(args[1]) == 1 then
            -- Netrw is off, so the directory argument leaves an empty buffer
            -- named after the directory. Drop it, or it shows up in :ls later.
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" and vim.fn.isdirectory(name) == 1 then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
            vim.cmd("Neotree filesystem reveal left")
          end
        end,
      })
    end,
    cmd = "Neotree",
    keys = {
      { "<C-n>", "<cmd>Neotree toggle<CR>", desc = "File explorer" },
    },
    opts = {
      filesystem = { hijack_netrw_behavior = "disabled" },
    },
  },
}
