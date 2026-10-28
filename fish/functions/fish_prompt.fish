# Left prompt, on two lines, after a blank line (except on the first prompt):
#   ~/c/dotfiles main · 2 changed  4.2s     folder, git status (see __prompt_git), last command's duration
#   ❯                                        green, or red if the last command failed
# Once a command is run, it's redrawn as just a grey "❯" (see conf.d/prompt.fish).
function fish_prompt
    set -l last_status $status

    # Blank line between the previous command's output and the prompt
    set -q __prompt_spacing; and echo

    if contains -- --final-rendering $argv
        set_color brblack
        echo -n '❯ '
        set_color normal
        return
    end

    # Line 1
    set_color blue
    echo -n (prompt_pwd)
    __prompt_git
    set_color brblack
    if set -q __prompt_duration
        echo -n '  '(__prompt_format_duration $__prompt_duration)
    end
    echo

    # Line 2
    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end
    echo -n '❯ '
    set_color normal
end
