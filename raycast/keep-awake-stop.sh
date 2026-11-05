#!/bin/bash
# Ends "Keep Awake" early: the Mac sleeps and locks normally again.

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Keep Awake: Stop
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 💤
# @raycast.packageName Keep Awake
# @raycast.description Let the Mac sleep and lock normally again

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

PIDFILE="$HOME/Library/Caches/keep-awake.pid"

if [ -f "$PIDFILE" ]; then
  read -r pid _ < "$PIDFILE"
  # Check it's still caffeinate: after a restart, the PID may belong to another process
  if [ "$(ps -p "$pid" -o comm= 2>/dev/null)" = /usr/bin/caffeinate ]; then kill "$pid"; fi
  rm -f "$PIDFILE"
fi

echo "💤 Sleep is back to normal"
