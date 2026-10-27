if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting

set -gx PATH "/opt/homebrew/bin" $PATH

alias ls="eza --icons"
alias cat="bat"
alias vim="nvim"
alias z="zed"

# prompt
set tide_git_truncation_length 50

# Git worktrees share the zoxide history of their main checkout: visits are recorded under the
# main checkout's path, and jumps from inside a worktree land on the same folder in that worktree.
function __worktree_roots --description 'Print the main checkout root, then the current linked worktree root'
    set -l top (git rev-parse --show-toplevel 2>/dev/null); or return 1
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); or return 1
    set -l main (path dirname -- $common)
    test "$top" != "$main"; or return 1
    printf '%s\n' $main $top
end

function __worktree_to_main --argument-names dir
    set -l roots (__worktree_roots); or begin
        echo $dir
        return
    end
    string replace --regex -- '^'(string escape --style=regex -- $roots[2])'(?=/|$)' $roots[1] $dir
end

function __worktree_to_current --argument-names dir
    set -l roots (__worktree_roots); or begin
        echo $dir
        return
    end
    set -l mapped (string replace --regex -- '^'(string escape --style=regex -- $roots[1])'(?=/|$)' $roots[2] $dir)
    if test -d "$mapped"
        echo $mapped
    else
        echo $dir
    end
end

zoxide init fish --cmd cd \
    | string replace -- 'command zoxide add -- (__zoxide_pwd)' 'command zoxide add -- (__worktree_to_main (__zoxide_pwd))' \
    | string replace -- '__zoxide_cd $result' '__zoxide_cd (__worktree_to_current $result)' \
    | string replace -- '(string escape -- $result)' '(string escape -- (__worktree_to_current $result))' \
    | source

# For Brewfile
set -gx HOMEBREW_BUNDLE_FILE "$HOME/.config/Brewfile"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
export PATH="$HOME/.local/bin:$PATH"

# opencode
fish_add_path /Users/kpushpanathan/.opencode/bin


alias assume="source (brew --prefix)/bin/assume.fish"

function cdr --description 'fuzzy-cd within the current repo'
    set -l root (git rev-parse --show-toplevel 2>/dev/null; or pwd)
    set -l selection (fd --type d --hidden --exclude .git . $root | fzf --height 40% --reverse --border)
    if test -n "$selection"
        cd $selection
    end
end
