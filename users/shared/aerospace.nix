# Aerospace Configuration
#
# Advanced window management for macOS with i3/sway-like functionality
# Features:
# - Vim-style navigation (alt-h/j/k/l)
# - Dynamic workspace management (alt-1~0, alt-shift-1~0)
# - Multiple layout modes (horizontal, vertical, accordion, floating)
# - Smart gaps and window normalization
# - Service mode for advanced operations
#
# Note: Aerospace must be installed manually:
# brew install --cask nikitabobko/tap/aerospace

# Only deploy config file - AeroSpace will pick it up automatically
  home.file.".config/aerospace/aerospace.toml" = {
    source = aerospace-config;
  };
