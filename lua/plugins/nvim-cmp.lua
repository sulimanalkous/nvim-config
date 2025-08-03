return {
  {
    "hrsh7th/nvim-cmp", -- Completion plugin
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",     -- LSP completion
      "hrsh7th/cmp-buffer",       -- Buffer completion
      "hrsh7th/cmp-path",         -- File path completion
      "hrsh7th/cmp-cmdline",      -- Command-line completion
      "L3MON4D3/LuaSnip",         -- Snippets engine
      "saadparwaiz1/cmp_luasnip", -- Snippet completion
      "rafamadriz/friendly-snippets", -- Pre-configured snippets
      "tzachar/cmp-ai",           -- AI completion with DeepSeek
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load VSCode-style snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body) -- Use LuaSnip for snippet expansion
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(), -- Trigger completion
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Confirm selection
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }), -- Alternative accept key
          ["<C-e>"] = cmp.mapping(function(fallback)
            -- Prefer AI completion if available
            local entries = cmp.get_entries()
            for _, entry in ipairs(entries) do
              if entry.source.name == "cmp_ai" then
                cmp.confirm({ select = false })
                return
              end
            end
            -- Otherwise use normal confirm
            if cmp.visible() then
              cmp.confirm({ select = true })
            else
              fallback()
            end
          end, { "i" }), -- AI-focused accept key
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, -- LSP-based completion
          { name = "cmp_ai" },   -- AI completion with DeepSeek
          { name = "luasnip" }, -- Snippets
          { name = "buffer" }, -- Text from open buffers
          { name = "path" }, -- File path completion
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              cmp_ai = "[AI]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
      })

      -- Enable completion for command mode (e.g., `:help`)
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
        }),
      })
    end
  }
}

