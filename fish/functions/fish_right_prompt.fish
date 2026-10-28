# Right prompt: empty while typing, so the input line only has the arrow.
# Once a command is run, shows the time it was run at, for the scrollback.
function fish_right_prompt
    contains -- --final-rendering $argv; or return
    set_color brblack
    date '+%H:%M'
    set_color normal
end
