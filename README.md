# nvim — clone and forget

A Neovim config built to be **copied to any machine and forgotten**.
Clone it, run `nvim`, and everything installs itself once. No mason, no
headless install scripts, no dependency churn — just an editor.

Works on **Linux, macOS and FreeBSD** the same way.

## The deal

| What | How it gets installed | When |
|---|---|---|
| Neovim itself | your OS package manager | once, per machine |
| Plugins (lazy.nvim) | git, automatically | first `nvim` run |
| Treesitter parsers | compiled from C source inside nvim | first `nvim` run |
| LSP servers | `./bootstrap.sh` (below) | once, per machine |
| Colorscheme, keymaps, everything else | this repo | nothing to do |

The only things that ever touch your system are **LSP servers** — they're
OS-specific binaries, so they come from your package manager. Everything
else is pure git or compiles itself, which is why it's identical everywhere.

## Install (per machine, ~2 minutes)

```sh
# 1. Install Neovim (>= 0.10) and Node.js (for npm) if you don't have them

# 2. Put this config in place
git clone https://github.com/sulimanalkous/nvim-config.git ~/.config/nvim

# 3. One-time LSP servers (optional but recommended)
cd ~/.config/nvim && ./bootstrap.sh

# 4. Done. First launch installs plugins + parsers, then you forget it.
nvim
```

`bootstrap.sh` is idempotent — safe to re-run, skips what's installed.

## LSP: which languages get a server

A language gets LSP only if its server is on `PATH` — missing ones are
skipped **silently** (no errors, no warnings). Install a server later and
it just starts working on the next launch.

| Language | Server binary | Install |
|---|---|---|
| Lua | `lua-language-server` | brew / apt / pkg (in `bootstrap.sh`) |
| Rust | `rust-analyzer` | `rustup component add rust-analyzer` |
| Python | `pyright` | `npm i -g pyright` |
| JavaScript/TypeScript | — | formatting only, via `prettier` |
| Vue | `vue-language-server` | `npm i -g @volar/vue-language-server` |
| Tailwind CSS | `tailwindcss-language-server` | `npm i -g tailwindcss-language-server` |
| Ruby | `solargraph` | `gem install solargraph` |
| Flutter/Dart | `flutter` SDK | opt-in: `./bootstrap.sh --all` |

## Keybindings

Leader key is **space** — press it and **which-key** pops up every binding.
Press `<space>?` any time to see all keymaps. Nothing to memorize.

The config is built for **Emacs muscle memory**, so the real Emacs chords work
too: `C-x` is the prefix, exactly like in Emacs.

| Key | Action |
|---|---|
| `C-x C-f` | find file |
| `C-x b` | buffer list (fuzzy, like `switch-to-buffer`) |
| `C-x k` | kill this buffer, window stays |
| `C-x LEFT` / `C-x RIGHT` | previous / next buffer (`C-x p` / `C-x n` too) |
| `C-x C-s` / `C-x s` | save this buffer / save all buffers |
| `C-x 2` / `C-x 3` | split below / split right |
| `C-x o` | other window |
| `C-x 0` / `C-x 1` | close window / close other windows |
| `<Esc><Esc>` in a terminal | leave terminal mode (the `<C-\><C-n>` way, typeable) |
| `<C-p>` | find files |
| `<space>fg` | live grep (search text in project) |
| `<space>fb` | open buffer list |
| `<C-n>` | toggle file explorer |
| `gd` / `gr` / `K` | go to definition / references / hover |
| `<space>e` | show diagnostics |
| `<space>rn` | rename symbol |
| `<space>ca` | code action |
| `<space>tt` | pick a theme (live preview, remembered) |
| `:Run <cmd>` | run a command, output in the error list (like `compile`) |
| `gcc` / `gc<motion>` | comment line / block |
| `<space>?` | show every keymap |

Buffers behave like Emacs buffers: `hidden` is on, so a file you visited stays
alive after you switch away, and switching never asks you to save first.

## Updating

Nothing updates itself — that's on purpose. When *you* want it:

- `:Lazy update` — update plugins (roll back with `:Lazy restore`)
- `:TSUpdate` — update treesitter parsers

If a plugin ever misbehaves: `git diff` this repo to see what changed, and
`:Lazy restore` to go back to the last working state.

## Adding a plugin

Drop one file in `lua/plugins/` — that's the whole ceremony. Example:

```lua
-- lua/plugins/hello.lua
return { "github-user/some-plugin", config = function() require("some-plugin").setup() end }
```

Restart nvim; lazy.nvim installs it.

## Troubleshooting

- **"LSP doesn't work for language X"** — its server isn't installed.
  `command -v <binary>` (see table above), install it, restart nvim.
- **Plugins broken after an update** — `:Lazy restore` rolls back.
- **Treesitter errors** — you need a C compiler (`cc`/`clang`/`gcc`).
- **This config is meant to have zero errors/warnings.** If nvim shows you
  one, it's a bug in this repo — file it.
