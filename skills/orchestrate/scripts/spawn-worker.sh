#!/bin/bash
# Starts a worker: a Claude Code session in its own Rex tab, in its own git worktree,
# with a shell pane below it in the same worktree.
#
#   spawn-worker.sh NAME [--base REF] [--branch BRANCH] [--model MODEL] [--no-worktree] [--no-shell]
#
# The brief must already be at .claude/orchestrator/NAME.brief.md (in the main checkout).
# NAME names the tab, the worktree (.claude/worktrees/NAME) and, unless --branch is given,
# the branch. --no-worktree runs the worker in the main checkout, for read-only work.
# Prints the worker's registry line as JSON.

. "$(dirname "$0")/lib.sh"

[ $# -ge 1 ] || die "usage: spawn-worker.sh NAME [--base REF] [--branch BRANCH] [--model MODEL] [--no-worktree] [--no-shell]"
NAME="$1"; shift
[[ "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "NAME must be lowercase letters, digits and hyphens"

BASE="HEAD" BRANCH="$NAME" MODEL="opus" USE_WORKTREE=1 SHELL_PANE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --no-worktree) USE_WORKTREE=""; shift ;;
    --no-shell) SHELL_PANE=""; shift ;;
    *) die "unknown option $1" ;;
  esac
done

BRIEF="$RUN_DIR/$NAME.brief.md"
[ -f "$BRIEF" ] || die "write the brief first: $BRIEF"
if [ -f "$REGISTRY" ] && cut -f1 "$REGISTRY" | grep -qx "$NAME"; then
  die "a worker named '$NAME' already exists: send it a follow-up with tell-worker.sh, or close it first"
fi

# Keep the orchestrator's files and the worktrees out of git status, without touching .gitignore
mkdir -p "$RUN_DIR" "$GIT_COMMON/info"
for path in .claude/orchestrator/ .claude/worktrees/; do
  grep -qxF "$path" "$GIT_COMMON/info/exclude" 2>/dev/null || echo "$path" >> "$GIT_COMMON/info/exclude"
done

if [ -n "$USE_WORKTREE" ]; then
  DIR="$WORKTREES/$NAME"
  [ ! -e "$DIR" ] || die "$DIR already exists"
  git -C "$REPO" worktree add -q -b "$BRANCH" "$DIR" "$BASE"
else
  DIR="$REPO" BRANCH=""
fi

# The model is always passed: without it the worker would use the default model, which may be
# the orchestrator's expensive one
created="$(rex window new -s "$REX_SESSION" "$NAME" -c "$DIR" --focus=false --json -- \
  claude --model "$MODEL" --permission-mode auto -n "$NAME" \
  "You are a worker in an orchestrated run. Read $BRIEF and carry it out.")"
BLOCK="$(echo "$created" | jq -er '.block_ids[0]')"
WINDOW="$(echo "$created" | jq -er '.window_id')"

SHELL_BLOCK=""
if [ -n "$SHELL_PANE" ]; then
  SHELL_BLOCK="$(rex split -s "$REX_SESSION" -b "$BLOCK" --split=below --ratio 25 --label "$NAME shell" \
    --focus=false -c "$DIR" --json | jq -er '.block_ids[0]')"
fi

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$NAME" "$BLOCK" "$WINDOW" "$SHELL_BLOCK" "$DIR" "$BRANCH" "$MODEL" >> "$REGISTRY"
jq -n --arg name "$NAME" --arg block "$BLOCK" --arg window "$WINDOW" --arg dir "$DIR" --arg branch "$BRANCH" \
  --arg model "$MODEL" --arg brief "$BRIEF" --arg report "$RUN_DIR/$NAME.report.md" \
  '{name: $name, block: $block, window: $window, worktree: $dir, branch: $branch, model: $model, brief: $brief, report: $report}'
