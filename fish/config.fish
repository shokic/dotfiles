# Main fish config, loaded last at startup.
#
# Fish loads things in this order, so most config lives elsewhere:
#   1. conf.d/*.fish   - sourced automatically at startup, in alphabetical order
#   2. config.fish     - this file
#   functions/*.fish   - not loaded at startup; each file is loaded the first time
#                        the function with the same name is called
#
# Plugins (see fish_plugins) are installed by fisher into conf.d/ and functions/ too.

# Disable the "Welcome to fish" message
set -g fish_greeting
