-- Renders headings, bullets, checkboxes and code blocks inside a markdown
-- buffer. Needs the markdown and markdown_inline treesitter parsers, which
-- lua/plugins/treesitter.lua installs.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
}
