return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "hrsh7th/nvim-cmp",
      "j-hui/fidget.nvim", -- for status feedback
      "MeanderingProgrammer/render-markdown.nvim", -- optional markdown rendering
    },

    config = function()
      local cc = require("codecompanion")

      cc.setup({
        strategies = {
          chat = {
            adapter = "local_ai",
            window = {
              layout = "right", -- or "bottom"
              width = 0.4,
            },
          },

          inline = {
            adapter = "local_ai",
            keymaps = {
              accept_change = {
                modes = { n = "ga" },
                description = "Accept inline AI change",
              },
              reject_change = {
                modes = { n = "gr" },
                description = "Reject inline AI change",
                opts = { nowait = true },
              },
            },
          },

          cmd = {
            adapter = "local_ai",
          },
        },

        adapters = {
          local_ai = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              env = {
                url = "http://localhost:1234",
                api_key = "sk-local", -- dummy for LM Studio
                chat_url = "/v1/chat/completions",
                models_endpoint = "/v1/models",
              },
              schema = {
                model = {
                  default = "qwen2.5-coder-1.5b-Instruct",
                  type = "string",
                  description = "Model name to use with LM Studio",
                },
                temperature = {
                  type = "number",
                  default = 0.7,
                  desc = "Controls randomness (0.0 = deterministic, 1.0 = creative)",
                },
                max_completion_tokens = {
                  type = "integer",
                  default = 1024,
                  desc = "Max number of tokens to generate",
                },
              },
            })
          end,
        },

        -- Optional: enable logs if you want to debug
        log_level = "INFO",
      })

      -- Keymaps
      vim.keymap.set("n", "<leader>cc", ":CodeCompanionChatToggle<CR>", { desc = "Toggle AI Chat" })
      vim.keymap.set("v", "<leader>ca", ":CodeCompanionInlineAction<CR>", { desc = "AI Inline Action" })
    end,
  },

  {
    "j-hui/fidget.nvim",
    opts = {
      integration = {
        ["codecompanion.nvim"] = true,
      },
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
  },
}

