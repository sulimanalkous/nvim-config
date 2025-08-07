# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration powered by Lazy.nvim plugin manager, turning Neovim into a modern IDE. The configuration is structured with modular plugin files and includes LSP support for multiple languages.

## Key Architecture

### Configuration Structure
- `init.lua` - Main entry point that loads vim options and lazy.nvim
- `lua/vim-options.lua` - Core Neovim settings (tabs, line numbers, leader key `,`)
- `lua/plugins.lua` - Basic plugin list (plenary, fugitive, auto-pairs)
- `lua/plugins/` - Individual plugin configurations organized by functionality
- `lsp.lua` - Legacy LSP configuration (partially superseded by lua/plugins/lsp-config.lua)

### Plugin Management
Uses Lazy.nvim for plugin management with lazy loading. Plugins are defined in separate files under `lua/plugins/`:
- Each plugin file returns a table with plugin specifications
- Configuration happens in the `config` function within each plugin spec

### LSP Configuration
Two LSP configuration files exist (migration in progress):
- `lsp.lua` - Legacy configuration with basic setups
- `lua/plugins/lsp-config.lua` - Modern configuration with detailed settings

Supported languages:
- Rust (rust-analyzer with clippy integration)
- TypeScript/JavaScript (ts_ls)
- Python (pyright)
- Tailwind CSS (tailwindcss-language-server)

### Key Plugins and Functionality

#### Core IDE Features
- **LSP**: `nvim-lspconfig` for language server support
- **Completion**: `nvim-cmp` with multiple sources (LSP, buffer, path, snippets)
- **File Explorer**: `neo-tree` (Ctrl+N to toggle)
- **Fuzzy Finder**: `telescope.nvim` (Ctrl+P for files, leader+fg for grep)
- **Syntax Highlighting**: `nvim-treesitter` with all parsers installed

#### UI and Theming
- **Theme**: Catppuccin color scheme
- **Status Line**: Lualine with Dracula theme
- **Icons**: nvim-web-devicons for file type icons

### Key Bindings
- Leader key: `,`
- File tree: `Ctrl+N`
- Find files: `Ctrl+P`
- Live grep: `<leader>fg`
- LSP actions:
  - Go to definition: `gd`
  - Show references: `gr`
  - Hover documentation: `K`
  - Rename symbol: `<leader>rn`
  - Show diagnostics: `<leader>e`

### Auto-formatting
- Global format-on-save enabled in init.lua
- Language-specific formatting configured in LSP setups
- Rust uses rust-analyzer formatting with clippy integration

## Development Workflow

### Adding New Plugins
1. Create new file in `lua/plugins/` directory
2. Return a table with plugin specification
3. Include dependencies and config function as needed
4. Lazy.nvim will automatically load the plugin

### LSP Server Installation
Required external tools (install manually):
- Rust: `rustup component add rust-analyzer`
- Python: `npm install -g pyright`
- TypeScript/Vue: `npm install -g @vue/language-server typescript`
- Tailwind: `npm install -g @tailwindcss/language-server`

### Configuration Testing
- Use `:Lazy` to manage plugins
- Use `:Mason` for LSP server management (if mason.nvim is added)
- Check LSP status with `:LspInfo`
- Restart Neovim after major configuration changes

#### AI Coding Assistant
- **Avante.nvim**: AI-powered coding assistant with local model support
  - Custom llama provider for llama-server integration
  - Configured with Qwen2.5-Coder-7B-Instruct for optimal coding performance
  - Auto-detection of running models from llama-server process
  - 32K context length for large code understanding
  - Key bindings:
    - `<leader>aa` - Ask/chat mode with AI
    - `<leader>ae` - Edit selected code with AI
    - `ct` - Accept AI suggestions (theirs)
    - `co` - Keep original code (ours)
    - `ca` - Accept all AI changes
    - `cb` - Accept both versions
    - `<leader>ar` - Refresh AI context

### AI Setup Requirements
- **llama-server**: Local model serving on port 1234
- **Recommended model**: Qwen2.5-Coder-7B-Instruct for best coding performance
- **Alternative models**: deepseek-coder, phi4, mistral-7b-instruct
- **Context length**: 32K tokens configured for large code files

### AI Workflow
1. **Start llama-server** with your preferred model on port 1234
2. **Auto-detection** will identify the running model automatically
3. **Use chat mode** (`<leader>aa`) for explanations and complex queries
4. **Use edit mode** (`<leader>ae`) for direct code modifications
5. **Review and apply** changes using `ct` (accept) or `co` (reject)

## Notes
- Avante.nvim includes custom llama provider with line number cleaning
- The provider supports both streaming and non-streaming responses
- Tool calling capabilities are available for advanced AI interactions
- Some configuration exists in both `lsp.lua` and `lua/plugins/lsp-config.lua` - the plugins version is more current
- Treesitter installs all parsers by default (`ensure_installed = "all"`)
- Format-on-save is globally enabled for all file types
- The configuration includes both core plugins and language-specific tools