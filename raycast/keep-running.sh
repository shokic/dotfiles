#!/bin/bash
# Keeps the Mac awake for a while, even with the lid closed or the screen locked, then lets it sleep
# normally again. Running it again replaces the timer; "Keep Running: Stop" ends it early.
#
# Lid closed needs `pmset disablesleep` (caffeinate can't do it), which needs root: setup.sh allows
# exactly that command without a password, in /etc/sudoers.d/keep-running.
# The display still turns off; only the Mac stays awake (downloads, servers, SSH keep running).

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Keep Running
# @raycast.mode silent
# @raycast.argument1 { "type": "dropdown", "placeholder": "Duration", "data": [{"title": "30 minutes", "value": "30"}, {"title": "1 hour", "value": "60"}, {"title": "2 hours", "value": "120"}, {"title": "3 hours", "value": "180"}, {"title": "4 hours", "value": "240"}, {"title": "6 hours", "value": "360"}, {"title": "8 hours", "value": "480"}] }

# Optional parameters:
# @raycast.icon 🏃
# @raycast.packageName Keep Running
# @raycast.description Keep the Mac awake, even with the lid closed or locked, for a while

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

MINUTES="$1"
# The running timer's process, so a new run or "Stop" can end it
PIDFILE="$HOME/Library/Caches/keep-running.pid"

# End the previous timer, if any, and wait for it to put sleep back,
# so it can't re-enable sleep after this run disabled it
if [ -f "$PIDFILE" ]; then
  read -r pid _ < "$PIDFILE"
  # Check it's still our timer: after a restart, the PID may belong to another process
  if ps -p "$pid" -o command= 2>/dev/null | grep -q keep-running; then
    kill "$pid"
    while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
  fi
fi

# -n: fail instead of asking for a password, which Raycast can't show
if ! sudo -n /usr/bin/pmset -a disablesleep 1; then
  echo "Not allowed to change sleep settings: run ./setup.sh in the dotfiles"
  exit 1
fi

# Timer in the background, so Raycast doesn't wait for it: puts sleep back when it ends or is killed.
# `sleep & wait` rather than plain `sleep`: bash only runs traps once a foreground command finishes.
# (sleeper isn't local: the EXIT trap runs after the function returns, and set -u would stop it there)
timer() {
  sleeper=""
  trap 'kill $sleeper 2>/dev/null || true; sudo -n /usr/bin/pmset -a disablesleep 0; rm -f "$PIDFILE"' EXIT
  trap 'exit' TERM INT HUP
  sleep $((MINUTES * 60)) &
  sleeper=$!
  wait $sleeper
}
# In ( ): with a bare `timer &`, macOS's bash 3.2 skips the EXIT trap when the time is up
(timer) < /dev/null > /dev/null 2>&1 &
# PID and end time, the end time for the status (keep-awake-status.sh)
echo "$! $(($(date +%s) + MINUTES * 60))" > "$PIDFILE"
disown

# Shown by Raycast as a toast
echo "🏃 Running until $(date -v+"${MINUTES}"M +%H:%M)"
