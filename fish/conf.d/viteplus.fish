# Vite+ (installed by tools.sh): adds vp, and the node/npm/pnpm it manages, to PATH, with completions.
# Its installer only sets up the shell it runs from, so it misses fish when it runs before fish is
# the login shell, as on a fresh Mac. Does nothing once Vite+ is uninstalled.
if test -f ~/.config/vite-plus/env.fish
    source ~/.config/vite-plus/env.fish
end
