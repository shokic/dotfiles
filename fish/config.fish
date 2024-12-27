if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting

set -gx PATH "/opt/homebrew/bin" $PATH

alias ls="eza --icons"
alias cat="bat"

function se
    sesh connect $(sesh list | fzf)
end

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

zoxide init fish --cmd cd | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
