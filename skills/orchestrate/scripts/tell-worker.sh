#!/bin/bash
# Sends a follow-up message to a worker, as if typed at its prompt.
#
#   tell-worker.sh NAME 'MESSAGE'
#
# MESSAGE is one line. For anything longer, write a file in .claude/orchestrator/ and send
# a line that points to it. Refuses while the worker is working, so a message never lands
# in the middle of its turn. Returns once the worker has started on the message, so a
# wait-workers.sh right after it doesn't see the previous turn's "done".

. "$(dirname "$0")/lib.sh"

[ $# -eq 2 ] || die "usage: tell-worker.sh NAME 'MESSAGE'"
NAME="$1" MESSAGE="$2"
case "$MESSAGE" in *$'\n'*) die "MESSAGE must be one line: put the details in a file and point to it" ;; esac

BLOCK="$(field "$NAME" 2)"
s="$(state "$NAME" | cut -f1)"
case "$s" in
  done|idle) ;;
  *) die "'$NAME' is $s, not at its prompt: look at its screen (rex capture -s \"\$REX_SESSION\" -b $BLOCK --trim | tail -40)" ;;
esac

rex send -s "$REX_SESSION" -b "$BLOCK" "$MESSAGE"
rex send-key -s "$REX_SESSION" -b "$BLOCK" enter

for _ in $(seq 30); do
  [ "$(state "$NAME" | cut -f1)" = working ] && { echo "sent to $NAME"; exit 0; }
  sleep 1
done
die "sent, but '$NAME' didn't start working within 30s: look at its screen"
