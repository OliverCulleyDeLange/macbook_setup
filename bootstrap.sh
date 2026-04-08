#!/usr/bin/env bash
# bootstrap.sh — New Mac setup script
# Run once on a fresh machine. Safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ANDROID_SDK="$HOME/Library/Android/sdk"
NODE_VERSION="24"

step() { echo; echo "==> $*"; }

# ── 1. Xcode Command Line Tools ────────────────────────────────────────────────
step "Xcode CLT"
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "  Install the CLT in the dialog, then re-run this script."
  exit 0
fi
echo "  OK"

# ── 2. Homebrew ────────────────────────────────────────────────────────────────
step "Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script (Apple Silicon)
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
echo "  OK: $(brew --version | head -1)"

# ── 3. Rust (before brew bundle, which installs cargo tools) ───────────────────
step "Rust / rustup"
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
echo "  OK: $(rustc --version)"

# ── 4. Homebrew Bundle ─────────────────────────────────────────────────────────
step "brew bundle (this takes a while)"
BREWFILE_PATH="$REPO_DIR/Brewfile"
if [[ ! -f "$BREWFILE_PATH" ]]; then
  echo "  Brewfile not found at $BREWFILE_PATH — skipping"
else
  brew bundle --file="$BREWFILE_PATH" --no-upgrade
fi

# ── 5. nvm + Node ──────────────────────────────────────────────────────────────
step "nvm + Node $NODE_VERSION"
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
echo "  OK: $(node --version)"

# ── 6. Android SDK ─────────────────────────────────────────────────────────────
step "Android SDK"
SDKMANAGER="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -f "$SDKMANAGER" ]]; then
  echo "  android-commandlinetools cask not installed — run 'brew install --cask android-commandlinetools' first"
else
  # Accept licenses
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

  echo "  OK"
fi

# ── 7. Maestro (mobile UI testing) ────────────────────────────────────────────
step "Maestro"
if ! command -v maestro &>/dev/null; then
  curl -Ls "https://get.maestro.mobile.dev" | bash
fi
echo "  OK: $(maestro --version 2>/dev/null || echo 'installed')"

# ── 8. SSH keys ────────────────────────────────────────────────────────────────
step "SSH"
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "  No SSH key found."
  echo "  Either copy your existing key from your old machine:"
  echo "    scp old-mac:~/.ssh/id_ed25519{,.pub} ~/.ssh/"
  echo "    chmod 600 ~/.ssh/id_ed25519"
  echo "  Or generate a new one:"
  echo "    ssh-keygen -t ed25519 -C 'your@email.com'"
  echo "    gh auth login   (to add it to GitHub)"
else
  echo "  OK: key exists"
fi

# ── 9. Dotfiles ────────────────────────────────────────────────────────────────
step "Dotfiles"
DOTFILES_DIR="$REPO_DIR/dotfiles"
symlink() {
  local src="$DOTFILES_DIR/$1" dst="$HOME/$1"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "$dst.bak"
    echo "  Backed up existing $1 → $1.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  Linked $1"
}

symlink ".zshrc"
symlink ".zshenv"
symlink ".gitconfig"
symlink ".gitignore_global"

# ── Done ───────────────────────────────────────────────────────────────────────
echo
echo "✓ Bootstrap complete."
