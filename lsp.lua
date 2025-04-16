local lspconfig = require("lspconfig")

lspconfig.rust_analyzer.setup({})
lspconfig.tsserver.setup({})
lspconfig.pyright.setup({})
lspconfig.solargraph.setup({})
lspconfig.jdtls.setup({})

vim.o.completeopt = "menuone,noselect"

local cmp = require("cmp")
cmp.setup({
    mapping = {
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
    },
    sources = { { name = "nvim_lsp" } },
})


-- Adding Rust-Analyzer
lspconfig.rust_analyzer.setup({
  cmd = { "rust-analyzer" },
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = {
        command = "clippy"
      }
    }
  }
})
