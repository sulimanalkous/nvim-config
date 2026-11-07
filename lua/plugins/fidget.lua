-- LSP progress and notifications in the bottom-right corner.
--
-- The opts table must not call require("fidget...") directly: a spec is
-- evaluated at IMPORT time, before its plugin is on the runtimepath, and a
-- failing require there makes lazy discard the whole spec ("Failed to load
-- `plugins.fidget`"). The require lives in `config` instead, which lazy runs
-- after the plugin is loaded.
return {
  "j-hui/fidget.nvim",
  opts = {
    progress = {
      poll_rate = 0,
      suppress_on_insert = false,
      ignore_done_already = false,
      ignore_empty_message = false,
      clear_on_detach = function()
        return true
      end,
      -- One group per LSP client, so each server gets its own line.
      notification_group = function(msg)
        return msg.lsp_client and msg.lsp_client.name or "default"
      end,
      display = {
        render_limit = 16,
        done_ttl = 3,
        done_icon = "✓",
        done_style = "Constant",
        progress_ttl = math.huge,
        progress_icon = { pattern = "dots", period = 1 },
        progress_style = "WarningMsg",
        group_style = "Title",
        icon_style = "Question",
        priority = 30,
      },
    },
    notification = {
      poll_rate = 10,
      filter = vim.log.levels.INFO,
      history_size = 128,
      override_vim_notify = false,
      configs = {},
      redirect = function(msg, level, opts)
        if opts and opts.on_open then
          return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
        end
      end,
      view = {
        stack_upwards = true,
        icon_separator = " ",
        group_separator = "---",
        group_separator_hl = "Comment",
        render_message = function(msg, cnt)
          return cnt == 1 and msg or string.format("(%dx) %s", cnt, msg)
        end,
      },
      window = {
        normal_hl = "Comment",
        winblend = 0,
        border = "none",
        zindex = 45,
        max_width = 0,
        max_height = 0,
        x_padding = 1,
        y_padding = 0,
        align = "bottom",
        relative = "editor",
        avoid = { "NvimTree" },
      },
    },
    logger = {
      level = vim.log.levels.WARN,
      max_size = 10000,
      float_precision = 0.01,
      path = string.format("%s/fidget.nvim.log", vim.fn.stdpath("cache")),
    },
  },
  config = function(_, opts)
    opts.notification.configs.default = require("fidget.notification").default_config
    require("fidget").setup(opts)
  end,
}
