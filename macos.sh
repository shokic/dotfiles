#!/bin/bash
# Sets macOS preferences (the ones in System Settings) with `defaults`.
# Run by setup.sh. Safe to re-run: only values that differ are written.
#
# To find the key behind a setting: save `defaults read` and `defaults -currentHost read`,
# change the setting in System Settings, read again and diff.

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

# Set by pref() so apps are only restarted when one of their preferences changed
RESTART_DOCK=""
RESTART_FINDER=""
RESTART_SYSTEMUISERVER=""
RELOAD_SETTINGS=""

# Set by pref() when it wrote something, for the few global preferences an app needs restarting for
PREF_CHANGED=""

# Write a preference unless it already has that value, e.g. `pref com.apple.dock autohide -bool true`.
# Put -currentHost first for preferences stored per machine.
pref() {
  local host=""
  if [ "$1" = "-currentHost" ]; then host="$1"; shift; fi
  local domain="$1" key="$2" type="$3" value="$4"
  PREF_CHANGED=""
  # `defaults read` prints booleans as 1/0
  local expected="$value"
  case "$value" in true) expected=1 ;; false) expected=0 ;; esac
  # $host is unquoted so it disappears when empty
  if [ "$(defaults $host read "$domain" "$key" 2>/dev/null || true)" = "$expected" ]; then
    return
  fi
  defaults $host write "$domain" "$key" "$type" "$value"
  echo "set $domain $key to $value"
  PREF_CHANGED=1
  case "$domain" in
    com.apple.dock) RESTART_DOCK=1 ;;
    com.apple.finder) RESTART_FINDER=1 ;;
    com.apple.screencapture) RESTART_SYSTEMUISERVER=1 ;;
    *) RELOAD_SETTINGS=1 ;;
  esac
}

# Trackpad preferences are stored twice: for the built-in trackpad and for a Magic Trackpad
trackpad() {
  pref com.apple.AppleMultitouchTrackpad "$@"
  pref com.apple.driver.AppleBluetoothMultitouch.trackpad "$@"
}

## Trackpad

# Tracking speed (0 to 3)
pref -g com.apple.trackpad.scaling -float 2.5

# Click pressure: 0 = light, 1 = medium, 2 = firm (normal click, then force click).
# Only stored for the built-in trackpad.
pref com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
pref com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0

# Tap to click (the -currentHost one makes it work on the login screen too)
trackpad Clicking -bool true
pref -currentHost -g com.apple.mouse.tapBehavior -int 1

# Three-finger drag (Accessibility > Pointer Control > Trackpad Options)
trackpad TrackpadThreeFingerDrag -bool true

# Three-finger swipes are taken by dragging, so swiping between
# full-screen apps and Mission Control use four fingers (0 = off, 2 = on)
trackpad TrackpadThreeFingerHorizSwipeGesture -int 0
trackpad TrackpadThreeFingerVertSwipeGesture -int 0
trackpad TrackpadFourFingerHorizSwipeGesture -int 2
trackpad TrackpadFourFingerVertSwipeGesture -int 2

## Keyboard

# Fastest key repeat, shortest delay before it starts (the sliders' limits)
pref -g KeyRepeat -int 2
pref -g InitialKeyRepeat -int 15

# Holding a key repeats it instead of showing the accent picker
pref -g ApplePressAndHoldEnabled -bool false

# No smart quotes and dashes (they break code pasted into chat apps and notes)
pref -g NSAutomaticQuoteSubstitutionEnabled -bool false
pref -g NSAutomaticDashSubstitutionEnabled -bool false

# No autocorrect, auto-capitalization, or period on double space
pref -g NSAutomaticSpellingCorrectionEnabled -bool false
pref -g NSAutomaticCapitalizationEnabled -bool false
pref -g NSAutomaticPeriodSubstitutionEnabled -bool false

# No Genmoji and emoji mix suggestions while typing
pref com.apple.EmojiPreferences GenmojiSuggestions -bool false
pref com.apple.keyboard.preferences IsMixmojiSuggestionsEnabled -bool false

## Save dialogs

# Open expanded, with the folder browser, instead of the small version
pref -g NSNavPanelExpandedStateForSaveMode -bool true
pref -g NSNavPanelExpandedStateForSaveMode2 -bool true

# Save new documents to the Mac instead of iCloud
pref -g NSDocumentSaveNewDocumentsToCloud -bool false

## Appearance

# Light/dark mode follows the time of day
pref -g AppleInterfaceStyleSwitchesAutomatically -bool true

## Dock

pref com.apple.dock autohide -bool true

# The hidden Dock shows up as soon as the pointer reaches it, and slides in faster
pref com.apple.dock autohide-delay -float 0
pref com.apple.dock autohide-time-modifier -float 0.3

# Only show open apps: pinned apps are hidden (but still remembered)
pref com.apple.dock static-only -bool true

# No "recent applications" section
pref com.apple.dock show-recents -bool false

# Keep Spaces in the order they were made, instead of reordering them by recent use
pref com.apple.dock mru-spaces -bool false

## Finder

# List view by default (folders with their own view settings keep them)
pref com.apple.finder FXPreferredViewStyle -string Nlsv

# New windows open the home folder instead of Recents
pref com.apple.finder NewWindowTarget -string PfHm
pref com.apple.finder NewWindowTargetPath -string "file://$HOME/"

# Show ~/Library, which macOS hides with a file flag rather than a preference
if ls -ldO ~/Library | grep -q hidden; then
  chflags nohidden ~/Library
  echo "unhid ~/Library"
  RESTART_FINDER=1
fi

# Show all file extensions (a global preference, so Finder doesn't restart by itself)
pref -g AppleShowAllExtensions -bool true
if [ -n "$PREF_CHANGED" ]; then RESTART_FINDER=1; fi

# No Tags section in the sidebar
pref com.apple.finder ShowRecentTags -bool false

# Path bar and status bar at the bottom of windows
pref com.apple.finder ShowPathbar -bool true
pref com.apple.finder ShowStatusBar -bool true

# Search the current folder instead of the whole Mac
pref com.apple.finder FXDefaultSearchScope -string SCcf

# No warning when changing a file's extension
pref com.apple.finder FXEnableExtensionChangeWarning -bool false

# Folders before files when sorting by name
pref com.apple.finder _FXSortFoldersFirst -bool true

# No .DS_Store files on network and USB drives
pref com.apple.desktopservices DSDontWriteNetworkStores -bool true
pref com.apple.desktopservices DSDontWriteUSBStores -bool true

## Screenshots

# Saved to ~/Screenshots instead of the Desktop
mkdir -p ~/Screenshots
pref com.apple.screencapture location -string ~/Screenshots

# No shadow around window screenshots
pref com.apple.screencapture disable-shadow -bool true

## Windows

# No gaps between windows tiled side by side
pref com.apple.WindowManager EnableTiledWindowMargins -bool false

## Apply

if [ -n "$RESTART_DOCK" ]; then killall Dock; fi
if [ -n "$RESTART_FINDER" ]; then killall Finder; fi
if [ -n "$RESTART_SYSTEMUISERVER" ]; then killall SystemUIServer; fi

if [ -n "$RELOAD_SETTINGS" ]; then
  # Applies most trackpad and keyboard changes without logging out
  ACTIVATE=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
  if [ -x "$ACTIVATE" ]; then "$ACTIVATE" -u; fi
  echo
  echo "macOS settings changed: restart apps, or log out if something hasn't applied"
fi
