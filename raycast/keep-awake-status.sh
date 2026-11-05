#!/bin/bash
# Shows in Raycast's search whether Keep Awake or Keep Running is on, and the time left:
#   ☕️ Awake · 1h 23m left   🏃 Running · 45m left
# Raycast re-runs it every 10 seconds (inline mode). Add it to Favorites to keep it at the top.

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Keep Awake Status
# @raycast.mode inline
# @raycast.refreshTime 10s

# Optional parameters:
# @raycast.icon ⏳
# @raycast.packageName Keep Awake
# @raycast.description Whether Keep Awake or Keep Running is on, and the time left

# Fail on unset variables and failures inside pipes (not -e: an empty or missing state file is normal)
set -uo pipefail

# "1h 23m" or "45m" for $1 seconds, rounded up so it never shows 0m while running
format_left() {
  local minutes=$((($1 + 59) / 60))
  if [ "$minutes" -ge 60 ]; then
    echo "$((minutes / 60))h $((minutes % 60))m"
  else
    echo "${minutes}m"
  fi
}

# Seconds left for the timer in state file $1 ("PID END"), if its process is still running and
# its command contains $2. Prints nothing otherwise: time up, stopped, or a restart since.
seconds_left() {
  local pid="" end=""
  [ -f "$1" ] || return 0
  read -r pid end < "$1"
  [ -n "$pid" ] && [ -n "$end" ] || return 0
  ps -p "$pid" -o command= 2>/dev/null | grep -q -- "$2" || return 0
  local left=$((end - $(date +%s)))
  [ "$left" -gt 0 ] && echo "$left"
  return 0
}

status=""

awake="$(seconds_left "$HOME/Library/Caches/keep-awake.pid" 'caffeinate -disu')"
[ -n "$awake" ] && status="☕️ Awake · $(format_left "$awake") left"

running="$(seconds_left "$HOME/Library/Caches/keep-running.pid" keep-running)"
if [ -n "$running" ]; then
  status="${status:+$status   }🏃 Running · $(format_left "$running") left"
# Sleep still off without a timer: the Mac restarted mid-timer, so nothing will turn it back on
elif pmset -g | grep -qE 'SleepDisabled[[:space:]]+1'; then
  status="${status:+$status   }⚠️ Sleep still off: run Keep Running: Stop"
fi

echo "${status:-💤 Off}"
