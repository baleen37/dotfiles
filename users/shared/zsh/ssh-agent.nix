# 1Password SSH agent setup and SSH wrapper for Zsh
#
# Provides:
# - _setup_1password_agent(): detect and configure 1Password SSH agent
# - ssh-add key registration
# - ssh() wrapper with autossh fallback

{ isDarwin, lib }:

''
  # Optimized 1Password SSH agent detection with platform awareness
  _setup_1password_agent() {
    # Early exit if already configured
    [[ -n "$${SSH_AUTH_SOCK:-}" ]] && [[ -S "$SSH_AUTH_SOCK" ]] && return 0

    local socket_paths=()

    # Platform-specific socket detection
    ${lib.optionalString isDarwin ''
      # macOS: Check Group Containers efficiently
      for container in ~/Library/Group\ Containers/*.com.1password; do
        [[ -d "$container" ]] && socket_paths+=("$container/t/agent.sock")
      done 2>/dev/null
    ''}

    # Common cross-platform locations
    socket_paths+=(
      ~/.1password/agent.sock
      /tmp/1password-ssh-agent.sock
      ~/Library/Containers/com.1password.1password/Data/tmp/agent.sock
    )

    # Find first available socket
    for sock in "$${socket_paths[@]}"; do
      if [[ -S "$sock" ]]; then
        export SSH_AUTH_SOCK="$sock"
        return 0
      fi
    done

    return 1
  }

  _setup_1password_agent

  # Add SSH key to agent if not already registered
  if [[ -f ~/.ssh/id_ed25519 ]]; then
    ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf ~/.ssh/id_ed25519 2>/dev/null | awk '{print $2}')" \
      || ssh-add ~/.ssh/id_ed25519 2>/dev/null
  fi
''
