# Utility shell functions for Zsh
#
# Provides:
# - shell(): quick nix-shell access
# - ssh(): enhanced SSH wrapper with autossh fallback
# - setup_ssh_agent_for_gui(): SSH agent for GUI apps

''
# nix shortcuts
shell() {
    nix-shell '<nixpkgs>' -A "$1"
}

# rationalise-dot: when the user types a third (or later) consecutive "."
# at the end of the buffer, expand it to "/..". This makes "..." expand to
# "../..", "...." to "../../..", etc. — and because the expansion happens
# inline in the buffer, tab-completion (e.g. `cd .../<TAB>`) works naturally.
rationalise-dot() {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+=/..
  else
    LBUFFER+=.
  fi
}
zle -N rationalise-dot
bindkey . rationalise-dot
# Keep "." literal inside incremental search
bindkey -M isearch . self-insert

# Enhanced SSH wrapper with intelligent reconnection
ssh() {
  # Optimized connection wrapper with autossh fallback
  if command -v autossh >/dev/null 2>&1; then
    # Use autossh with optimized settings for reliability
    AUTOSSH_POLL=60 AUTOSSH_FIRST_POLL=30 autossh -M 0 \
      -o "ServerAliveInterval=30" \
      -o "ServerAliveCountMax=3" \
      "$@"
  else
    # Enhanced regular SSH with connection optimization
    command ssh \
      -o "ServerAliveInterval=60" \
      -o "ServerAliveCountMax=3" \
      -o "TCPKeepAlive=yes" \
      "$@"
  fi
}

# SSH agent setup for GUI applications
# Ensures GUI apps can access SSH agent for Git operations
setup_ssh_agent_for_gui() {
  if [[ -n "$SSH_AUTH_SOCK" && -S "$SSH_AUTH_SOCK" ]]; then
    # Set SSH agent variables for GUI applications
    launchctl setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null || true
    [[ -n "$SSH_AGENT_PID" ]] && launchctl setenv SSH_AGENT_PID "$SSH_AGENT_PID" 2>/dev/null || true
    echo "SSH agent configured for GUI applications"
  fi
}

# Setup SSH agent for GUI applications
setup_ssh_agent_for_gui
''
