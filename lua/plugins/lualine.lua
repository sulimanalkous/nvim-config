return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          -- "auto" takes the colours from the active colorscheme. The catppuccin
          -- plugin only ships catppuccin-mocha/latte/frappe/macchiato, so a plain
          -- "catppuccin" here made lualine warn and fall back anyway.
          theme = "auto",
          globalstatus = true,
        },
      })
    end,
  },
}
