# dotfiles

My dev environment setup.

## Setup

```bash
# 1. Install Homebrew: https://brew.sh
# 2. Clone and install
git clone https://github.com/shokic/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
brew bundle --file Brewfile
./setup.sh
```

Run `./setup.sh` again after any change. It only updates what's different.

## Removing things

```bash
# Homebrew: delete the line from Brewfile, then
brew bundle cleanup                 # preview what's no longer in the Brewfile
brew bundle cleanup --force --zap   # uninstall it, with its settings and caches

# Tools from tools.sh (then delete the name from TOOLS)
./tools.sh uninstall <name>
```

## Files

- `fish/`, `ghostty/`, `zed.settings.jsonc`: app configs, linked into `~/.config`
- `Brewfile`: apps and tools from Homebrew
- `macos.sh`: macOS settings (trackpad, keyboard, Dock, Finder…)
- `tools.sh`: tools installed with curl
- `setup.sh`: links the configs and runs the two scripts above
