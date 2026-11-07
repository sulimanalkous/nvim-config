-- Telescope pickers. Everything loads on first use through `keys`, so the
-- picker code costs nothing at startup.
local function buffer_picker()
  require("telescope.builtin").buffers({
    attach_mappings = function(_, map)
      local actions = require("telescope.actions")
      map("n", "d", actions.delete_buffer)
      map("i", "<C-d>", actions.delete_buffer)
      return true
    end,
  })
end

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fb", buffer_picker, desc = "Buffers (d to close)" },
      { "<leader>fc", "<cmd>Telescope git_commits<CR>", desc = "Git commits" },
      { "<leader>gb", "<cmd>Telescope git_branches<CR>", desc = "Git branches" },
      { "<leader>ld", "<cmd>Telescope lsp_definitions<CR>", desc = "LSP definitions" },
      { "<leader>lr", "<cmd>Telescope lsp_references<CR>", desc = "LSP references" },
      { "<leader>ls", "<cmd>Telescope lsp_document_symbols<CR>", desc = "LSP symbols" },
    },
    config = function()
      require("telescope").setup({})
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = require("telescope.themes").get_dropdown({}),
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
}
