#!/bin/bash
# Waits until a worker needs the orchestrator, then prints every worker's state.
#
#   wait-workers.sh [--now] [--for SECONDS] [--marker TEXT] [--grace SECONDS] [NAME...]
#
# A worker has finished when its turn ended (done, idle) AND it wrote its report after it
# was last asked something (spawn-worker.sh and tell-worker.sh record that moment). The
# state alone isn't enough: a worker reports "done" while a background command of its own
# is still running, and wakes up again when it ends.
#
# Returns as soon as one of the named workers (default: all):
#   - finished, as defined above. With --marker, the report must also contain TEXT (for a
#     follow-up that appends a section to an existing report);
#   - has been at its prompt for --grace seconds (default 300) without a fresh report:
#     it stopped early, look at its screen;
#   - has been blocked on a question or a permission for 60 seconds;
#   - failed (error), lost its pane (gone), or reported nothing for 30 seconds (none).
# Name only the workers still expected to be working. --now prints the states without
# waiting. --for gives up after SECONDS (default 7200).
#
# Output: the reason it returned, then one line per worker:
#   NAME  STATE  KIND  REPORT(fresh|stale|no)  MESSAGE

. "$(dirname "$0")/lib.sh"

NOW="" LIMIT=7200 GRACE=300 MARKER="" NAMES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --now) NOW=1; shift ;;
    --for) LIMIT="$2"; shift 2 ;;
    --grace) GRACE="$2"; shift 2 ;;
    --marker) MARKER="$2"; shift 2 ;;
    -*) die "unknown option $1" ;;
    *) NAMES+=("$1"); shift ;;
  esac
done
[ -f "$REGISTRY" ] || die "no workers yet"
if [ ${#NAMES[@]} -eq 0 ]; then
  while read -r n; do NAMES+=("$n"); done < <(cut -f1 "$REGISTRY")
fi

# fresh: written after the worker was last asked something. stale: older than that. no: missing.
report_state() {
  local report="$RUN_DIR/$1.report.md" asked="$RUN_DIR/$1.asked"
  [ -s "$report" ] || { echo no; return; }
  if [ -f "$asked" ] && [ ! "$report" -nt "$asked" ]; then echo stale; return; fi
  if [ -n "$MARKER" ] && ! grep -qF -- "$MARKER" "$report"; then echo stale; return; fi
  echo fresh
}

print_all() {
  local n s kind msg
  while read -r n; do
    IFS=$'\t' read -r s kind msg <<< "$(state "$n")"
    printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$s" "${kind:--}" "$(report_state "$n")" "$msg"
  done < <(cut -f1 "$REGISTRY")
}

START=$SECONDS REASON=""
declare -a IDLE_SINCE BLOCKED_SINCE
while [ -z "$NOW" ]; do
  for i in "${!NAMES[@]}"; do
    n="${NAMES[$i]}"
    s="$(state "$n" | cut -f1)"
    case "$s" in
      working) IDLE_SINCE[$i]="" BLOCKED_SINCE[$i]="" ;;
      done|idle)
        BLOCKED_SINCE[$i]=""
        if [ "$(report_state "$n")" = fresh ]; then REASON="$n finished"; break 2; fi
        [ -n "${IDLE_SINCE[$i]:-}" ] || IDLE_SINCE[$i]=$SECONDS
        if [ $((SECONDS - IDLE_SINCE[$i])) -ge "$GRACE" ]; then
          REASON="$n has been at its prompt for ${GRACE}s without a fresh report: look at its screen"; break 2
        fi ;;
      blocked)
        IDLE_SINCE[$i]=""
        [ -n "${BLOCKED_SINCE[$i]:-}" ] || BLOCKED_SINCE[$i]=$SECONDS
        if [ $((SECONDS - BLOCKED_SINCE[$i])) -ge 60 ]; then REASON="$n is blocked: the user decides"; break 2; fi ;;
      # A session reports nothing for its first seconds; past that it's stuck on a startup prompt
      none) if [ $((SECONDS - START)) -ge 30 ]; then REASON="$n reports no status: look at its screen"; break 2; fi ;;
      *) REASON="$n is $s"; break 2 ;;
    esac
  done
  if [ $((SECONDS - START)) -ge "$LIMIT" ]; then
    REASON="timed out after ${LIMIT}s"
    break
  fi
  sleep 5
done

[ -z "$REASON" ] || echo "$REASON"
print_all
