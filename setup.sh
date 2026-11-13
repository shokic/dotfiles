#!/bin/bash
# Sets up this Mac from the repo: symlinks the configs into ~/.config, applies the macOS
# settings (macos.sh), installs the curl tools (tools.sh), registers fonts, sets up fish,
# then runs what only this Mac's profile needs (profiles/<profile>/setup.sh).
#
#   ./setup.sh [work|personal]    the profile is asked on the first run, then remembered
# Safe to re-run: only what's out of date changes, and existing files are only replaced after asking.

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

# Find Homebrew's tools (fish...) even when Homebrew isn't in this shell's PATH yet, as on a fresh Mac
if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi

# Absolute path to this repo, wherever it's cloned
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Whether there's a terminal to ask overwrite questions on
HAS_TTY=""
if (exec < /dev/tty) 2>/dev/null; then HAS_TTY=1; fi

# Set when anything changes, to suggest reloading the shell at the end
CHANGED=""

# Profile: what differs between a work and a personal Mac (profiles/<profile>/, the Brewfile,
# tools.sh). Asked on the first run and saved for the next ones; `./setup.sh <profile>` changes it.
PROFILE_FILE=~/.config/dotfiles/profile
PROFILE="${1:-$(cat "$PROFILE_FILE" 2>/dev/null || true)}"
if [ -z "$PROFILE" ] && [ -n "$HAS_TTY" ]; then
  read -r -p "Is this a work or a personal Mac? [work/personal] " PROFILE < /dev/tty || PROFILE=""
fi
case "$PROFILE" in
  work|personal) ;;
  *) echo "usage: ./setup.sh [work|personal] (the profile is only needed on the first run)"; exit 1 ;;
esac
if [ "$(cat "$PROFILE_FILE" 2>/dev/null || true)" != "$PROFILE" ]; then
  mkdir -p "$(dirname "$PROFILE_FILE")"
  echo "$PROFILE" > "$PROFILE_FILE"
  echo "profile: $PROFILE (saved in $PROFILE_FILE)"
fi

# iCloud Drive, for the files that can't be in this public repo (fonts, work configs)
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

# Make sure the iCloud Drive file $1 is on this Mac. If iCloud only kept it online ("dataless"),
# cp fails on it instead of downloading it, so ask iCloud to download it, and wait up to a minute.
# Fails if it's still not there.
icloud_download() {
  stat -f '%Sf' "$1" | grep -q dataless || return 0
  brctl download "$1" > /dev/null 2>&1 || true
  for _ in $(seq 60); do
    stat -f '%Sf' "$1" | grep -q dataless || return 0
    sleep 1
  done
  return 1
}

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
for dir in ~/.config/fish ~/.config/fish/conf.d ~/.config/fish/functions ~/.config/ghostty ~/.config/zed ~/.config/rex; do
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

link "$DOTFILES/rex/init.lua" ~/.config/rex/init.lua

