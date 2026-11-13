# Shared by the orchestrate scripts. Sourced, not run.

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

command -v rex > /dev/null || die "rex isn't installed"
command -v jq > /dev/null || die "jq isn't installed"
[ -n "${REX_SESSION:-}" ] || die "REX_SESSION isn't set: run this from a terminal inside Rex"

# The main checkout, even when called from inside a worktree
GIT_COMMON="$(cd "$(git rev-parse --git-common-dir 2>/dev/null)" && pwd)" || die "not in a git repository"
REPO="$(dirname "$GIT_COMMON")"

# Briefs, reports and the worker registry live here; worktrees live beside it
RUN_DIR="$REPO/.claude/orchestrator"
WORKTREES="$REPO/.claude/worktrees"
REGISTRY="$RUN_DIR/workers.tsv"   # name, block, window, shell block, worktree, branch, model

# Print one field of a worker's registry line: field NAME NUMBER
field() {
  [ -f "$REGISTRY" ] || die "no workers yet ($REGISTRY doesn't exist)"
  local value
  value="$(awk -F'\t' -v n="$1" -v f="$2" '$1 == n { print $f; found = 1 } END { exit !found }' "$REGISTRY")" \
    || die "no worker named '$1' (known: $(cut -f1 "$REGISTRY" | tr '\n' ' '))"
  echo "$value"
}

# Print a worker's state as "STATE<TAB>KIND<TAB>MESSAGE": state NAME
# STATE is what Claude Code reports to Rex (working, done, idle, blocked, error), or
# "none" when it reports nothing (still starting, or stuck on a startup prompt), or
# "gone" when its pane no longer exists.
state() {
  local block out
  block="$(field "$1" 2)"
  if ! out="$(rex block call -s "$REX_SESSION" -b "$block" program_status 2>/dev/null)"; then
    printf 'gone\t\t\n'
    return
  fi
  echo "$out" | jq -r '(.records[0] // {}) | [.state // "none", .kind // "", .msg // ""] | @tsv'
}
