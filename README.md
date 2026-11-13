# dotfiles

My dev environment setup.

## Setup

```bash
# 1. Install Homebrew (https://brew.sh), and run the commands it prints to add it to your PATH
# 2. Clone and install
git clone https://github.com/shokic/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
brew bundle --file Brewfile
./setup.sh
```

Run `./setup.sh` again after any change. It only updates what's different.

On the first run, `setup.sh` also sets up GitHub: it creates an SSH key if there's none (`~/.ssh/id_ed25519`, no passphrase), logs `gh` in through the browser, adds the key to your GitHub account to push over SSH and to sign commits, and switches this repo's remote to SSH.

Fonts that can't be shared (MonoLisa) aren't in this repo: put them in `iCloud Drive/fonts/`, and `setup.sh` installs them.

## Removing things

```bash
# Homebrew: delete the line from Brewfile, then
brew bundle cleanup                 # preview what's no longer in the Brewfile
brew bundle cleanup --force --zap   # uninstall it, with its settings and caches

# Tools from tools.sh (then delete the name from TOOLS)
./tools.sh uninstall <name>
```

## Files

- `fish/`, `ghostty/`, `zed/`, `rex/`: app configs, linked into `~/.config`
- `git/.gitconfig`: git settings (name, email, pull/rebase/merge behavior, the `git gone` alias), linked to `~/.gitconfig`
- `raycast/`: Raycast script commands (Keep Awake, Keep Running). Add the folder once in Raycast: Settings → Extensions → + → Add Script Directory
- `Brewfile`: apps and tools from Homebrew
- `macos.sh`: macOS settings (trackpad, keyboard, Dock, Finder…)
- `tools.sh`: tools installed with curl
- `setup.sh`: links the configs and runs the two scripts above
