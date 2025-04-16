return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      -- Rust LSP
      lspconfig.rust_analyzer.setup({
        cmd = { "rust-analyzer" }, -- Make sure this is installed in PATH
        filetypes = { "rust" },
        root_dir = lspconfig.util.root_pattern("Cargo.toml"),
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            assist = {
              importGranularity = "module",
              importPrefix = "by_self",
            },
            imports = {
              granularity = {
                group = "module",
              },
              prefix = "self",
            },
          },
        },
        on_attach = function(client, bufnr)
          -- Format on save (which includes auto-imports)
          if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ async = false })
              end,
            })
          end
        end,
      })

      -- TypeScript/JavaScript LSP
      lspconfig.tsserver.setup({
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
        root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
      })


      -- Tailwindcss
      lspconfig.tailwindcss.setup({
        cmd = { "tailwindcss-language-server", "--stdio" },
        filetypes = { "html", "css", "scss", "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte", "vue" },
        init_options = {
          userLanguages = {
            eelixir = "html-eex",
            eruby = "erb",
          },
        },
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                "tw`([^`]*)", -- tw`...`
                "tw=\"([^\"]*)", -- tw="..."
                "tw={\"([^\"}]*)", -- tw={"..."}
                "tw\\.\\w+`([^`]*)", -- tw.xxx`...`
                "tw\\(.*?\\)`([^`]*)", -- tw(...)`...`
              },
            },
          },
        },
      })



      -- Python LSP: pyright
      lspconfig.pyright.setup({
        cmd = { "pyright" },
        filetypes = { "python" },
        root_dir = lspconfig.util.root_pattern("pyproject.toml", "setup.py", "setup.cfg", ".git"),
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace", -- show errors from entire project 
              typeCheckingMode = "basic",   -- or "strict" for stronger errors 
            },
          },
        },
      })

      -- Enable diagnostics (errors & warnings)
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Keybindings for LSP functions
      vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })
    end
  }
}

