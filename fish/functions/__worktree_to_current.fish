# Helper for the zoxide worktree hook (see conf.d/zoxide.fish).
#
# The reverse of __worktree_to_main: converts a path in the main checkout into the same
# path in the current worktree, so `cd` jumps stay inside the worktree you're working in.
# e.g. ~/code/app/src -> ~/code/app-feature/src
# Falls back to the original path if that folder doesn't exist in the worktree,
# or when not in a linked worktree.
function __worktree_to_current --argument-names dir
    set -l roots (__worktree_roots); or begin
        echo $dir
        return
    end
    # Swap the main root prefix ($roots[1]) for the worktree root ($roots[2])
    set -l mapped (string replace --regex -- '^'(string escape --style=regex -- $roots[1])'(?=/|$)' $roots[2] $dir)
    if test -d "$mapped"
        echo $mapped
    else
        echo $dir
    end
end
