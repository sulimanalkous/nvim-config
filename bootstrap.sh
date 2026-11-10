#!/usr/bin/env sh
# One-time setup for this nvim config: installs the LSP servers and
# formatters it looks for, using your system / language package managers
# (MacPorts or brew, apt, pkg, npm, gem, rustup) — no mason. Tools no package
# manager carries (zls, C3, c3lsp) come from their official releases, pinned
# below, into ~/.local. This is what makes the config work on Linux, macOS
# AND FreeBSD.
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
    macos)   if have port; then sudo port install lua-language-server; else brew install lua-language-server; fi ;;
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

# --- Zig + C3 ---------------------------------------------------------------
# zig   -> package manager (MacPorts / brew); on Linux install it yourself
# zls   -> official release; its version must match zig's (0.16 <-> 0.16)
# c3c   -> official release (includes c3fmt and the stdlib), not brew: brew
#          ships no c3fmt and MacPorts has no c3 at all
# c3lsp -> built from source with Go at the commit known to work; the last
#          tagged release (0.4.0) is too old for C3 0.8
# Everything lands in ~/.local/opt and is linked into ~/.local/bin, which
# nvim adds to its PATH on its own (init.lua).
ZLS_VERSION="0.16.0"
C3_VERSION="v0.8.5_1"
C3LSP_COMMIT="725b25e1018949b3c205045bb4c3b7f850227ef2"

BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
mkdir -p "$BIN" "$OPT"
case "$(uname -m)" in
  arm64|aarch64) ARCH="aarch64" ;;
  x86_64|amd64)  ARCH="x86_64" ;;
  *)             ARCH="" ;;
esac

if ! have zig; then
  say "Installing zig..."
  case "$OS" in
    macos)   if have port; then sudo port install zig; else brew install zig; fi ;;
    linux)   echo "!! install zig from https://ziglang.org/download/ (then re-run for zls)" ;;
    freebsd) sudo pkg install -y zig ;;
  esac
fi

if ! have zls && [ -n "$ARCH" ] && [ "$OS" != "freebsd" ]; then
  say "Installing zls $ZLS_VERSION..."
  case "$OS" in macos) zos="macos" ;; *) zos="linux" ;; esac
  dir="$OPT/zls-$ZLS_VERSION"
  mkdir -p "$dir" &&
    curl -fsSL "https://github.com/zigtools/zls/releases/download/$ZLS_VERSION/zls-$ARCH-$zos.tar.xz" |
    tar -xJ -C "$dir" &&
    ln -sf "$dir/zls" "$BIN/zls" ||
    echo "!! zls download failed"
fi

if ! have c3c && [ "$OS" != "freebsd" ]; then
  say "Installing C3 $C3_VERSION (c3c, c3fmt, stdlib)..."
  dir="$OPT/c3-$C3_VERSION"
  mkdir -p "$dir"
  case "$OS" in
    macos)
      tmp="$(mktemp -d)"
      curl -fsSL -o "$tmp/c3.zip" "https://github.com/c3lang/c3c/releases/download/$C3_VERSION/c3-macos.zip" &&
        unzip -q -o "$tmp/c3.zip" -d "$dir"
      rm -rf "$tmp" ;;
    linux)
      curl -fsSL "https://github.com/c3lang/c3c/releases/download/$C3_VERSION/c3-linux.tar.gz" |
        tar -xz -C "$dir" ;;
  esac
  if [ -x "$dir/c3/c3c" ]; then
    ln -sf "$dir/c3/c3c" "$BIN/c3c"
    ln -sf "$dir/c3/c3fmt" "$BIN/c3fmt"
  else
    echo "!! C3 download failed"
  fi
fi

if ! have c3lsp && [ ! -x "$BIN/c3lsp" ]; then
  if ! have go; then
    say "Installing Go (needed once, to build c3lsp)..."
    case "$OS" in
      macos)   if have port; then sudo port install go; else brew install go; fi ;;
      linux)   sudo apt-get install -y golang-go ;;
      freebsd) sudo pkg install -y go ;;
    esac
  fi
  if have go; then
    say "Building c3lsp ($(printf %.7s "$C3LSP_COMMIT"))..."
    src="$(mktemp -d)"
    git -C "$src" init -q &&
      git -C "$src" fetch -q --depth 1 https://github.com/pherrymason/c3-lsp.git "$C3LSP_COMMIT" &&
      git -C "$src" checkout -q FETCH_HEAD &&
      go build -C "$src/server/cmd/lsp" -o "$BIN/c3lsp" ||
      echo "!! c3lsp build failed"
    rm -rf "$src"
  else
    echo "!! Go not found — install it and re-run to build c3lsp."
  fi
fi

# --- c3doc / zdoc ------------------------------------------------------------
# Search the installed C3 / Zig manuals and std source (bin/ldoc.py, one
# script, the language comes from the name it runs as). nvim's K uses c3doc
# to explain C3 keywords, types and operators. Needs python3 (on macOS it
# comes with the Xcode command line tools).
for tool in c3doc zdoc; do
  if ! have "$tool" && [ ! -e "$BIN/$tool" ]; then
    say "Linking $tool..."
    ln -s "$(cd "$(dirname "$0")" && pwd)/bin/ldoc.py" "$BIN/$tool"
  fi
done

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
