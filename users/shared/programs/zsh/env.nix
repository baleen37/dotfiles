# Environment variables and PATH configuration for Zsh
#
# Sets up:
# - PATH: pnpm, npm, local bin, cargo, go, gem, homebrew
# - Locale: en_US.UTF-8
# - Editor: vim
# - npm config
# - GitHub CLI token

# Note: isDarwin is not available here since this is a raw string import.
# Homebrew PATH is handled inline via the isDarwin conditional in default.nix.

''
  # PATH configuration - Global package managers
  export PATH="$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH"
  export PATH="$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH"
  export PATH="$HOME/.local/share/bin:$PATH"
  export PATH="$HOME/.local/bin:$PATH"
  # Cargo (Rust)
  export PATH="$HOME/.cargo/bin:$PATH"
  # Go
  export PATH="$HOME/go/bin:$PATH"
  # Gem (Ruby) - only if GEM_HOME is set to user directory
  if [[ -n "$GEM_HOME" ]]; then
    export PATH=$GEM_HOME/bin:$PATH
  fi

  # History configuration
  export HISTIGNORE="pwd:ls:cd"

  # Locale settings for UTF-8 support
  export LANG="en_US.UTF-8"
  export LC_ALL="en_US.UTF-8"

  # Editor preferences
  export EDITOR="vim"
  export VISUAL="vim"

  # npm configuration
  export NPM_CONFIG_PREFIX="$HOME/.npm-global"

  # GitHub CLI token
  export GITHUB_TOKEN=$(gh auth token)
''
