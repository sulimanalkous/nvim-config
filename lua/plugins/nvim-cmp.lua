return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          -- Nothing is pre-selected: <CR> keeps making a newline, and <C-y>
          -- accepts the item you picked with <Tab>. Typing a word and pressing
          -- Enter then never inserts a completion by accident.
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
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
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snip]",
              buffer = "[Buf]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
      })

      -- C3: c3lsp lists a module once per source file (std::io x40) and
      -- sends some faults with an empty label. Show each name once.
      local seen, seen_ctx = {}, nil
      cmp.setup.filetype("c3", {
        sources = cmp.config.sources({
          {
            name = "nvim_lsp",
            entry_filter = function(entry, ctx)
              if ctx ~= seen_ctx then
                seen, seen_ctx = {}, ctx
              end
              local item = entry:get_completion_item()
              if item.label == "" then
                return false
              end
              local key = item.label .. "\0" .. tostring(item.kind)
              if seen[key] then
                return false
              end
              seen[key] = true
              return true
            end,
          },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- Command-line completion (e.g. :help, :e)
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
        }),
      })
    end,
  },
}
