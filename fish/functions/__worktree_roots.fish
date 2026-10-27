# Helper for the zoxide worktree hook (see conf.d/zoxide.fish).
#
# When inside a linked git worktree, prints two lines:
#   1. the root of the main checkout
#   2. the root of the current worktree
# Fails (returns 1) when not in a git repo, or when in the main checkout itself.
function __worktree_roots --description 'Print the main checkout root, then the current linked worktree root'
    set -l top (git rev-parse --show-toplevel 2>/dev/null); or return 1
    # The shared .git directory lives in the main checkout, so its parent is the main root
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); or return 1
    set -l main (path dirname -- $common)
    test "$top" != "$main"; or return 1
    printf '%s\n' $main $top
end
