# cdr: pick a folder in the current git repo with fzf and cd into it.
# Searches from the repo root (or the current folder if not in a repo),
# including hidden folders but skipping .git. Needs fd and fzf.
function cdr --description 'fuzzy-cd within the current repo'
    set -l root (git rev-parse --show-toplevel 2>/dev/null; or pwd)
    set -l selection (fd --type d --hidden --exclude .git . $root | fzf --height 40% --reverse --border)
    # Empty when fzf is cancelled (Esc / Ctrl-C)
    if test -n "$selection"
        cd $selection
    end
end
