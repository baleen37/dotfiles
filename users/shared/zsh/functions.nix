# Utility shell functions for Zsh
#
# Provides:
# - shell(): quick nix-shell access
# - ssh(): enhanced SSH wrapper with autossh fallback
# - idea(): IntelliJ IDEA background launcher
# - setup_ssh_agent_for_gui(): SSH agent for GUI apps

''
# nix shortcuts
shell() {
    nix-shell '<nixpkgs>' -A "$1"
}

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

# IntelliJ IDEA background launcher
# Runs IntelliJ IDEA in background to avoid blocking terminal
# Usage: idea [project-dir] [file-path]
idea() {
  if command -v idea >/dev/null 2>&1; then
    # Run IntelliJ IDEA in background, disown from shell
    # Preserve SSH agent and other important environment variables
    nohup env SSH_AUTH_SOCK="$SSH_AUTH_SOCK" SSH_AGENT_PID="$SSH_AGENT_PID" \
      GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" \
      command idea "$@" >/dev/null 2>&1 &
    disown %% 2>/dev/null || true
    echo "\033[0;32mIntelliJ IDEA started in background with SSH agent integration\033[0m"
  else
    echo "\033[0;31mIntelliJ IDEA not found. Please install it first.\033[0m"
    return 1
  fi
}

# SSH agent setup for GUI applications (including IntelliJ IDEA)
# Ensures GUI apps can access SSH agent for Git operations
setup_ssh_agent_for_gui() {
  if [[ -n "$SSH_AUTH_SOCK" && -S "$SSH_AUTH_SOCK" ]]; then
    # Set SSH agent variables for GUI applications
    launchctl setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null || true
    [[ -n "$SSH_AGENT_PID" ]] && launchctl setenv SSH_AGENT_PID "$SSH_AGENT_PID" 2>/dev/null || true
    echo "SSH agent configured for GUI applications"
  fi
}

# Setup SSH agent for GUI applications (IntelliJ IDEA, etc.)
setup_ssh_agent_for_gui
''
