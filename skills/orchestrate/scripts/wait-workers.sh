#!/bin/bash
# Waits until a worker needs the orchestrator, then prints every worker's state.
#
#   wait-workers.sh [--now] [--for SECONDS] [NAME...]
#
# Returns as soon as one of the named workers (default: all) stops working: it finished
# (done, idle), is stuck on a question or a permission (blocked), failed (error), its pane
# closed (gone), or it has reported nothing for 30 seconds (none: look at its screen).
# Name only the workers still expected to be working, or it returns at once for the others.
# --now prints the states without waiting. --for gives up after SECONDS (default 3600).
#
# Output, one line per worker: NAME  STATE  KIND  REPORT(yes|no)  MESSAGE

. "$(dirname "$0")/lib.sh"

NOW="" LIMIT=3600 NAMES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --now) NOW=1; shift ;;
    --for) LIMIT="$2"; shift 2 ;;
    -*) die "unknown option $1" ;;
    *) NAMES+=("$1"); shift ;;
  esac
done
[ -f "$REGISTRY" ] || die "no workers yet"
if [ ${#NAMES[@]} -eq 0 ]; then
  while read -r n; do NAMES+=("$n"); done < <(cut -f1 "$REGISTRY")
fi

print_all() {
  local n s kind msg report
  while read -r n; do
    IFS=$'\t' read -r s kind msg <<< "$(state "$n")"
    report=no; [ -f "$RUN_DIR/$n.report.md" ] && report=yes
    printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$s" "${kind:--}" "$report" "$msg"
  done < <(cut -f1 "$REGISTRY")
}

START=$SECONDS
while [ -z "$NOW" ]; do
  for n in "${NAMES[@]}"; do
    s="$(state "$n" | cut -f1)"
    case "$s" in
      working) ;;
      # A session reports nothing for its first seconds; past that it's stuck on a startup prompt
      none) [ $((SECONDS - START)) -lt 30 ] || break 2 ;;
      *) break 2 ;;
    esac
  done
  if [ $((SECONDS - START)) -ge "$LIMIT" ]; then
    echo "timed out after ${LIMIT}s: every named worker is still working" >&2
    break
  fi
  sleep 5
done

print_all
