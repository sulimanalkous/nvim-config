
return { 
  "catppuccin/nvim", 
  lazy = false,
  name= "catppuccin", 
  priority = 1000,
  config = function()
    -- Load Theme
    vim.cmd.colorscheme "catppuccin"
  end
}

