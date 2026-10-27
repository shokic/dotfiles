# zoxide: replaces `cd` with a version that also jumps to frequently used folders
# (e.g. `cd dotfiles` from anywhere). Only for interactive shells, and only if installed.
status is-interactive; or return
command -q zoxide; or return

# Git worktrees share the zoxide history of their main checkout: visits are recorded under the
# main checkout's path, and jumps from inside a worktree land on the same folder in that worktree.
# This works by patching zoxide's generated fish code before sourcing it, to route paths through
# the helpers in functions/__worktree_*.fish.
zoxide init fish --cmd cd \
    | string replace -- 'command zoxide add -- (__zoxide_pwd)' 'command zoxide add -- (__worktree_to_main (__zoxide_pwd))' \
    | string replace -- '__zoxide_cd $result' '__zoxide_cd (__worktree_to_current $result)' \
    | string replace -- '(string escape -- $result)' '(string escape -- (__worktree_to_current $result))' \
    | source
