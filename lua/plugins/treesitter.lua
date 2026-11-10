return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup()

    -- New API (main branch rewrite): `ensure_installed` is gone, and
    -- highlight/indent are handled by nvim core (vim.treesitter).
    -- Install missing parsers on load; already-installed ones are skipped.
    require("nvim-treesitter").install({
      "lua", "vim", "vimdoc", "query", "bash", "json", "yaml", "toml",
      "markdown", "markdown_inline", "latex",
      "c", "cpp", "rust", "go", "zig", "c3", "python", "ruby", "java",
      "javascript", "typescript", "tsx", "html", "css", "vue", "svelte",
      "elixir", "heex", "eex",
    })

    -- Installing a parser does not turn it on: start tree-sitter highlighting
    -- for every buffer whose language has a parser installed; languages
    -- without one keep their regular vim syntax highlighting.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
