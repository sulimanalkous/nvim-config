return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      -- Only register prettier as a formatter if the binary exists on PATH,
      -- otherwise format_on_save would error on every save of a JS file.
      local prettier_fts = {
        "javascript", "typescript", "javascriptreact", "typescriptreact",
        "vue", "css", "html", "json", "jsonc", "markdown", "yaml",
      }
      local formatters_by_ft = {}
      if vim.fn.executable("prettier") == 1 then
        for _, ft in ipairs(prettier_fts) do
          formatters_by_ft[ft] = { "prettier" }
        end
      end
      return {
        formatters_by_ft = formatters_by_ft,
        format_on_save = {
          timeout_ms = 1000,
          lsp_fallback = true,
        },
      }
    end,
  },
}
