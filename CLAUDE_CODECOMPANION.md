# CodeCompanion Configuration Guide

## Current Working Setup

### Configuration Location
- Main config: `/home/suliman/.config/nvim/lua/plugins/codecompanion.lua`
- Fidget spinner: `/home/suliman/.config/nvim/lua/plugins/codecompanion/fidget-spinner.lua`

### Current Model Configuration
```lua
-- Working adapter config for LM Studio on localhost:1234
adapters = {
  lm_studio = function()
    return require("codecompanion.adapters").extend("openai_compatible", {
      env = {
        url = "http://localhost:1234",
      },
      schema = {
        model = {
          default = "qwen2.5-coder-1.5b-instruct", -- Fast model
          -- Alternative: "deepseek-coder-6.7b-instruct" -- Slower but smarter
        },
      },
    })
  end,
},
```

### Key Bindings (All Working)
- `<C-a>` - AI Actions Menu
- `<leader>cc` - Open AI Chat (fast chat)
- `<leader>ci` - Inline Assistant
- `<leader>cs` - AI Command Mode
- `<leader>cf` - AI Fix Code
- `<leader>co` - AI Optimize Code
- `<leader>ce` - AI Explain Code
- `<leader>cr` - AI Refactor Selection
- `<leader>cd` - AI Document Code
- `<leader>ct` - AI Generate Tests
- `<leader>cb` - Add Debug Logs (visual mode)
- `<leader>cm` - Add Comments (visual mode)
- `<leader>cp` - Code Review
- `<leader>aa` - Accept AI Changes
- `<leader>ar` - Reject AI Changes
- `:cc` - Expands to `:CodeCompanion`

### Dependencies
```lua
dependencies = {
  "nvim-lua/plenary.nvim",
  "nvim-treesitter/nvim-treesitter",
  "j-hui/fidget.nvim", -- for status feedback
  "MeanderingProgrammer/render-markdown.nvim", -- markdown rendering
},
```

### Known Issues & Solutions

#### "No messages to submit" Error
- **Cause**: Chat buffer not detecting typed messages
- **Solution**: Use `<C-s>` instead of `<Enter>` to submit, or `:CodeCompanionChat Submit`

#### "Cannot modify files" Response
- **Cause**: Small models (1.5B) are trained to be cautious
- **Solutions**:
  1. Use larger model: `deepseek-coder-6.7b-instruct` (slower but more agent-like)
  2. Use Continue (VS Code) for file editing instead
  3. Use inline mode: `<leader>ci` + `<leader>aa` to accept changes

#### API Key Errors
- **Cause**: CodeCompanion trying to send API key to local server
- **Solution**: Use simple `openai_compatible` adapter without api_key field

### Speed vs Intelligence Trade-off
- **Fast Model**: `qwen2.5-coder-1.5b-instruct` - Quick responses, cautious about file edits
- **Smart Model**: `deepseek-coder-6.7b-instruct` - Slower but more willing to edit files

### Alternative: Continue (VS Code)
- Config: `~/.continue/config.yaml`
- Better for file editing with small models
- Uses same local AI server on port 1234
- Complementary to CodeCompanion

## Switching to llama.cpp

### Why Switch?
- **Native GPU support** for AMD RX 6600 (ROCm)
- **Potentially faster** than LM Studio
- **More control** over model parameters
- **Better memory management**

### What to Tell Claude
"I want to switch from LM Studio (port 1234) to llama.cpp server. Help me:
1. Set up llama.cpp with ROCm support for AMD RX 6600
2. Configure it as a server (like LM Studio)
3. Update CodeCompanion to use the new llama.cpp server
4. Test that it works with both fast (1.5B) and smart (6.7B) models"

### Expected Benefits
- 🚀 **GPU acceleration** instead of CPU-only
- 🚀 **Better performance** on larger models
- 🚀 **More efficient memory usage**
- 📊 **Model switching** without restarting server

### Hardware Context
- **GPU**: AMD RX 6600 (8GB VRAM, RDNA2)
- **Supported models**: Up to 7B parameters comfortably
- **ROCm compatibility**: Should work with proper setup

## Notes
- CodeCompanion works great for **quick questions and chat**
- For serious **file editing**, consider Continue (VS Code) + this same AI backend
- The **two-tool approach** is actually optimal for this hardware setup

## Troubleshooting Commands
```bash
# Check CodeCompanion logs
:messages
:CodeCompanionDebug

# Test AI server directly
curl -s -X POST http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder-1.5b-instruct","messages":[{"role":"user","content":"hello"}]}'

# Restart CodeCompanion
:Lazy reload codecompanion.nvim
```