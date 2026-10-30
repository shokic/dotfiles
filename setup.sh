#!/bin/bash
# Sets up this Mac from the repo: symlinks the configs into ~/.config, applies the macOS
# settings (macos.sh), installs the curl tools (tools.sh), registers fonts, and sets up fish.
# Safe to re-run: only what's out of date changes, and existing files are only replaced after asking.

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

# Absolute path to this repo, wherever it's cloned
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Whether there's a terminal to ask overwrite questions on
HAS_TTY=""
if (exec < /dev/tty) 2>/dev/null; then HAS_TTY=1; fi

# Set when anything changes, to suggest reloading the shell at the end
CHANGED=""

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
  CHANGED=1
}

# Remove broken symlinks left over from previous runs
for dir in ~/.config/fish ~/.config/fish/conf.d ~/.config/fish/functions ~/.config/ghostty ~/.config/zed; do
  [ -d "$dir" ] || continue
  for f in "$dir"/*; do
    if [ -L "$f" ] && [ ! -e "$f" ]; then
      echo "removing broken symlink $f"
      rm -f "$f"
      CHANGED=1
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

# Zed: file by file, so Zed can keep its own files (prompts, themes) next to them
link "$DOTFILES/zed/settings.json" ~/.config/zed/settings.json
link "$DOTFILES/zed/keymap.json" ~/.config/zed/keymap.json

# Found by `brew bundle` via HOMEBREW_BUNDLE_FILE (set in fish/conf.d/homebrew.fish)
link "$DOTFILES/Brewfile" ~/.config/Brewfile

# macOS preferences: trackpad, keyboard, Dock, Finder...
"$DOTFILES/macos.sh"

# Tools installed with curl instead of Homebrew
"$DOTFILES/tools.sh"

# Fonts that can't be shared (MonoLisa) aren't in this public repo, so they're kept in iCloud Drive, in a
# fonts/ folder. Copy the ones missing from ~/Library/Fonts.
# Problems only warn: a missing font shouldn't stop the rest of the setup.
ICLOUD_FONTS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/fonts"
if [ -d "$ICLOUD_FONTS" ]; then
  while IFS= read -r -d '' f; do
    if [ ! -e ~/Library/Fonts/"$(basename "$f")" ]; then
      mkdir -p ~/Library/Fonts
      # Reading the file also downloads it, if iCloud only kept it online
      if cp "$f" ~/Library/Fonts/; then
        echo "copied font $(basename "$f") from iCloud Drive"
      else
        echo "⚠️  couldn't copy font $f"
      fi
    fi
  done < <(find "$ICLOUD_FONTS" -type f \( -iname '*.otf' -o -iname '*.ttf' -o -iname '*.otc' -o -iname '*.ttc' \) -print0)
fi

# Zed's code font: without it, Zed silently falls back to another font.
# Also covers Macs without the iCloud folder, unless MonoLisa was installed by hand.
if ! ls ~/Library/Fonts/MonoLisa* > /dev/null 2>&1; then
  echo
  echo "⚠️  MonoLisa isn't installed: add it to iCloud Drive/fonts/ and re-run, or install it by hand"
fi

# Fonts from the Brewfile land in ~/Library/Fonts, but macOS doesn't always register them,
# and apps can't use a font until it is. Register the ones that aren't, like Font Book does.
# (JavaScript for Automation, because it can call the macOS font functions directly.)
FONTS="$(osascript -l JavaScript <<'EOF'
ObjC.import("CoreText");
const dir = $("~/Library/Fonts").stringByExpandingTildeInPath;
const files = ObjC.deepUnwrap($.NSFileManager.defaultManager.contentsOfDirectoryAtPathError(dir, null)) || [];
const registered = [];
for (const name of files) {
  if (!/\.(otf|ttf|otc|ttc)$/i.test(name)) continue;
  const url = $.NSURL.fileURLWithPath(dir.stringByAppendingPathComponent(name));
  // Scope 0: not registered. 2: registered for this user, persistently.
  if ($.CTFontManagerGetScopeForURL(url) === 0 && $.CTFontManagerRegisterFontsForURL(url, 2, null)) {
    registered.push(name);
  }
}
registered.join("\n");
EOF
)"
if [ -n "$FONTS" ]; then
  echo
  echo "registered fonts (restart apps to use them):"
  echo "$FONTS" | sed 's/^/  /'
fi

# Make fish the login shell (https://fishshell.com/docs/current/#default-shell)
FISH="$(command -v fish || true)"
if [ -z "$FISH" ]; then
  # Fresh machine: fish comes from the Brewfile, so this step has to wait
  echo
  echo "fish isn't installed yet: run \`brew bundle\` here, then re-run ./setup.sh"
# Ask macOS directly: $SHELL keeps the old value until the next login
elif [ "$(dscl . -read ~/ UserShell | awk '{print $2}')" != "$FISH" ]; then
  # chsh only accepts shells listed in /etc/shells
  if ! grep -qx "$FISH" /etc/shells; then
    echo "adding $FISH to /etc/shells (needs sudo)"
    echo "$FISH" | sudo tee -a /etc/shells > /dev/null
  fi
  chsh -s "$FISH"
  CHANGED=1
  echo "default shell set to $FISH (applies to new terminal windows)"
fi

# Install or remove fish plugins so they match fish/fish_plugins.
# Only when the lists differ: `fisher update` re-downloads every plugin.
if [ -n "$FISH" ] && ! "$FISH" <<'EOF'
set -l wanted (string match -r '^[^\s]+$' < $__fish_config_dir/fish_plugins | string replace -- \~ ~ | sort)
set -l installed (printf '%s\n' $_fisher_plugins | sort)
test "$wanted" = "$installed"
EOF
then
  echo
  echo "fish plugins changed, running fisher update"
  "$FISH" -c 'fisher update'
  CHANGED=1
fi

# A script can't reload the shell that ran it, so leave that to the user.
# exec fish starts a fresh fish in place of the current shell.
if [ -n "$CHANGED" ] && [ -n "$FISH" ]; then
  echo
  echo "done: run \`exec fish\` to reload your shell"
fi
