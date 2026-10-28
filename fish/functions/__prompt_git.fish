# Git part of the prompt, in words. Prints nothing outside a git repo.
#   main ↑1 ↓2 · 1 staged · 3 changed · 2 new · 1 stash
#   main MERGING · 1 conflict · 1 staged
#
#   ↑ ↓       commits not pushed yet / not pulled yet
#   conflict  files with merge conflicts
#   staged    files added with `git add`, ready to commit
#   changed   files modified but not staged
#   new       untracked files, not in git yet
#   stash     entries in `git stash list`
function __prompt_git
    # One git call gives the branch, ahead/behind, stash count and every file's state.
    # --no-optional-locks: don't block other git commands while the prompt runs
    set -l status_lines (git --no-optional-locks status --porcelain=v2 --branch --show-stash 2>/dev/null)
    or return

    set -l git_dir (git rev-parse --git-dir 2>/dev/null)

    # Branch name, or the commit hash when detached
    set -l branch (string replace -rf '^# branch\.head ' '' -- $status_lines)
    if test "$branch" = "(detached)"
        set branch (string match -rg '^# branch\.oid (.{8})' -- $status_lines)
    end

    # In-progress operation. A rebase detaches HEAD, so take the branch name from the rebase state.
    set -l operation
    if test -d $git_dir/rebase-merge -o -d $git_dir/rebase-apply
        set operation REBASING
        for head_name in $git_dir/rebase-merge/head-name $git_dir/rebase-apply/head-name
            test -f $head_name; and set branch (string replace 'refs/heads/' '' < $head_name)
        end
    else if test -f $git_dir/MERGE_HEAD
        set operation MERGING
    else if test -f $git_dir/CHERRY_PICK_HEAD
        set operation CHERRY-PICKING
    else if test -f $git_dir/REVERT_HEAD
        set operation REVERTING
    else if test -f $git_dir/BISECT_LOG
        set operation BISECTING
    end

    # Ahead/behind, e.g. "# branch.ab +1 -2"; missing when the branch has no upstream
    set -l ab (string match -rg '^# branch\.ab \+(\d+) -(\d+)' -- $status_lines)

    # File lines start with "1 XY" (changed) or "2 XY" (renamed), where X is the staged state and
    # Y the unstaged state ("." = unchanged); "u" lines are conflicts and "?" lines untracked files.
    set -l conflicts (count (string match -r '^u ' -- $status_lines))
    set -l staged (count (string match -r '^[12] [^.]' -- $status_lines))
    set -l changed (count (string match -r '^[12] .[^.]' -- $status_lines))
    set -l new (count (string match -r '^\? ' -- $status_lines))
    set -l stashes (string match -rg '^# stash (\d+)' -- $status_lines)

    set_color yellow
    echo -n " $branch"
    if test -n "$operation"
        set_color red
        echo -n " $operation"
    end

    set_color yellow
    test -n "$ab[1]" -a "$ab[1]" != 0; and echo -n " ↑$ab[1]"
    test -n "$ab[2]" -a "$ab[2]" != 0; and echo -n " ↓$ab[2]"

    set -l parts
    test $conflicts -eq 1; and set -a parts (set_color red)"1 conflict"(set_color yellow)
    test $conflicts -gt 1; and set -a parts (set_color red)"$conflicts conflicts"(set_color yellow)
    test $staged -gt 0; and set -a parts "$staged staged"
    test $changed -gt 0; and set -a parts "$changed changed"
    test $new -gt 0; and set -a parts "$new new"
    test -n "$stashes"; and test $stashes -eq 1; and set -a parts "1 stash"
    test -n "$stashes"; and test $stashes -gt 1; and set -a parts "$stashes stashes"

    for part in $parts
        echo -n (set_color brblack)" · "(set_color yellow)$part
    end
    set_color normal
end
