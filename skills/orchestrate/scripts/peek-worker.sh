#!/bin/bash
# Prints the end of a pane's screen, with anything that looks like a secret masked.
#
#   peek-worker.sh NAME [LINES]          the worker's Claude Code pane
#   peek-worker.sh --shell NAME [LINES]  the shell pane beside it
#   peek-worker.sh --block BLOCK [LINES] any pane of the session, by block id
#
# LINES defaults to 40. The capture includes the scrollback, so a `clear` in the pane
# hides nothing: tokens, keys and Authorization headers are masked here, including when
# the terminal wrapped them over several lines.

. "$(dirname "$0")/lib.sh"

case "${1:-}" in
  --shell) BLOCK="$(field "${2:?NAME}" 4)"; shift 2 ;;
  --block) BLOCK="${2:?BLOCK}"; shift 2 ;;
  "") die "usage: peek-worker.sh [--shell] NAME [LINES] | --block BLOCK [LINES]" ;;
  *) BLOCK="$(field "$1" 2)"; shift ;;
esac
LINES_WANTED="${1:-40}"

rex capture -s "$REX_SESSION" -b "$BLOCK" --trim | tail -n "$LINES_WANTED" | awk '
  # A long unbroken run of token characters is a secret, or the wrapped rest of one
  function mask(line) {
    gsub(/eyJ[A-Za-z0-9_.-]+/, "<hidden>", line)
    gsub(/(AKIA|ASIA)[A-Z0-9]{12,}/, "<hidden>", line)
    gsub(/(gh[pousr]_|sk-|xox[abp]-)[A-Za-z0-9_-]{10,}/, "<hidden>", line)
    gsub(/[Bb]earer +[A-Za-z0-9_.=-]+/, "Bearer <hidden>", line)
    return line
  }
  {
    line = mask($0)
    if (hidden && line ~ /^[A-Za-z0-9_.=+\/-]{20,}$/) { print "<hidden>"; next }
    hidden = (line ~ /<hidden>/)
    print line
  }'
