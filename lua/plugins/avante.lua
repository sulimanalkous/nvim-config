return {
  dir = vim.fn.stdpath("config") .. "/avante.nvim-llama-support",
  name = "avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- set this if you want to always pull the latest change

  opts = function()
    -- Auto-detect model based on environment or default
    local function get_model_name()
      if vim.env.AVANTE_MODEL then
        return vim.env.AVANTE_MODEL
      end
      
      -- Try to detect from running process (optional)
      local handle = io.popen("ps aux | grep llama-server | grep -v grep | head -1")
      if handle then
        local result = handle:read("*a")
        handle:close()
        
        if result:match("deepseek%-r1") then
          return "DeepSeek-R1-Distill-Qwen-1.5B"
        elseif result:match("deepseek") then
          return "deepseek-coder"
        elseif result:match("mistral") then
          return "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
        elseif result:match("phi4") then
          return "Phi-4"
        elseif result:match("qwen%-coder%-7b") then
          return "Qwen2.5-Coder-7B-Instruct"
        elseif result:match("qwen") then
          return "Qwen2.5-Coder-1.5B-Instruct"
        end
      end
      
      -- Default fallback - try a code model
      return "deepseek-coder"
    end

    return {
      provider = "llama",
      debug = false,
      auto_suggestions = false,
      auto_set_keymaps = true,
      auto_set_highlight_group = true,
      support_paste_from_clipboard = true,
      llama = {
        endpoint = "http://127.0.0.1:1234/v1",
        model = get_model_name(), -- Auto-detect from llama-server
        ["local"] = true,
        options = {
          num_ctx = 32768,
          temperature = 0,
        },
      },
      rag_service = {
        enabled = false,
        host_mount = os.getenv("HOME"),
        runner = "docker",
        llm = {
          provider = "llama",
          endpoint = "http://127.0.0.1:1234/v1",
          model = get_model_name(),
          extra = nil,
        },
        embed = {
          provider = "llama",
          endpoint = "http://127.0.0.1:1234/v1",
          model = get_model_name(),
          extra = nil,
        },
        docker_extra_args = "",
      },
      behaviour = {
        auto_suggestions = true, -- Enable auto-suggestions
        auto_set_highlight_group = true, 
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false, -- Manual control over diffs
        support_paste_from_clipboard = true,
      },
      windows = {
        position = "right",
        wrap = true,
        width = 30,
        sidebar_header = {
          align = "center",
          rounded = true,
        },
        input = {
          prefix = "> ",
        },
      },
      hints = { enabled = true },
    }
  end,
  -- Already built manually, no build command needed
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
