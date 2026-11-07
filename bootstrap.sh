#!/usr/bin/env sh
# One-time setup for this nvim config: installs the LSP servers and
# formatters it looks for, using your system / language package managers
# (brew, apt, pkg, npm, gem, rustup). No GitHub-release download scripts,
# no mason — this is what makes the config work on Linux, macOS AND FreeBSD.
#
# Safe to re-run: each step skips anything already installed.
# Run:  ./bootstrap.sh
#
# After it finishes, just start nvim — plugins and treesitter parsers
# install themselves on first run.

set -u

case "$(uname -s)" in
  Darwin)  OS="macos" ;;
  Linux)   OS="linux" ;;
  FreeBSD) OS="freebsd" ;;
  *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac
echo "==> Detected OS: $OS"

have() { command -v "$1" >/dev/null 2>&1; }
say() { printf '\n==> %s\n' "$*"; }

# --- C compiler: treesitter needs one to build its parser binaries --------
if ! have cc && ! have clang && ! have gcc; then
  say "No C compiler found — treesitter needs one to build parsers."
  case "$OS" in
    linux)
      sudo apt-get update && sudo apt-get install -y build-essential ;;
    macos)
      echo "Run:  xcode-select --install   (then re-run this script)" ;;
    freebsd)
      echo "FreeBSD ships clang in base — if this message shows, install it:" 
      echo "  sudo pkg install -y llvm" ;;
  esac
fi

# --- Node tooling (JS/TS): bun preferred, npm as fallback ------------------
# prettier            -> formatting (conform.nvim)
# pyright             -> Python LSP
# tailwindcss-language-server -> Tailwind CSS LSP
# @volar/vue-language-server  -> Vue LSP (binary: vue-language-server)
# tree-sitter-cli     -> REQUIRED by nvim-treesitter main; without it :TSInstall
#                        and every parser update fails
NODE_PKGS="prettier pyright tailwindcss-language-server @volar/vue-language-server tree-sitter-cli"
if ! have tree-sitter || ! have prettier || ! have pyright || ! have tailwindcss-language-server || ! have vue-language-server; then
  if have bun; then
    say "Installing JS/TS tooling via bun..."
    bun install -g $NODE_PKGS
  elif have npm; then
    say "Installing JS/TS tooling via npm..."
    npm install -g $NODE_PKGS
  else
    echo "!! neither bun nor npm found — install one (https://bun.sh) first."
  fi
fi

# --- OS package manager installs ------------------------------------------
# lua-language-server, solargraph (Ruby), rust-analyzer (Rust)
if ! have lua-language-server; then
  say "Installing lua-language-server..."
  case "$OS" in
    macos)   brew install lua-language-server ;;
    linux)   sudo apt-get install -y lua-language-server || echo "!! not in your distro's repos — install it manually" ;;
    freebsd) sudo pkg install -y lua-language-server ;;
  esac
fi

if ! have solargraph; then
  say "Installing solargraph (Ruby) via gem..."
  gem install solargraph
fi

if have rustup && ! have rust-analyzer; then
  say "Installing rust-analyzer via rustup..."
  rustup component add rust-analyzer
elif ! have rust-analyzer; then
  echo "!! rustup not found — install Rust (https://rustup.rs) to get rust-analyzer."
fi

# --- Optional: Flutter/Dart -------------------------------------------------
# Big install, so it's opt-in. flutter-tools.nvim is already configured to
# enable itself automatically if it finds `flutter` on PATH.
if [ "${1:-}" = "--all" ] && ! have flutter; then
  say "Installing Flutter SDK..."
  case "$OS" in
    macos)   brew install --cask flutter ;;
    linux)   echo "Install Flutter from https://docs.flutter.dev/get-started/install/linux" ;;
    freebsd) echo "Flutter is not packaged for FreeBSD — run it on another machine or skip" ;;
  esac
fi

say "Done. Start nvim — plugins + treesitter parsers install themselves on first run."
echo "LSP servers are picked up automatically; install any extra one later and it just works."
