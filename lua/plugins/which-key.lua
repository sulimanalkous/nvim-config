return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      spec = {
        { "<C-x>", group = "Emacs C-x" },
        { "g", group = "Go to" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code / Crates" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
        { "<leader>r", group = "Ruby" },
        { "<leader>t", group = "Theme" },
        { "<leader>w", group = "Window" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          -- every keymap: global ones (all the C-x chords) and this
          -- buffer's own (LSP, Ruby...), not just the buffer-local ones
          require("which-key").show({ global = true })
        end,
        desc = "All keymaps (which-key)",
      },
    },
  },
}
