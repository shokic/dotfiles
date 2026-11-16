#!/bin/bash
# Starts a worker: a Claude Code session in its own Rex tab, in its own git worktree,
# with a shell pane beside it in the same worktree.
#
#   spawn-worker.sh NAME [--base REF] [--branch BRANCH] [--no-worktree] [--no-shell]
#
# The brief must already be at .claude/orchestrator/NAME.brief.md (in the main checkout).
# NAME names the tab, the worktree (.claude/worktrees/NAME) and, unless --branch is given,
# the branch. --no-worktree runs the worker in the main checkout, for read-only work.
# Workers always run on Opus with high reasoning effort.
# Prints the worker's registry line as JSON.

. "$(dirname "$0")/lib.sh"

[ $# -ge 1 ] || die "usage: spawn-worker.sh NAME [--base REF] [--branch BRANCH] [--no-worktree] [--no-shell]"
NAME="$1"; shift
[[ "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "NAME must be lowercase letters, digits and hyphens"

BASE="HEAD" BRANCH="$NAME" MODEL="opus" EFFORT="high" USE_WORKTREE=1 SHELL_PANE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
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

# The model and the effort are always passed: without them the worker would use the user's
# defaults, which may be the orchestrator's expensive model. --add-dir lets the worker read
# its brief and write its report in the main checkout without a permission prompt; it takes
# several values, so another option must follow it.
touch "$RUN_DIR/$NAME.asked"
created="$(rex window new -s "$REX_SESSION" "$NAME" -c "$DIR" --focus=false --json -- \
  claude --add-dir "$RUN_DIR" --model "$MODEL" --effort "$EFFORT" --permission-mode auto -n "$NAME" \
  "You are a worker in an orchestrated run. Read $BRIEF and carry it out. Commit messages carry no Co-Authored-By line and no AI attribution.")"
BLOCK="$(echo "$created" | jq -er '.block_ids[0]')"
WINDOW="$(echo "$created" | jq -er '.window_id')"

SHELL_BLOCK=""
if [ -n "$SHELL_PANE" ]; then
  SHELL_BLOCK="$(rex split -s "$REX_SESSION" -b "$BLOCK" --split=right --ratio 35 --label "$NAME shell" \
    --focus=false -c "$DIR" --json | jq -er '.block_ids[0]')"
fi

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$NAME" "$BLOCK" "$WINDOW" "$SHELL_BLOCK" "$DIR" "$BRANCH" "$MODEL/$EFFORT" >> "$REGISTRY"
jq -n --arg name "$NAME" --arg block "$BLOCK" --arg window "$WINDOW" --arg dir "$DIR" --arg branch "$BRANCH" \
  --arg model "$MODEL/$EFFORT" --arg brief "$BRIEF" --arg report "$RUN_DIR/$NAME.report.md" \
  '{name: $name, block: $block, window: $window, worktree: $dir, branch: $branch, model: $model, brief: $brief, report: $report}'
