#!/usr/bin/env bash
# setup.sh — Run this first on a fresh Mac
# curl -fsSL https://raw.githubusercontent.com/OliverCulleyDeLange/macbook_setup/main/setup.sh | bash
set -euo pipefail

REPO="OliverCulleyDeLange/macbook_setup"
CLONE_DIR="$HOME/macbook_setup"

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
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -f /usr/local/bin/brew ]]    && eval "$(/usr/local/bin/brew shellenv)"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -f /usr/local/bin/brew ]]    && eval "$(/usr/local/bin/brew shellenv)"
fi
echo "  OK: $(brew --version | head -1)"

# ── 3. GitHub CLI ──────────────────────────────────────────────────────────────
step "GitHub CLI"
brew install gh 2>/dev/null || true
echo "  OK: $(gh --version | head -1)"

# ── 4. GitHub auth ─────────────────────────────────────────────────────────────
step "GitHub auth"
if ! gh auth status &>/dev/null; then
  gh auth login --web --git-protocol ssh
else
  echo "  Already authenticated"
fi

# ── 5. SSH key ─────────────────────────────────────────────────────────────────
step "SSH key"
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  read -rp "  Enter your email for the SSH key: " email
  ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
  gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(scutil --get ComputerName)"
  echo "  SSH key created and added to GitHub"
else
  echo "  Key already exists"
fi

# ── 6. Clone macbook_setup ─────────────────────────────────────────────────────
step "Clone macbook_setup"
if [[ ! -d "$CLONE_DIR" ]]; then
  gh repo clone "$REPO" "$CLONE_DIR"
else
  echo "  Already cloned — pulling latest"
  git -C "$CLONE_DIR" pull
fi

# ── 7. Run bootstrap ───────────────────────────────────────────────────────────
step "Running bootstrap.sh"
bash "$CLONE_DIR/bootstrap.sh"
