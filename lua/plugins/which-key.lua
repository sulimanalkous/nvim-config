return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 500,
    spec = {
      { "<leader>c", group = "💬 AI Assistant", mode = { "n", "v" } },
      { "<leader>f", group = "🔍 Find" },
      { "<leader>g", group = "🔧 Git" },
      { "<leader>t", group = "🧪 Test" },
      { "<leader>w", group = "🪟 Window" },
      { "<leader>b", group = "📂 Buffer" },
      { "g", group = "🎯 Go to" },
      { "z", group = "📁 Fold" },
      { "]", group = "➡️ Next" },
      { "[", group = "⬅️ Previous" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}