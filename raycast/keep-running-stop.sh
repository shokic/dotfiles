#!/bin/bash
# Ends "Keep Running" early: the Mac sleeps normally again.

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Keep Running: Stop
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 💤
# @raycast.packageName Keep Running
# @raycast.description Let the Mac sleep normally again

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

PIDFILE="$HOME/Library/Caches/keep-running.pid"

# End the timer, which puts sleep back as it exits
if [ -f "$PIDFILE" ]; then
  read -r pid _ < "$PIDFILE"
  # Check it's still our timer: after a restart, the PID may belong to another process
  if ps -p "$pid" -o command= 2>/dev/null | grep -q keep-running; then
    kill "$pid"
    while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
  fi
  rm -f "$PIDFILE"
fi

# Also when there was no timer: the setting survives restarts, so a restart mid-timer would leave it on
sudo -n /usr/bin/pmset -a disablesleep 0 || {
  echo "Not allowed to change sleep settings: run ./setup.sh in the dotfiles"
  exit 1
}

echo "💤 Sleep is back to normal"
