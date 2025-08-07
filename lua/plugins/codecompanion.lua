return {
  {
    "olimorris/codecompanion.nvim",
    enabled = false, -- Re-enabled, neoai has persistent parsing bugs
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "j-hui/fidget.nvim", -- for status feedback
      "MeanderingProgrammer/render-markdown.nvim", -- optional markdown rendering
    },

    init = function()
      require("plugins.codecompanion.fidget-spinner"):init()
    end,

    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = "llama-cpp",
          },
          inline = {
            adapter = "llama-cpp",
            keymaps = {
              accept_change = {
                modes = { n = "<leader>aa" },
                description = "Accept the suggested change",
              },
              reject_change = {
                modes = { n = "<leader>ar" },
                opts = { nowait = true },
                description = "Reject the suggested change",
              },
            },
          },
          cmd = {
            adapter = "llama-cpp",
          },
        },

        adapters = {
          ["llama-cpp"] = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              name = "llama-cpp",
              formatted_name = "Llama.cpp",
              env = {
                url = "http://localhost:1234",
              },
              schema = {
                model = {
                  default = "deepseek-coder-6.7b-instruct",
                },
                tools = {
                  enabled = true,
                },
              },
              handlers = {
                chat_output = function(self, data)
                  local openai = require("codecompanion.adapters.openai")
                  local result = openai.handlers.chat_output(self, data)
                  if result ~= nil then
                    result.output.role = "assistant" -- Fix role mapping for llama.cpp
                  end
                  return result
                end,
              },
            })
          end,
        },

        opts = {
          send_code = true,
          silence_notifications = false,
        },
        
        tools = {
          insert_edit_into_file = {
            enabled = true,
          },
          files = {
            enabled = true,
          },
          cmd_runner = {
            enabled = true,
          },
        },
        
        prompt_library = {
          ["Custom Code Edit"] = {
            strategy = "inline",
            description = "Apply code changes directly to files",
            opts = {
              auto_submit = true,
              stop_context_insertion = false,
            },
            prompts = {
              {
                role = "system",
                content = "You are a code editor. When asked to modify code, ALWAYS provide the exact replacement code that should be applied to the file. Never provide explanations or bash commands - only the code changes.",
              },
            },
          },
        },

        display = {
          chat = {
            intro_message = "Hello! How can I help you with code?",
          },
          inline = {
            layout = "vertical",
          },
        },

        log_level = "DEBUG",
        
        system_prompt = "You are an AI coding assistant. When users request file edits using @insert_edit_into_file, you must call the tool to apply changes directly to files. When users request command execution using @cmd_runner, you must execute the commands. Always use the available tools when requested.",
      })

      -- Official Recommended Workflow (from CodeCompanion docs)
      vim.keymap.set({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true, desc = "AI Actions Menu" })
      vim.keymap.set({ "n", "v" }, "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true, desc = "Toggle AI Chat" })
      
      vim.keymap.set("v", "<leader>cA", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true, desc = "Add selection to chat" })

      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])

      -- Core Commands
      vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { desc = "Open AI Chat" })
      vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { desc = "Chat about selection" })

      -- Inline Assistant
      vim.keymap.set("n", "<leader>ci", "<cmd>CodeCompanion<cr>", { desc = "Open Inline Assistant" })
      vim.keymap.set("v", "<leader>ci", "<cmd>CodeCompanion<cr>", { desc = "Inline Assistant for selection" })
      
      -- Command Mode
      vim.keymap.set("n", "<leader>cs", "<cmd>CodeCompanionCmd<cr>", { desc = "AI Command Mode" })

      -- Prompt Library Shortcuts (using '/' prefix)
      vim.keymap.set("n", "<leader>cf", "<cmd>CodeCompanion /fix<cr>", { desc = "AI Fix Code" })
      vim.keymap.set("n", "<leader>co", "<cmd>CodeCompanion /optimize<cr>", { desc = "AI Optimize Code" })
      vim.keymap.set("n", "<leader>ce", "<cmd>CodeCompanion /explain<cr>", { desc = "AI Explain Code" })
      vim.keymap.set("v", "<leader>cr", "<cmd>CodeCompanion /refactor<cr>", { desc = "AI Refactor Selection" })
      vim.keymap.set("n", "<leader>cd", "<cmd>CodeCompanion /document<cr>", { desc = "AI Document Code" })
      vim.keymap.set("n", "<leader>ct", "<cmd>CodeCompanion /tests<cr>", { desc = "AI Generate Tests" })

      vim.keymap.set("n", "<leader>ch", "<cmd>CodeCompanion /help<cr>", { desc = "AI Help" })
      vim.keymap.set("n", "<leader>cR", "<cmd>CodeCompanionChat RefreshCache<cr>", { desc = "Refresh Chat Cache" })

      -- Quick inline prompts
      vim.keymap.set("v", "<leader>cb", "<cmd>CodeCompanion Add debugging logs to this code<cr>", { desc = "Add Debug Logs" })
      vim.keymap.set("v", "<leader>cm", "<cmd>CodeCompanion Add comprehensive comments to this code<cr>", { desc = "Add Comments" })
      vim.keymap.set("n", "<leader>cp", "<cmd>CodeCompanion Review this file for potential improvements<cr>", { desc = "Code Review" })

      -- Manual accept/reject keymaps
      vim.keymap.set("n", "<leader>aa", function()
        local ok, result = pcall(function()
          require("codecompanion").accept()
        end)
        if not ok then
          print("No CodeCompanion changes to accept")
        end
      end, { desc = "Accept AI Changes (Manual)" })

      vim.keymap.set("n", "<leader>ar", function()
        local ok, result = pcall(function()
          require("codecompanion").reject()
        end)
        if not ok then
          print("No CodeCompanion changes to reject")
        end
      end, { desc = "Reject AI Changes (Manual)" })
    end,
  },

  {
    "j-hui/fidget.nvim",
    opts = {},
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
  },
}
