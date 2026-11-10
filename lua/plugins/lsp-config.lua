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
          -- Inlay hints: the server's inferred types shown inline (zls, clangd),
          -- drawn faint by quiet_inlay_hints() below. <leader>ch flips them in
          -- every buffer; a file opened later follows the last choice because it
          -- reads the vim.g flag here.
          vim.lsp.inlay_hint.enable(vim.g.inlay_hints_enabled ~= false, { bufnr = args.buf })
          vim.keymap.set("n", "<leader>ch", function()
            local on = not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf })
            vim.g.inlay_hints_enabled = on
            vim.lsp.inlay_hint.enable(on)
            vim.notify("inlay hints: " .. (on and "on" or "off"))
          end, { buffer = args.buf, desc = "Toggle inline hints" })
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        end,
      })

      -- Inlay hints sit inside the code, so draw them like comments: low
      -- contrast, no bold or italic. Re-applied when the colorscheme changes,
      -- so it follows every theme instead of hardcoding a grey.
      local function quiet_inlay_hints()
        local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
        vim.api.nvim_set_hl(0, "LspInlayHint", {
          fg = comment.fg,
          bg = nil,
          bold = false,
          italic = false,
        })
      end
      quiet_inlay_hints()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = quiet_inlay_hints })

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
        -- zls finds `zig` on PATH; build.zig marks the project root so
        -- zls analyses the whole project instead of one loose file.
        zls = {
          cmd = { "zls" },
          root_markers = { "build.zig", "build.zig.zon", ".git" },
        },
        -- c3lsp-fresh wraps c3lsp and clears its stdlib cache first: c3lsp
        -- 0.5.0 reloads that cache without function parameters, so hover
        -- would show "fn printfn()". The c3c and stdlib paths are passed in
        -- so hover, completion and go-to-definition reach into std::.
        c3_lsp = (function()
          local cmd = { "c3lsp-fresh" }
          local c3c = vim.fn.exepath("c3c")
          if c3c ~= "" then
            c3c = vim.fn.resolve(c3c)
            -- -c3c-path is the binary itself; -stdlib-path is the lib/ folder
            -- (c3lsp appends "std" on its own).
            vim.list_extend(cmd, { "-c3c-path", c3c })
            local lib = vim.fs.joinpath(vim.fs.dirname(c3c), "lib")
            if vim.fn.isdirectory(vim.fs.joinpath(lib, "std")) == 1 then
              vim.list_extend(cmd, { "-stdlib-path", lib })
            end
          end
          return {
            cmd = cmd,
            filetypes = { "c3", "c3i" },
            -- Use the c3c project root when there is one; for a loose file
            -- (learning, no project.json) use the file's own folder, so the
            -- server still indexes it and hover/completion work. Errors for
            -- loose files come from lua/c3.lua instead.
            root_dir = function(bufnr, on_dir)
              local root = vim.fs.root(bufnr, { "project.json", "manifest.json" })
              on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
            end,
          }
        end)(),
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
            filetypes = opts.filetypes,
            settings = opts.settings,
            init_options = opts.init_options,
            root_markers = opts.root_markers,
            root_dir = opts.root_dir,
          })
          vim.lsp.enable(name)
        end
      end

      -- dartls is managed by flutter-tools.nvim.
    end,
  },
}
