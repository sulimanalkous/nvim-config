return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        volar = {
          filetypes = { "vue", "javascript", "typescript" },
          init_options = {
            typescript = {
              tsdk = vim.fn.stdpath("data") .. "/npm/lib/node_modules/typescript/lib"
            }
          }
        },
      },
    },
  },
}

