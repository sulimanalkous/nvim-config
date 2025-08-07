return {
  {
    "tzachar/cmp-ai",
    enabled = false, -- Temporarily disabled to test neoai conflict
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      local cmp_ai = require('cmp_ai.config')
      
      cmp_ai:setup({
        max_lines = 100,
        provider = 'OpenAI',
        provider_options = {
          model = 'qwen2.5-coder-1.5b-instruct',
          base_url = 'http://localhost:1234/v1',
          api_key = 'lm-studio', -- LM Studio doesn't need real key
        },
        notify = true,
        notify_callback = function(msg)
          vim.notify(msg)
        end,
        run_on_every_keystroke = true,
        ignored_file_types = {
          -- default is not to ignore
          -- uncomment to ignore lua files for a demonstration
          -- lua = true
        },
      })
    end,
  },
}