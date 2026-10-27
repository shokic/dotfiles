# Directories added to PATH.
# Named 00- so it loads first: the other conf.d files rely on tools found here.
# fish_add_path skips directories already in PATH or that don't exist.
# -g keeps it to this session instead of saving it as a universal variable.

# Homebrew (Apple Silicon install location)
fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin

# User-installed scripts and tools
fish_add_path -g $HOME/.local/bin
