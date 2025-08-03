return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dartls = {
          cmd = { "dart", "language-server", "--protocol=lsp" },
          filetypes = { "dart" },
          init_options = {
            closingLabels = true,
            outline = true,
            flutterOutline = true,
          },
          settings = {
            dart = {
              enableSdkFormatter = true,
            },
          },
        },
      },
    },
  },
}

