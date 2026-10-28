# Prompt setup. The prompt itself is in functions/fish_prompt.fish and fish_right_prompt.fish.
#
# Live prompt (2 lines):       Already-run commands (scrollback):
#   ~/c/dotfiles main  4.2s      ❯ npm test                    14:31
#   ❯ _

# Transient prompt: before running a command, fish redraws its prompt with
# --final-rendering, so it can shrink to "❯" plus the time it was run
set -g fish_transient_prompt 1


# Record the last command's duration for fish_prompt, each time a new prompt is shown.
# $status_generation only changes when a command actually ran, so an empty Enter
# clears the duration instead of showing the previous command's time again.
# Event handlers have to be defined at startup, so this can't live in functions/.
set -g __prompt_last_generation $status_generation
function __prompt_record_duration --on-event fish_prompt
    if test "$status_generation" = "$__prompt_last_generation"
        set -e __prompt_duration
    else
        set -g __prompt_duration $CMD_DURATION
    end
    set -g __prompt_last_generation $status_generation
end

# Start adding a blank line above the prompt once the first command has run,
# so a new shell doesn't open with an empty line at the top
function __prompt_enable_spacing --on-event fish_postexec
    set -g __prompt_spacing 1
    functions -e __prompt_enable_spacing
end
