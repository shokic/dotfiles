if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting

set -gx PATH "/opt/homebrew/bin" $PATH

alias ls="eza --icons"
alias cat="bat"
alias vim="nvim"

# prompt
set tide_git_truncation_length 50

zoxide init fish --cmd cd | source

# For Brewfile
set -gx HOMEBREW_BUNDLE_FILE "$HOME/.config/Brewfile"

# For Volta
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

# For AWS
alias koala-dev="aws-vault exec koala-dev --"
alias koala-devops="aws-vault exec koala-devops --"
