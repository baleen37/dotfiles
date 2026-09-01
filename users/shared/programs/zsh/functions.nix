{ isDarwin, lib }:

# Utility shell functions for Zsh
#
# Provides:
# - shell(): quick nix-shell access
# - cd(): multi-dot cd shortcut
# - assh: autossh alias for long-lived connections
# - setup_ssh_agent_for_gui(): SSH agent for GUI apps
#
# Note: ssh() is intentionally NOT overridden. Ghostty's shell integration
# installs its own ssh() that ships xterm-ghostty terminfo to remote hosts
# (ssh-terminfo); wrapping ssh here would shadow that. Keepalive options live
# in ~/.ssh/config (programs.ssh module).

''
  # Clear input modes left behind when a remote full-screen app exits without
  # cleanup (for example, after an SSH connection reset).
  #
  # Mouse tracking: \e[?1000l..\e[?1015l
  # Kitty keyboard protocol: \e[<u pops the flag stack, and \e[0;3u resets the
  #   flags outright (mode 3 = reset bits) because a crashed program may never
  #   have pushed, leaving nothing to pop. Without this the terminal keeps
  #   reporting keys as escape sequences and typing emits stray `1;1:3u`.
  # Bracketed paste: \e[?2004l
  #
  # term = xterm-ghostty is the actual fix; this hook is the safety net for
  # remote programs that still exit uncleanly.
  _reset_terminal_input_modes() {
    [[ -t 1 ]] || return 0
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1015l\e[<u\e[0;3u\e[?2004l'
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _reset_terminal_input_modes

  # nix shortcuts
  shell() {
      nix-shell '<nixpkgs>' -A "$1"
  }

  # Multi-dot cd: `cd ...` -> `cd ../..`, `cd ....` -> `cd ../../..`, etc.
  # Implemented as a function override (not a ZLE widget) so the typed form
  # (`cd ...`) is preserved in shell history instead of being rewritten.
  cd() {
    if [[ $# -eq 1 && "$1" =~ "^\.{3,}$" ]]; then
      local dots="$1"
      local target=""
      local i
      for (( i = 1; i < ''${#dots}; i++ )); do
        target+="../"
      done
      builtin cd "$target"
    else
      builtin cd "$@"
    fi
  }

  # autossh for long-lived connections that need auto-reconnect.
  # Plain `ssh` goes through Ghostty's shell-integration wrapper which
  # installs xterm-ghostty terminfo on the remote — don't shadow it.
  alias assh='AUTOSSH_POLL=60 AUTOSSH_FIRST_POLL=30 autossh -M 0 -o ServerAliveInterval=30 -o ServerAliveCountMax=3'

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

  ${lib.optionalString isDarwin ''
    # Compatibility name for the former macOS-only cache command.
    bgc() {
      bl gc "$@"
    }
  ''}
''
