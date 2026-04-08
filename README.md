# macbook_setup

New Mac setup — installs all apps, CLI tools, and dotfiles automatically.

## Fresh Mac setup

Run these commands in Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/OliverCulleyDeLange/macbook_setup/main/setup.sh -o ~/setup.sh
bash ~/setup.sh
```

This will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install GitHub CLI and authenticate (browser)
4. Generate an SSH key and add it to GitHub
5. Clone this repo
6. Run `bootstrap.sh` — installs all packages, apps, and dotfiles

## What's included

| Tool | How |
|------|-----|
| Homebrew packages & apps | `Brewfile` via `brew bundle` |
| Rust + cargo tools | `rustup` + `Brewfile` cargo section |
| Node / npm | `nvm` (v24) |
| Android SDK | `sdkmanager` (platforms, NDK, emulator) |
| Maestro | curl installer |
| Dotfiles | symlinked from `dotfiles/` |

## Manual steps after setup

1. Sign in to 1Password, Tailscale, Setapp
2. Install apps via Setapp
3. Sign in to Android Studio and verify SDK

## Updating dotfiles

Dotfiles in `~/` are symlinked to `dotfiles/` in this repo, so edits are live. To save changes:

```bash
cd ~/macbook_setup
git add dotfiles/
git commit -m "update dotfiles"
git push
```
