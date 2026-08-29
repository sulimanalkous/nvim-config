return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Keymaps attached to every LSP client.
      -- Modern API (nvim 0.11+): LspAttach autocmd, no deprecated on_attach.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf, noremap = true, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        end,
      })

      -- Diagnostics UI
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Servers are installed by you (bootstrap.sh / brew / apt / pkg / npm),
      -- never by mason. key = vim.lsp.config name, cmd = binary on PATH.
      -- Modern API (nvim 0.11+): vim.lsp.config + vim.lsp.enable.
      local servers = {
        rust_analyzer = {
          cmd = { "rust-analyzer" },
          settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              check = { command = "clippy" },
              assist = {
                importGranularity = "module",
                importPrefix = "by_self",
              },
            },
          },
        },
        pyright = {
          cmd = { "pyright" },
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
              },
            },
          },
        },
        tailwindcss = {
          cmd = { "tailwindcss-language-server" },
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
                  "tw`([^`]*)",
                  'tw="([^"]*)',
                  'tw={"([^"}]*)"',
                  "tw\\.\\w+`([^`]*)",
                  "tw\\(.*?\\)`([^`]*)",
                },
              },
            },
          },
        },
        lua_ls = {
          cmd = { "lua-language-server" },
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
            },
          },
        },
        volar = { cmd = { "vue-language-server" } },
        solargraph = { cmd = { "solargraph" } },
      }

      -- Wire up only servers whose binary is actually on PATH. Install any of
      -- them yourself and they are picked up on the next nvim start.
      -- Missing servers are skipped silently — no errors, no warnings.
      for name, opts in pairs(servers) do
        if vim.fn.executable(opts.cmd[1]) == 1 then
          vim.lsp.config(name, {
            cmd = opts.cmd,
            settings = opts.settings,
            init_options = opts.init_options,
          })
          vim.lsp.enable(name)
        end
      end

      -- dartls is managed by flutter-tools.nvim.
    end,
  },
}
