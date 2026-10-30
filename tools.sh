#!/bin/bash
# Tools that come with their own installer instead of Homebrew.
#
#   ./tools.sh                    install the ones that are missing (run by setup.sh)
#   ./tools.sh uninstall <tool>   remove one; its settings and data are kept
#
# Safe to re-run: a tool is only installed when it's missing, and each one keeps itself up to date.
# Paths are checked rather than commands: ~/.local/bin isn't in PATH yet on a fresh Mac.

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

TOOLS="claude viteplus herdr"

# Delete each path given, saying so
remove() {
  for p in "$@"; do
    # -L catches symlinks too, including broken ones that -e would miss
    if [ -e "$p" ] || [ -L "$p" ]; then
      rm -rf "$p"
      echo "removed $p"
    fi
  done
}

# Mention the settings and data an uninstall leaves behind
keep() {
  for p in "$@"; do
    if [ -e "$p" ]; then echo "kept $p (settings and data: delete it yourself if you don't need it)"; fi
  done
}

## Claude Code

claude_installed() { [ -e ~/.local/bin/claude ]; }
claude_install() { curl -fsSL https://claude.ai/install.sh | bash; }
claude_uninstall() {
  remove ~/.local/bin/claude ~/.local/share/claude ~/.local/state/claude ~/.cache/claude
  keep ~/.claude ~/.claude.json
}

## Vite+

viteplus_installed() { [ -e ~/.local/share/vite-plus ]; }
viteplus_install() { curl -fsSL https://vite.plus | bash; }
viteplus_uninstall() {
  ~/.local/share/vite-plus/bin/vp implode --yes
  # Added to fish by the installer: it would fail to source the deleted env file
  remove ~/.config/fish/conf.d/vite-plus.fish
}

## Herdr app (the herdr CLI comes from the Brewfile)

# The installer puts the app in ~/Applications, and always links herdr-app
herdr_installed() { [ -e ~/.local/bin/herdr-app ]; }
herdr_install() { curl -fsSL https://releases.herdr.dev/app/install.sh | sh; }
herdr_uninstall() {
  if pgrep -xq Herdr; then
    echo "quit Herdr first"
    exit 1
  fi
  # Stops the background server, ending the terminals it runs
  if [ -x ~/.local/bin/herdr-core ]; then ~/.local/bin/herdr-core server stop || true; fi
  remove ~/Applications/Herdr.app /Applications/Herdr.app \
    ~/.local/bin/herdr-app ~/.local/bin/herdr-core ~/.local/bin/hc
  keep ~/.config/herdr-app ~/.local/state/herdr-core ~/Library/Preferences/dev.herdr.app.plist
}

## Run

if [ "${1:-}" = uninstall ]; then
  tool="${2:-}"
  case " $TOOLS " in
    *" $tool "*) ;;
    *) echo "usage: ./tools.sh uninstall <$(echo $TOOLS | tr ' ' '|')>"; exit 1 ;;
  esac
  if ! "${tool}_installed"; then
    echo "$tool isn't installed"
    exit 0
  fi
  # Read from the terminal, so a pipe can't answer for you
  if ! (exec < /dev/tty) 2>/dev/null; then
    echo "needs a terminal to ask for confirmation"
    exit 1
  fi
  read -r -p "Uninstall $tool? [y/N] " answer < /dev/tty || answer=""
  case "$answer" in
    y|Y) ;;
    *) echo "Stopped."; exit 1 ;;
  esac
  "${tool}_uninstall"
  echo
  echo "$tool uninstalled: remove it from TOOLS in tools.sh, or setup.sh will install it again"
  exit 0
fi

for tool in $TOOLS; do
  if ! "${tool}_installed"; then
    echo
    echo "installing $tool"
    "${tool}_install"
  fi
done
