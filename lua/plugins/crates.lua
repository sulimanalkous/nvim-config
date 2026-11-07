-- Cargo.toml helper: crate name completion, versions, features and deps.
return {
  {
    "saecki/crates.nvim",
    tag = "stable",
    event = { "BufRead Cargo.toml" },
    config = function()
      require("crates").setup({
        completion = {
          crates = { enabled = true, max_results = 8, min_chars = 3 },
        },
        lsp = {
          enabled = true,
          actions = true,
          completion = true,
          hover = true,
          -- Buffer-local in Cargo.toml only, so `K`, and the <leader>c keys
          -- below never leak into code buffers.
          on_attach = function(_, bufnr)
            local crates = require("crates")
            local opts = { buffer = bufnr }
            vim.keymap.set("n", "K", crates.show_popup, opts)
            vim.keymap.set("n", "<leader>ct", crates.toggle, opts)
            vim.keymap.set("n", "<leader>cr", crates.reload, opts)
            vim.keymap.set("n", "<leader>cv", crates.show_versions_popup, opts)
            vim.keymap.set("n", "<leader>cf", crates.show_features_popup, opts)
            vim.keymap.set("n", "<leader>cd", crates.show_dependencies_popup, opts)
            vim.keymap.set("n", "<leader>cu", crates.update_crate, opts)
            vim.keymap.set("v", "<leader>cu", crates.update_crates, opts)
            vim.keymap.set("n", "<leader>cU", crates.upgrade_crate, opts)
            vim.keymap.set("v", "<leader>cU", crates.upgrade_crates, opts)
            vim.keymap.set("n", "<leader>cA", crates.upgrade_all_crates, opts)
          end,
        },
      })

      -- Crate names complete in Cargo.toml only; everywhere else keeps the
      -- normal LSP/snippet sources from nvim-cmp.
      vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("CmpSourceCargo", { clear = true }),
        pattern = "Cargo.toml",
        callback = function()
          require("cmp").setup.buffer({
            sources = { { name = "crates" }, { name = "nvim_lsp" }, { name = "path" } },
          })
        end,
      })
    end,
  },
}
