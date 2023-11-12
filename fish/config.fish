set fish_greeting

if status is-interactive
    # Commands to run in interactive sessions can go here
end

set --global hydro_symbol_prompt "> "

alias ls="exa --icons"
alias cat="bat"
alias c="code"

alias dev-sandbox="aws-vault exec dev-sandbox --"

set -gx PATH "/opt/homebrew/bin" $PATH
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH
set -gx FZF_DEFAULT_COMMAND "fd --type f --strip-cwd-prefix"

function f  
    set -l selected_dir (fd -t d | fzf)
    set -l tab_title (string replace -r '.*\/(.+\/.+\/)' '$1' $selected_dir)
    kitty @ launch --tab-title "$tab_title" --type tab --cwd current --hold fish -c "cd $selected_dir; exec fish" > /dev/null 2>&1
end
