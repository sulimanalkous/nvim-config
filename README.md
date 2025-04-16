# 🌀 My Neovim IDE Config (LazyVim-Based)

This is my personal Neovim configuration powered by [LazyVim](https://github.com/LazyVim/LazyVim).  
It turns Neovim into a modern, full-featured IDE — with LSP, autocompletion, formatter, snippets, and more.

## 📦 Features

- 🚀 Lazy.nvim plugin manager (fast & lazy-loaded)
- 🧠 LSP support (Rust, Python, TypeScript, Vue, etc.)
- 💡 Auto-completion with `nvim-cmp`
- 🔧 Format-on-save with `conform.nvim`
- 🎨 Syntax highlighting via `nvim-treesitter`
- 🗂️ File explorer (`nvim-tree` or `neo-tree`)
- 🔍 Fuzzy finder (`telescope.nvim`)
- 🧩 Git integration via `gitsigns.nvim`
- ✨ Prettier for web formatting
- 🦀 Rust + 🐍 Python + Vue out of the box

## 🚀 Setup

### 1. Clone this config


```bash
git clone https://github.com/<your-username>/nvim-config.git ~/.config/nvim

```

### 2. (Optional) Install LSP servers manually


```bash

# Rust
rustup component add rust-analyzer

# Python
npm install -g pyright

# TypeScript/Vue
npm install -g @vue/language-server typescript
```
