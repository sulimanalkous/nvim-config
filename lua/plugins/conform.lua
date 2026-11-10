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
      -- c3fmt ships with the C3 compiler (c3lsp cannot format). It reads a
      -- .c3fmt config found from the file's path, else its defaults (tabs,
      -- braces on their own line). On code with a syntax error it refuses and
      -- the buffer is left as is.
      local formatters = {}
      if vim.fn.executable("c3fmt") == 1 then
        formatters_by_ft.c3 = { "c3fmt" }
        formatters.c3fmt = {
          command = "c3fmt",
          args = { "--stdin", "--stdout", "--stdin-filepath", "$FILENAME" },
          stdin = true,
        }
      end
      return {
        formatters_by_ft = formatters_by_ft,
        formatters = formatters,
        format_on_save = {
          timeout_ms = 1000,
          lsp_fallback = true,
        },
      }
    end,
  },
}
