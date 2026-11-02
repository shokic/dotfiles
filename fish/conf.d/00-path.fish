# Directories added to PATH.
# Named 00- so it loads first: the other conf.d files rely on tools found here.
# fish_add_path skips directories already in PATH or that don't exist.
# -g keeps it to this session instead of saving it as a universal variable.

# Homebrew (Apple Silicon install location)
fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin

# PostgreSQL client tools (psql, pg_dump...) from the libpq formula. Homebrew doesn't link
# them into /opt/homebrew/bin ("keg-only"), as they'd conflict with a full PostgreSQL install.
fish_add_path -g /opt/homebrew/opt/libpq/bin

# User-installed scripts and tools
fish_add_path -g $HOME/.local/bin
