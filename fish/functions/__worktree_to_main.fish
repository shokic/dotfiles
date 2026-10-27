# Helper for the zoxide worktree hook (see conf.d/zoxide.fish).
#
# Converts a path inside the current worktree into the same path in the main checkout,
# so zoxide records all visits under the main checkout.
# e.g. ~/code/app-feature/src -> ~/code/app/src
# Paths are returned unchanged when not in a linked worktree.
function __worktree_to_main --argument-names dir
    set -l roots (__worktree_roots); or begin
        echo $dir
        return
    end
    # Swap the worktree root prefix ($roots[2]) for the main root ($roots[1])
    string replace --regex -- '^'(string escape --style=regex -- $roots[2])'(?=/|$)' $roots[1] $dir
end
