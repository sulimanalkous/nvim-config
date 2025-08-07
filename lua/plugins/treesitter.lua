
return {
  "nvim-treesitter/nvim-treesitter", 
  build = ":TSUpdate",
  config = function()
    require'nvim-treesitter.configs'.setup {
      ensure_installed = { 
        "rust", "javascript", "typescript", "html", "css", "python", "ruby", "java",
        "markdown", "markdown_inline", "latex", "vim", "vimdoc", "bash", "json", "yaml"
      },
      -- ensure_installed = "all",  -- Commented out to avoid conflicts
      highlight = { enable = true },
      indent = { enable = true },
    }
  end
}
