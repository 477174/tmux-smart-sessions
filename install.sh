#!/usr/bin/env bash
set -e

# ══════════════════════════════════════════════════════════════
#  tmux-smart-sessions — Installer
#  Smart tmux session management with ephemeral shells,
#  auto-cleanup, and a protected session picker.
# ══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { echo -e "\033[1;34m[info]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[ok]\033[0m    $*"; }
warn()  { echo -e "\033[1;33m[warn]\033[0m  $*"; }
error() { echo -e "\033[1;31m[error]\033[0m $*"; exit 1; }

# ── Check dependencies ────────────────────────────────────────
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    return 1
  fi
  return 0
}

info "Checking dependencies..."

missing=()
check_dep tmux    || missing+=(tmux)
check_dep fzf     || missing+=(fzf)

if [ ${#missing[@]} -gt 0 ]; then
  warn "Missing required dependencies: ${missing[*]}"

  if command -v apt &>/dev/null; then
    info "Installing via apt..."
    sudo apt update -qq && sudo apt install -y "${missing[@]}"
  elif command -v brew &>/dev/null; then
    info "Installing via brew..."
    brew install "${missing[@]}"
  elif command -v pacman &>/dev/null; then
    info "Installing via pacman..."
    sudo pacman -S --noconfirm "${missing[@]}"
  else
    error "Cannot auto-install. Please install manually: ${missing[*]}"
  fi
fi

# sesh (optional but recommended)
if ! check_dep sesh; then
  info "Installing sesh..."
  SESH_VERSION=$(curl -sL https://api.github.com/repos/joshmedeski/sesh/releases/latest | grep -oP '"tag_name": "\K[^"]+')

  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  SESH_ARCH="x86_64" ;;
    aarch64) SESH_ARCH="arm64" ;;
    arm64)   SESH_ARCH="arm64" ;;
    *)       error "Unsupported architecture: $ARCH" ;;
  esac

  OS=$(uname -s)
  case "$OS" in
    Linux)  SESH_OS="Linux" ;;
    Darwin) SESH_OS="Darwin" ;;
    *)      error "Unsupported OS: $OS" ;;
  esac

  SESH_URL="https://github.com/joshmedeski/sesh/releases/download/${SESH_VERSION}/sesh_${SESH_OS}_${SESH_ARCH}.tar.gz"
  TMP_DIR=$(mktemp -d)
  curl -sL "$SESH_URL" -o "$TMP_DIR/sesh.tar.gz"
  tar xzf "$TMP_DIR/sesh.tar.gz" -C "$TMP_DIR"
  sudo mv "$TMP_DIR/sesh" /usr/local/bin/sesh
  sudo chmod +x /usr/local/bin/sesh
  rm -rf "$TMP_DIR"
  ok "sesh $(sesh --version 2>&1 | awk '{print $NF}') installed"
fi

# zoxide (optional — sesh uses it if available)
if ! check_dep zoxide; then
  info "Installing zoxide (optional, improves sesh)..."
  if command -v apt &>/dev/null; then
    sudo apt install -y zoxide 2>/dev/null || warn "Could not install zoxide. Skipping."
  elif command -v brew &>/dev/null; then
    brew install zoxide
  else
    warn "Could not install zoxide. Skipping (sesh will work without it)."
  fi
fi

# ── Install sesh-picker ──────────────────────────────────────
info "Installing sesh-picker..."
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/bin/sesh-picker" "$HOME/.local/bin/sesh-picker"
chmod +x "$HOME/.local/bin/sesh-picker"

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  warn "\$HOME/.local/bin is not in your PATH. Add it to your shell config:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

ok "sesh-picker installed to ~/.local/bin/"

# ── Install tmux.conf ────────────────────────────────────────
info "Setting up tmux.conf..."

if [ -f "$HOME/.tmux.conf" ]; then
  if grep -q "sesh-picker" "$HOME/.tmux.conf"; then
    ok "tmux.conf already configured. Skipping."
  else
    warn "Existing ~/.tmux.conf found. Backing up to ~/.tmux.conf.bak"
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
    cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
    ok "tmux.conf installed (backup at ~/.tmux.conf.bak)"
  fi
else
  cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
  ok "tmux.conf installed"
fi

# ── Shell init snippet ───────────────────────────────────────
info "Checking shell init..."

SHELL_RC=""
case "$(basename "$SHELL")" in
  zsh)  SHELL_RC="$HOME/.zshrc" ;;
  bash) SHELL_RC="$HOME/.bashrc" ;;
  *)    SHELL_RC="$HOME/.profile" ;;
esac

if [ -f "$SHELL_RC" ] && grep -q "_ephemeral_" "$SHELL_RC"; then
  ok "Shell init already configured in $SHELL_RC. Skipping."
else
  echo ""
  echo "────────────────────────────────────────────────────────"
  echo "  Add this to the TOP of $SHELL_RC:"
  echo "────────────────────────────────────────────────────────"
  echo ""
  cat "$SCRIPT_DIR/shell-init.sh"
  echo ""
  echo "────────────────────────────────────────────────────────"

  read -rp "  Add it automatically? [Y/n] " answer
  if [[ "$answer" =~ ^[Nn] ]]; then
    warn "Skipped. Add it manually later."
  else
    # Prepend to shell rc
    TMP_RC=$(mktemp)
    cat "$SCRIPT_DIR/shell-init.sh" "$SHELL_RC" > "$TMP_RC"
    mv "$TMP_RC" "$SHELL_RC"
    ok "Added to $SHELL_RC"
  fi
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✓ tmux-smart-sessions installed!"
echo ""
echo "  Usage:"
echo "    1. Open a new terminal (tmux starts automatically)"
echo "    2. Press Ctrl+A f to open the session picker"
echo "    3. Type a name + Enter to create a session"
echo "    4. Ctrl+D to kill a session (current is protected)"
echo ""
echo "  Reload tmux config:  Ctrl+A r"
echo "══════════════════════════════════════════════════════════"