# Claude Code: my own skills, one link per skill so the skills other tools install
# into ~/.claude/skills (Rex's, the synced ones) stay in place
for skill in "$DOTFILES"/skills/*/; do
  link "${skill%/}" ~/.claude/skills/"$(basename "$skill")"
done

# git: name, email, and the rest of the settings
link "$DOTFILES/git/.gitconfig" ~/.gitconfig

# SSH key: git uses it to reach GitHub and to sign commits and tags (see git/.gitconfig).
# No passphrase, so nothing has to be unlocked.
SSH_KEY=~/.ssh/id_ed25519
GIT_EMAIL="$(git config --file "$DOTFILES/git/.gitconfig" user.email)"
if [ ! -f "$SSH_KEY" ]; then
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  ssh-keygen -q -t ed25519 -N "" -C "$GIT_EMAIL" -f "$SSH_KEY"
  echo "created SSH key $SSH_KEY"
fi

# Trust that key's signatures for the git email, so git log --show-signature can check them here
mkdir -p ~/.config/git
SIGNER="$GIT_EMAIL $(cut -d' ' -f1,2 "$SSH_KEY.pub")"
if [ "$(cat ~/.config/git/allowed_signers 2>/dev/null)" != "$SIGNER" ]; then
  echo "$SIGNER" > ~/.config/git/allowed_signers
  echo "wrote ~/.config/git/allowed_signers"
fi

# GitHub: log gh in, and add the key to the account twice: to push and pull over SSH
# ("authentication"), and to show signed commits as Verified ("signing").
# Each step only runs when needed, so re-runs don't touch GitHub beyond a check.
GH_SCOPES="admin:public_key,admin:ssh_signing_key"   # what adding both kinds of keys needs
if ! command -v gh > /dev/null; then
  echo
  echo "gh isn't installed yet: run \`brew bundle\` here, then re-run ./setup.sh to set up GitHub"
elif [ -z "$HAS_TTY" ]; then
  echo
  echo "⚠️  no terminal to log in to GitHub from: re-run ./setup.sh in a terminal"
else
  if ! gh auth status -h github.com > /dev/null 2>&1; then
    echo
    echo "logging in to GitHub (opens the browser)"
    # --skip-ssh-key: the keys are added below, with this Mac's name as their title.
    # -p ssh: git (and gh clone) reach GitHub over SSH.
    gh auth login -h github.com -w -p ssh --skip-ssh-key -s "$GH_SCOPES" < /dev/tty
  else
    # Logged in before this script asked for these scopes: ask for the missing ones
    MISSING=""
    for s in ${GH_SCOPES//,/ }; do
      gh auth status -h github.com 2>&1 | grep -q "'$s'" || MISSING=1
    done
    if [ -n "$MISSING" ]; then
      echo
      echo "gh needs more access to add SSH keys (opens the browser)"
      gh auth refresh -h github.com -s "$GH_SCOPES" < /dev/tty
    fi
  fi

  # The key without its comment, as GitHub lists it
  PUBKEY="$(cut -d' ' -f1,2 "$SSH_KEY.pub")"
  KEYS="$(gh ssh-key list 2>/dev/null || true)"
  ADDED=""
  for type in authentication signing; do
    # gh ssh-key list: one key per line, tab-separated, with the key and its type as separate fields
    if ! echo "$KEYS" | awk -F'\t' -v k="$PUBKEY" -v t="$type" '
        { has_k = 0; has_t = 0; for (i = 1; i <= NF; i++) { if ($i == k) has_k = 1; if ($i == t) has_t = 1 } }
        has_k && has_t { found = 1 } END { exit !found }'; then
      if gh ssh-key add "$SSH_KEY.pub" --type "$type" --title "$(scutil --get ComputerName)"; then
        ADDED=1
      else
        echo "⚠️  couldn't add the SSH key to GitHub as a $type key"
      fi
    fi
  done

  # Check that GitHub accepts the key (accept-new: trust GitHub's host key the first time)
  if [ -n "$ADDED" ]; then
    if ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
      echo "GitHub accepts the SSH key"
    else
      echo "⚠️  GitHub doesn't accept the SSH key yet: check with ssh -T git@github.com"
    fi
  fi

  # gh extensions. gh-stack: stacked branches and PRs (gh stack). Update with `gh extension upgrade --all`
  for ext in github/gh-stack; do
    if ! gh extension list 2>/dev/null | grep -q "$ext"; then
      gh extension install "$ext" || echo "⚠️  couldn't install the gh extension $ext"
    fi
  done

  # The README clones this repo over HTTPS (there's no SSH key yet on a fresh Mac). Switch it to SSH
  # now that the key is on GitHub, so pushes use the key too.
  ORIGIN="$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || true)"
  if [[ "$ORIGIN" == https://github.com/* ]] &&
     ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
    SSH_ORIGIN="git@github.com:${ORIGIN#https://github.com/}"
    git -C "$DOTFILES" remote set-url origin "$SSH_ORIGIN"
    echo "dotfiles remote now uses SSH: $SSH_ORIGIN"
  fi
fi

# Zed: file by file, so Zed can keep its own files (prompts, themes) next to them
link "$DOTFILES/zed/settings.json" ~/.config/zed/settings.json
link "$DOTFILES/zed/keymap.json" ~/.config/zed/keymap.json

# Found by `brew bundle` via HOMEBREW_BUNDLE_FILE (set in fish/conf.d/homebrew.fish)
link "$DOTFILES/Brewfile" ~/.config/Brewfile

# macOS preferences: trackpad, keyboard, Dock, Finder...
"$DOTFILES/macos.sh"

# Tools installed with curl or a .dmg instead of Homebrew.
# A failed download (server down, no network) only warns, so the rest of the setup still runs.
if ! "$DOTFILES/tools.sh"; then
  echo
  echo "⚠️  a tool didn't install (see above): re-run ./setup.sh later to install the rest"
fi

# Fonts that can't be shared (MonoLisa) aren't in this public repo, so they're kept in iCloud Drive, in a
# fonts/ folder. Copy the ones missing from ~/Library/Fonts.
# Problems only warn: a missing font shouldn't stop the rest of the setup.
ICLOUD_FONTS="$ICLOUD/fonts"
if [ -d "$ICLOUD_FONTS" ]; then
  while IFS= read -r -d '' f; do
    dest=~/Library/Fonts/"$(basename "$f")"
    # -s, not -e: an empty file is left over from a failed copy, so copy it again
    [ -s "$dest" ] && continue
    if ! icloud_download "$f"; then
      echo "⚠️  couldn't download font $f from iCloud Drive: download it in Finder and re-run"
      continue
    fi
    mkdir -p ~/Library/Fonts
    if cp "$f" "$dest" && [ -s "$dest" ]; then
      echo "copied font $(basename "$f") from iCloud Drive"
    else
      rm -f "$dest"
      echo "⚠️  couldn't copy font $f"
    fi
  done < <(find "$ICLOUD_FONTS" -type f \( -iname '*.otf' -o -iname '*.ttf' -o -iname '*.otc' -o -iname '*.ttc' \) -print0)
fi

# Zed's code font: without it, Zed silently falls back to another font.
# Also covers Macs without the iCloud folder, unless MonoLisa was installed by hand.
# Only non-empty files count: an empty one is left over from a failed copy.
if [ -z "$(find ~/Library/Fonts -maxdepth 1 -name 'MonoLisa*' -size +0 2>/dev/null)" ]; then
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

# Raycast "Keep Running" (raycast/keep-running.sh): allow turning sleep off and on without a password,
# as Raycast can't ask for one. Only these two exact commands, nothing else runs as root.
# Checked by existence: the file itself is only readable by root.
SUDOERS=/etc/sudoers.d/keep-running
if [ ! -f "$SUDOERS" ]; then
  if [ -z "$HAS_TTY" ]; then
    echo "skipped $SUDOERS (no terminal to ask for the sudo password)"
  else
    echo
    echo "allowing Raycast's Keep Running to change sleep settings (needs sudo)"
    tmp="$(mktemp)"
    echo "$(whoami) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1" > "$tmp"
    # visudo checks the syntax first: a broken sudoers file could lock sudo out entirely
    if sudo visudo -cqf "$tmp"; then
      sudo install -m 0440 -o root -g wheel "$tmp" "$SUDOERS"
      echo "added $SUDOERS"
    fi
    rm -f "$tmp"
  fi
fi

# What only this profile needs. Sourced, not run, so it can use link, icloud_download, HAS_TTY...
if [ -f "$DOTFILES/profiles/$PROFILE/setup.sh" ]; then
  . "$DOTFILES/profiles/$PROFILE/setup.sh"
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
