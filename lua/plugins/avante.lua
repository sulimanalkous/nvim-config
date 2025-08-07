return {
  dir = vim.fn.stdpath("config") .. "/avante.nvim-llama-support",
  name = "avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- set this if you want to always pull the latest change

  opts = function()
    -- Auto-detect actual active model from llama-server API
    local function get_model_name()
      if vim.env.AVANTE_MODEL then
        return vim.env.AVANTE_MODEL
      end
      
      -- Try to get actual model from llama-server API
      local function query_server_model()
        local curl_cmd = "curl -s -m 3 http://127.0.0.1:1234/v1/models 2>/dev/null"
        local handle = io.popen(curl_cmd)
        if handle then
          local result = handle:read("*a")
          handle:close()
          
          if result and result ~= "" then
            -- Try to parse JSON response
            local model_match = result:match('"id"%s*:%s*"([^"]+)"')
            if model_match then
              -- Clean up the model name and categorize it
              local clean_name = model_match:lower()
              if clean_name:match("deepseek.*6%.?7") then
                return "deepseek-coder-6.7b"
              elseif clean_name:match("deepseek.*r1") then
                return "deepseek-r1"
              elseif clean_name:match("deepseek") then
                return "deepseek-coder"
              elseif clean_name:match("qwen.*7b") or clean_name:match("qwen.*7%-") then
                return "qwen2.5-7b"
              elseif clean_name:match("qwen.*1%.5b") or clean_name:match("qwen.*1%-5") then
                return "qwen2.5-1.5b"
              elseif clean_name:match("qwen") then
                return "qwen2.5-coder"
              elseif clean_name:match("llama.*3%.1.*8b") then
                return "llama-3.1-8b"
              elseif clean_name:match("llama") then
                return "llama"
              elseif clean_name:match("mistral.*7b") then
                return "mistral-7b-instruct"
              elseif clean_name:match("mistral") then
                return "mistral-7b-instruct"
              else
                return model_match -- Return the actual model name if we can't categorize
              end
            end
          end
        end
        return nil
      end
      
      -- First try API, then fallback to process detection
      local api_model = query_server_model()
      if api_model then
        return api_model
      end
      
      -- Fallback: Try to detect from running process
      local handle = io.popen("ps aux | grep llama-server | grep -v grep | head -1")
      if handle then
        local result = handle:read("*a")
        handle:close()
        -- Match your specific models from process name
        if result:match("deepseek%-coder.*6%.7[bB]") then
          return "deepseek-coder-6.7b"
        elseif result:match("deepseek%-r1") then
          return "deepseek-r1"
        elseif result:match("deepseek") then
          return "deepseek-coder"
        elseif result:match("qwen.*2%.5.*7[bB]") then
          return "qwen2.5-7b"
        elseif result:match("qwen.*2%.5.*1%.5[bB]") then
          return "qwen2.5-1.5b"
        elseif result:match("qwen") then
          return "qwen2.5-coder"
        elseif result:match("llama.*3%.1.*8[bB]") then
          return "llama-3.1-8b"
        elseif result:match("llama") then
          return "llama"
        elseif result:match("[Mm]istral.*7[bB]") then
          return "mistral-7b-instruct"
        elseif result:match("mistral") then
          return "mistral-7b-instruct"
        end
      end
      
      -- Final fallback
      return "unknown-model"
    end

    -- Get current model for conditional config
    local current_model = get_model_name()
    local model_type = "default"
    
    -- Detect model type for specific adjustments
    if current_model:match("deepseek") then
      model_type = "deepseek"
    elseif current_model:match("mistral") then
      model_type = "mistral"
    elseif current_model:match("qwen") then
      model_type = "qwen"
    elseif current_model:match("llama") then
      model_type = "llama"
    end
    
    -- Load prompts configuration
    local prompts = require('avante-prompts')
    
    -- Configuration options for different scenarios
    local prompt_scenario = vim.env.AVANTE_PROMPT_SCENARIO or "default" -- Can be: default, security, performance, full_review
    
    return {
            provider = "llama",
            debug = false,
            auto_suggestions = false,
            -- Dynamic system prompt based on scenario and model
            system_prompt = prompts.get_prompt(prompt_scenario, model_type),
            -- Disable Avante if server is not running
            behaviour = {
              auto_suggestions = false,
              auto_set_highlight_group = true,
              auto_set_keymaps = true,
              auto_apply_diff_after_generation = false,
              support_paste_from_clipboard = true,
              -- Make AI less aggressive - wait for explicit requests
              minimize_diff = true,
              smart_tab = false,
            },
            auto_set_keymaps = true,
            auto_set_highlight_group = true,
            support_paste_from_clipboard = true,
            llama = {
              endpoint = "http://127.0.0.1:1234/v1",
              model = get_model_name(), -- Auto-detect from llama-server
              ["local"] = true,
              options = is_deepseek and {
                num_ctx = 4096,
                temperature = 0.2, -- VERY low for DeepSeek
                -- ULTRA-AGGRESSIVE DeepSeek settings
                repeat_penalty = 1.8, -- Very high penalty
                repeat_last_n = 256,   -- Check more tokens
                top_k = 5,            -- Very focused
                top_p = 0.3,          -- Very conservative
                max_tokens = 200,     -- SHORT responses only
                -- DeepSeek-specific stop tokens
                stop = {
                  "<|im_end|>", 
                  "<|im_start|>", 
                  "<|im_start|>assistant",
                  "<|im_start|>user",
                  "<|im_start|>system",
                  "assistant:",
                  "user:", 
                  "system:",
                  "Human:",
                  "Assistant:",
                  "User:",
                  "System:",
                  "\n\n\n",
                  "```",
                  "---",
                  "###",
                },
              } or {
                num_ctx = 4096,
                temperature = 0.6,
                repeat_penalty = 1.1,
                top_k = 40,
                top_p = 0.8,
                max_tokens = 1000,
                stop = {"<|im_end|>", "<|im_start|>"},
              },
            },
            -- RAG service configuration for advanced features
            rag_service = {
              enabled = false,
              host_mount = os.getenv("HOME"),
              runner = "docker",
              llm = {
                provider = "llama",
                endpoint = "http://127.0.0.1:1234/v1",
                model = get_model_name(), -- Auto-detect from llama-server
                ["local"] = true,
                options = {
                  num_ctx = 32768,
                  temperature = 0.6, -- DeepSeek recommended 0.5-0.7 to avoid loops
                },
              },
              -- IMPORTANT: Embed configuration for RAG (keep this!)
              embed = {
                provider = "llama",
                endpoint = "http://127.0.0.1:1234/v1",
                model = get_model_name(),
                extra = nil,
              },
              docker_extra_args = "",
            },
            -- UI Windows configuration
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
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons,
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
