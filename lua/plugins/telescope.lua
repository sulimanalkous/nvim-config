return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
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
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
}
