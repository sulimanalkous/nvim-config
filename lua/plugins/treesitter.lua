return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup()

    -- New API (main branch rewrite): `ensure_installed` is gone, and
    -- highlight/indent are handled by nvim core (vim.treesitter).
    -- Install missing parsers on load; already-installed ones are skipped.
    require("nvim-treesitter").install({
      "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
      "markdown", "markdown_inline",
      "rust", "go", "c", "cpp", "python", "ruby", "java",
      "javascript", "typescript", "tsx", "html", "css", "vue",
      "latex",
    })
  end,
}
