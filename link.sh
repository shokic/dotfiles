#!/bin/bash
# Symlinks the files in this repo into their places in ~ and ~/.config.
# Safe to re-run: anything already at a target path is replaced.

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

# Absolute path to this repo, wherever it's cloned
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Whether there's a terminal to ask overwrite questions on
HAS_TTY=""
if (exec < /dev/tty) 2>/dev/null; then HAS_TTY=1; fi

# Print what's currently at $1 so it can be checked before overwriting
show() {
  if [ -L "$1" ]; then
    echo "   symlink -> $(readlink "$1")"
  elif [ -d "$1" ] && [ -z "$(ls -A "$1")" ]; then
    echo "   (empty directory)"
  elif [ -d "$1" ]; then
    echo "   directory containing:"
    ls -A "$1" | sed 's/^/   | /'
  elif grep -Iq . "$1" 2>/dev/null; then
    # Text file: show the first 40 lines
    head -n 40 "$1" | sed 's/^/   | /'
    if [ "$(wc -l < "$1")" -gt 40 ]; then echo "   | ..."; fi
  else
    echo "   (empty or binary file)"
  fi
}

# Replace whatever is at $2 with a symlink to $1, asking first if something is already there
link() {
  # Already linked to the right place: nothing to do
  if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then
    return
  fi

  # -L catches symlinks too, including broken ones that -e would miss
  if [ -e "$2" ] || [ -L "$2" ]; then
    echo
    echo "⚠️  $2 already exists:"
    show "$2"
    # Can't ask without a terminal (e.g. run from another script): play safe and skip
    if [ -z "$HAS_TTY" ]; then
      echo "skipped $2 (no terminal to ask)"
      return
    fi
    # Read from the terminal, not stdin, which is used by the loop below
    read -r -p "Overwrite it? [y/N/q] " answer < /dev/tty || answer=""
    case "$answer" in
      y|Y) ;;
      q|Q) echo "Stopped."; exit 1 ;;
      *) echo "skipped $2"; return ;;
    esac
  fi

  mkdir -p "$(dirname "$2")"
  rm -rf "$2"
  ln -sn "$1" "$2"
  echo "linked $2"
}

# Remove broken symlinks left over from previous runs
for dir in ~/.config/fish ~/.config/fish/conf.d ~/.config/fish/functions ~/.config/ghostty; do
  [ -d "$dir" ] || continue
  for f in "$dir"/*; do
    if [ -L "$f" ] && [ ! -e "$f" ]; then
      echo "removing broken symlink $f"
      rm -f "$f"
    fi
  done
done

# fish: link file by file so fisher can keep installing plugins into conf.d/ and functions/
cd "$DOTFILES/fish"
# (process substitution instead of a pipe, so `q` in link() exits the whole script)
while read -r f; do
  link "$DOTFILES/fish/${f#./}" ~/.config/fish/"${f#./}"
done < <(find . -type f)

link "$DOTFILES/ghostty/config" ~/.config/ghostty/config

# Zed expects plain settings.json; the repo uses .jsonc so editors allow comments in it
link "$DOTFILES/zed.settings.jsonc" ~/.config/zed/settings.json

# Found by `brew bundle` via HOMEBREW_BUNDLE_FILE (set in fish/conf.d/homebrew.fish)
link "$DOTFILES/Brewfile" ~/.config/Brewfile

# Make fish the login shell (https://fishshell.com/docs/current/#default-shell)
FISH="$(command -v fish || true)"
if [ -z "$FISH" ]; then
  # Fresh machine: fish comes from the Brewfile, so this step has to wait
  echo
  echo "fish isn't installed yet: run \`brew bundle\` here, then re-run ./link.sh"
# Ask macOS directly: $SHELL keeps the old value until the next login
elif [ "$(dscl . -read ~/ UserShell | awk '{print $2}')" != "$FISH" ]; then
  # chsh only accepts shells listed in /etc/shells
  if ! grep -qx "$FISH" /etc/shells; then
    echo "adding $FISH to /etc/shells (needs sudo)"
    echo "$FISH" | sudo tee -a /etc/shells > /dev/null
  fi
  chsh -s "$FISH"
  echo "default shell set to $FISH (applies to new terminal windows)"
fi
