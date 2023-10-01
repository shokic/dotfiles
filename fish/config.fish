set fish_greeting

if status is-interactive
    # Commands to run in interactive sessions can go here
end

set --global hydro_symbol_prompt "> "

alias ls="exa --icons"
alias cat="bat"

alias dev-sandbox="aws-vault exec dev-sandbox --"

set -gx PATH "/opt/homebrew/bin" $PATH
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH