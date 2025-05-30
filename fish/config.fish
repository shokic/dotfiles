if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting

set -gx PATH "/opt/homebrew/bin" $PATH

alias ls="eza --icons"
alias cat="bat"
alias vim="nvim"

function se
    sesh connect $(sesh list | fzf)
end

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

# prompt
set tide_git_truncation_length 50

zoxide init fish --cmd cd | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# For Brewfile
set -gx HOMEBREW_BUNDLE_FILE "$HOME/.config/Brewfile"
