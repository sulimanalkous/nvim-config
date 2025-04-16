
return {
  "nvim-treesitter/nvim-treesitter", 
  build = ":TSUpdate",
  config = function()
    require'nvim-treesitter.configs'.setup {
      -- ensure_installed = { "rust", "javascript", "typescript", "html", "css", "python", "ruby", "java" },
      ensure_installed = "all",
      highlight = { enable = true },
      indent = { enable = true },
    }
  end
}
