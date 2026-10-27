# Command aliases.
# Only set up in interactive shells, so scripts still get the real commands.
status is-interactive; or return

# Replace ls/cat with nicer versions, but only if they're installed
command -q eza; and alias ls="eza --icons"
command -q bat; and alias cat="bat"

alias z="zed"

# granted: `assume` has to be sourced (not run) so it can set AWS credentials
# in the current shell
alias assume="source (brew --prefix)/bin/assume.fish"
