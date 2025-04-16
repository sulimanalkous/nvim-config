return {
  {
    "numToStr/Comment.nvim", -- Plugin for toggling comments
    config = function()
      require("Comment").setup({
        toggler = {
          line = "gcc", -- Toggle comment for a single line
          block = "gbc", -- Toggle comment for a block
        },
        opleader = {
          line = "gc", -- Comment operator
          block = "gb", -- Block comment operator
        },
        extra = {
          above = "gcO", -- Add comment above
          below = "gco", -- Add comment below
          eol = "gcA", -- Add comment at end of line
        },
        mappings = {
          basic = true, -- Enable default mappings (gcc, gbc, etc.)
          extra = true, -- Enable extra mappings (gcO, gco, gcA)
          extended = false, -- Enable extended mappings (comment text objects)
        },
      })
    end,
  }
}

