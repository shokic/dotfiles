#!/bin/bash
# Sends a follow-up message to a worker, as if typed at its prompt.
#
#   tell-worker.sh [--queue] NAME 'MESSAGE'
#
# MESSAGE is one line. For anything longer, write a file in .claude/orchestrator/ and send
# a line that points to it.
#
# Without --queue the worker must be at its prompt (done, idle) or stopped on an error
# (a dropped connection: the message makes it resume). The script returns once the worker
# has started on the message.
# With --queue the message is sent while the worker is working: Claude Code queues it and
# reads it at its next step. Use it for a correction that can't wait; never interrupt a
# worker with escape.
#
# Records the moment, so wait-workers.sh can tell a report written after this message
# from an older one.

. "$(dirname "$0")/lib.sh"

QUEUE=""
if [ "${1:-}" = "--queue" ]; then QUEUE=1; shift; fi
[ $# -eq 2 ] || die "usage: tell-worker.sh [--queue] NAME 'MESSAGE'"
NAME="$1" MESSAGE="$2"
case "$MESSAGE" in *$'\n'*) die "MESSAGE must be one line: put the details in a file and point to it" ;; esac

BLOCK="$(field "$NAME" 2)"
s="$(state "$NAME" | cut -f1)"
if [ -n "$QUEUE" ]; then
  [ "$s" = working ] || die "'$NAME' is $s, not working: send the message without --queue"
else
  case "$s" in
    done|idle|error) ;;
    *) die "'$NAME' is $s: use --queue if it is working, otherwise look at its screen (peek-worker.sh $NAME)" ;;
  esac
  touch "$RUN_DIR/$NAME.asked"
fi

rex send -s "$REX_SESSION" -b "$BLOCK" "$MESSAGE"
rex send-key -s "$REX_SESSION" -b "$BLOCK" enter

if [ -n "$QUEUE" ]; then echo "queued for $NAME"; exit 0; fi
for _ in $(seq 30); do
  [ "$(state "$NAME" | cut -f1)" = working ] && { echo "sent to $NAME"; exit 0; }
  sleep 1
done
die "sent, but '$NAME' didn't start working within 30s: look at its screen (peek-worker.sh $NAME)"
