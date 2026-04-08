#!/usr/bin/env bash
# bootstrap.sh — New Mac setup script
# Run once on a fresh machine. Safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ANDROID_SDK="$HOME/Library/Android/sdk"
NODE_VERSION="24"

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

step()  { echo; echo -e "${BOLD}==> $*${RESET}"; }
ok()    { echo -e "  ${GREEN}✓ $*${RESET}"; }
warn()  { echo -e "  ${YELLOW}⚠ $*${RESET}"; }
error() { echo -e "  ${RED}✗ $*${RESET}"; }

# ── 1. Xcode Command Line Tools ────────────────────────────────────────────────
step "Xcode CLT"
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  warn "Install the CLT in the dialog, then re-run this script."
  exit 0
fi
ok "Xcode CLT ready"

# ── 2. Homebrew ────────────────────────────────────────────────────────────────
step "Homebrew"
# Add to PATH first so re-runs don't think brew is missing
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "$(brew --version | head -1)"

# ── 3. Dotfiles (early — other steps depend on shell config being in place) ────
step "Dotfiles"
DOTFILES_DIR="$REPO_DIR/dotfiles"
symlink() {
  local src="$DOTFILES_DIR/$1" dst="$HOME/$1"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "$dst.bak"
    warn "Backed up existing $1 → $1.bak"
  fi
  ln -sf "$src" "$dst"
  ok "Linked $1"
}

symlink ".zshrc"
symlink ".zshenv"
symlink ".gitconfig"
symlink ".gitignore_global"

# ── 4. Rust (before brew bundle, which installs cargo tools) ───────────────────
step "Rust / rustup"
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
ok "$(rustc --version)"

# ── 5. Homebrew Bundle ─────────────────────────────────────────────────────────
step "brew bundle (this takes a while)"
BREWFILE_PATH="$REPO_DIR/Brewfile"
if [[ ! -f "$BREWFILE_PATH" ]]; then
  error "Brewfile not found at $BREWFILE_PATH — skipping"
else
  brew bundle --file="$BREWFILE_PATH" --no-upgrade
  ok "brew bundle complete"
fi

# libheif postinstall sometimes fails during brew bundle — run it explicitly
brew postinstall libheif 2>/dev/null || true

# ── 6. nvm + Node ──────────────────────────────────────────────────────────────
step "nvm + Node $NODE_VERSION"
if [[ ! -d "$HOME/.nvm" ]]; then
  # PROFILE=/dev/null prevents nvm modifying shell profiles (managed via dotfiles)
  PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
ok "Node $(node --version)"

# ── 7. Android SDK ─────────────────────────────────────────────────────────────
step "Android SDK"
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
# android-commandlinetools cask installs sdkmanager into ~/Library/Android/sdk
SDKMANAGER=$(which sdkmanager 2>/dev/null || echo "")

if [[ -z "$SDKMANAGER" ]]; then
  warn "sdkmanager not found — skipping SDK install"
  warn "Re-run this script after brew bundle completes"
else
  yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

  "$SDKMANAGER" \
    "cmdline-tools;latest" \
    "platform-tools" \
    "build-tools;35.0.0" \
    "build-tools;36.0.0" \
    "platforms;android-34" \
    "platforms;android-35" \
    "platforms;android-36" \
    "emulator" \
    "ndk;27.1.12297006" \
    "system-images;android-35;google_apis_playstore;arm64-v8a"

  ok "Android SDK packages installed"
fi

# ── 8. Maestro (mobile UI testing) ────────────────────────────────────────────
step "Maestro"
if ! command -v maestro &>/dev/null; then
  curl -Ls "https://get.maestro.mobile.dev" | bash
fi
ok "Maestro $(maestro --version 2>/dev/null || echo 'installed')"

# ── 9. SSH keys ────────────────────────────────────────────────────────────────
step "SSH"
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  warn "No SSH key found."
  warn "Copy existing key:  scp old-mac:~/.ssh/id_ed25519{,.pub} ~/.ssh/ && chmod 600 ~/.ssh/id_ed25519"
  warn "Or generate one:    ssh-keygen -t ed25519 -C 'your@email.com' && gh ssh-key add ~/.ssh/id_ed25519.pub"
else
  ok "SSH key exists"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo
echo -e "${GREEN}${BOLD}✓ Bootstrap complete.${RESET}"
