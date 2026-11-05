#!/bin/bash
# Keeps the Mac awake and the screen on for a while: no sleep, no screen saver, no auto-lock.
# Lid closed still sleeps: that's "Keep Running". Running it again replaces the timer;
# "Keep Awake: Stop" ends it early.
#
# caffeinate does it all: it holds the Mac awake while it runs, and macOS goes back to normal
# as soon as it exits (time up, killed, or a restart), so there's nothing to restore.

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Keep Awake
# @raycast.mode silent
# @raycast.argument1 { "type": "dropdown", "placeholder": "Duration", "data": [{"title": "30 minutes", "value": "30"}, {"title": "1 hour", "value": "60"}, {"title": "2 hours", "value": "120"}, {"title": "3 hours", "value": "180"}, {"title": "4 hours", "value": "240"}, {"title": "6 hours", "value": "360"}, {"title": "8 hours", "value": "480"}] }

# Optional parameters:
# @raycast.icon ☕️
# @raycast.packageName Keep Awake
# @raycast.description Keep the Mac awake and the screen on, without locking, for a while

# Stop on errors, unset variables, and failures inside pipes
set -euo pipefail

MINUTES="$1"
# Our caffeinate's process, so a new run or "Stop" ends this one and not other apps' caffeinate
PIDFILE="$HOME/Library/Caches/keep-awake.pid"

# End the previous one, if any
if [ -f "$PIDFILE" ]; then
  read -r pid _ < "$PIDFILE"
  # Check it's still caffeinate: after a restart, the PID may belong to another process
  if [ "$(ps -p "$pid" -o comm= 2>/dev/null)" = /usr/bin/caffeinate ]; then kill "$pid"; fi
  rm -f "$PIDFILE"
fi

# -d display stays on, -i and -s no sleep (-s: when plugged in), -u counts as user activity,
# so the screen saver doesn't start and the screen doesn't lock. -t: for that many seconds.
# In the background, so Raycast doesn't wait for it.
/usr/bin/caffeinate -disu -t $((MINUTES * 60)) < /dev/null > /dev/null 2>&1 &
# PID and end time, the end time for the status (keep-awake-status.sh)
echo "$! $(($(date +%s) + MINUTES * 60))" > "$PIDFILE"
disown

# Shown by Raycast as a toast
echo "☕️ Awake until $(date -v+"${MINUTES}"M +%H:%M)"
