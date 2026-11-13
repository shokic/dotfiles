#!/bin/bash
# Closes a worker's tab and forgets the worker. Its branch and its commits are kept.
#
#   close-worker.sh NAME [--remove-worktree]
#
# --remove-worktree also deletes the worktree folder. Git refuses when it holds uncommitted
# changes, and this script doesn't force it: look at them first.
# The brief and the report stay in .claude/orchestrator/.

. "$(dirname "$0")/lib.sh"

[ $# -ge 1 ] || die "usage: close-worker.sh NAME [--remove-worktree]"
NAME="$1" REMOVE=""
[ "${2:-}" = "--remove-worktree" ] && REMOVE=1

WINDOW="$(field "$NAME" 3)"
DIR="$(field "$NAME" 5)"

rex window close -s "$REX_SESSION" "$WINDOW" 2>/dev/null || echo "tab already closed"

if [ -n "$REMOVE" ] && [ "$DIR" != "$REPO" ]; then
  git -C "$REPO" worktree remove "$DIR" || die "worktree kept (see above); the tab is closed and '$NAME' is still registered"
  echo "removed $DIR"
fi

awk -F'\t' -v n="$NAME" '$1 != n' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
echo "closed $NAME"
