return {
  {
    "akinsho/flutter-tools.nvim",
    ft = "dart",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      -- Only enable when the Flutter SDK is actually installed.
      -- Without it, dart files just open without LSP — silently.
      if vim.fn.executable("flutter") == 1 then
        require("flutter-tools").setup({})
      end
    end,
  },
}
