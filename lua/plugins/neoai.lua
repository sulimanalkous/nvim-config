local keymap_opts = { expr = true }

return {
  {
    "gierdo/neoai.nvim",
    enabled = false, -- Disabled due to persistent response parsing errors
    branch = "main",  -- Use main branch, not local-llama
    cmd = {
      "NeoAI",
      "NeoAIOpen",
      "NeoAIClose",
      "NeoAIToggle",
      "NeoAIContext",
      "NeoAIContextOpen",
      "NeoAIContextClose",
      "NeoAIInject",
      "NeoAIInjectCode",
      "NeoAIInjectContext",
      "NeoAIInjectContextCode",
    },
    keys = {
      {
        mode = "n",
        "<A-a>",
        ":NeoAI<CR>",
        keymap_opts,
      },
      {
        mode = "n",
        "<A-i>",
        ":NeoAIInject<Space>",
        keymap_opts,
      },
      {
        mode = "v",
        "<A-a>",
        ":NeoAIContext<CR>",
        keymap_opts,
      },
      {
        mode = "v",
        "<A-i>",
        ":NeoAIInjectContext<Space>",
        keymap_opts,
      },
    },
    config = function()
      local extract_code_snippets = function(text)
        local matches = {}
        for match in string.gmatch(text, "```%w*\n(.-)```") do
          table.insert(matches, match)
        end

        -- Next part matches any code snippets that are incomplete
        local count = select(2, string.gsub(text, "```", "```"))
        if count % 2 == 1 then
          local pattern = "```%w*\n([^`]-)$"
          local match = string.match(text, pattern)
          table.insert(matches, match)
        end
        return table.concat(matches, "\n\n")
      end

      require("neoai").setup({
        ui = {
          output_popup_text = "AI",
          input_popup_text = "Prompt",
          width = 45,
          output_popup_height = 80,
          submit = "<Enter>",
        },
        models = {
          {
            name = "openai",
            model = "llama 3",
            params = nil,
          },
        },
        register_output = {
          ["a"] = function(output)
            return output
          end,
          ["c"] = extract_code_snippets,
        },
        inject = {
          cutoff_width = 75,
        },
        prompts = {
          context_prompt = function(context)
            return "Please only follow instructions or answer to questions. Be concise. "
              .. (vim.api.nvim_buf_get_name(0) ~= "" and "This is my currently opened file: " .. vim.api.nvim_buf_get_name(0) or "")
              .. "I'd like to provide some context for future "
              .. "messages. Here is the code/text that I want to refer "
              .. "to in our upcoming conversations:\n\n"
              .. context
          end,
          default_prompt = function()
            return "Please only follow instructions or answer to questions. Be concise. "
              .. (
                vim.api.nvim_buf_get_name(0) ~= ""
                  and "This is my currently opened file: " .. vim.api.nvim_buf_get_name(0)
                or ""
              )
          end,
        },
        mappings = {
          ["select_up"] = "<C-k>",
          ["select_down"] = "<C-j>",
        },
        open_ai = {
          url = "http://localhost:1234/v1/chat/completions",
          display_name = "llama.cpp",
          api_key = {
            value = nil,
            get = function()
              return ""
            end,
          },
        },
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "m00qek/baleia.nvim",
    },
  },
  { "MunifTanjim/nui.nvim", lazy = true },
}
