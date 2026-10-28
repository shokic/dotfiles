# Formats a duration in milliseconds for the prompt: 120ms, 4.2s or 2m05s
function __prompt_format_duration --argument-names ms
    if test $ms -lt 1000
        echo {$ms}ms
    else if test $ms -lt 60000
        echo (math "floor($ms / 100) / 10")s
    else
        printf '%dm%02ds\n' (math "floor($ms / 60000)") (math "floor($ms % 60000 / 1000)")
    end
end
