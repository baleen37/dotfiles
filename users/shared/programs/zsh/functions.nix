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
# installs its own ssh() to use xterm-256color for remote hosts; wrapping ssh
# here would shadow that. Keepalive options live in ~/.ssh/config
# (programs.ssh module).

''
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
  # uses xterm-256color on the remote — don't shadow it.
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
    # Show and remove regenerable macOS development caches.
    bgc() {
      local mode="''${1:-cleanup}"

      bgc_usage() {
        print "Usage: bgc [stats|--dry-run|help]"
        print "  bgc stats     Show cache sizes"
        print "  bgc --dry-run Show sizes and cleanup commands without deleting"
      }

      bgc_size() {
        local label="$1"
        local path="$2"
        if [[ -e "$path" ]]; then
          du -sh "$path" 2>/dev/null | awk -v label="$label" '{ print label ": " $1 }'
        else
          print "$label: 0B"
        fi
      }

      bgc_stats() {
        print "Cache sizes:"
        bgc_size "Homebrew" "''${HOMEBREW_CACHE:-$HOME/Library/Caches/Homebrew}"
        bgc_size "Nix store (total)" "/nix/store"
        bgc_size "npm" "$HOME/.npm"
        bgc_size "pnpm" "$HOME/Library/pnpm/store"
        bgc_size "Yarn" "$HOME/Library/Caches/Yarn"
        bgc_size "uv" "$HOME/.cache/uv"
        bgc_size "pip" "$HOME/Library/Caches/pip"
        bgc_size "Gradle" "$HOME/.gradle/caches"
        bgc_size "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"
        bgc_size "Library/Caches" "$HOME/Library/Caches"
      }

      bgc_cleanup() {
        print "Cleaning development caches..."
        command -v brew >/dev/null 2>&1 && brew cleanup || true
        command -v nix >/dev/null 2>&1 && nix store gc || true
        command -v npm >/dev/null 2>&1 && npm cache clean --force || true
        command -v pnpm >/dev/null 2>&1 && pnpm store prune || true
        command -v yarn >/dev/null 2>&1 && yarn cache clean || true
        command -v uv >/dev/null 2>&1 && uv cache clean || true
        command -v pip >/dev/null 2>&1 && pip cache purge || true
        [[ -d "$HOME/.gradle/caches" ]] && rm -rf "$HOME/.gradle/caches"
        [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]] && rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/*
        [[ -d "$HOME/Library/Caches" ]] && find "$HOME/Library/Caches" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
      }

      bgc_docker_cleanup() {
        if ! command -v docker >/dev/null 2>&1; then
          print "Docker: not installed, skipped"
          return 0
        fi
        print "Docker cleanup removes stopped containers, dangling images, and build cache."
        print "Docker cleanup does not remove named volumes or running containers."
        read -q "REPLY?Run Docker cleanup? [y/N] "
        print
        [[ "$REPLY" == [yY] ]] || { print "Docker cleanup skipped"; return 0; }
        docker container prune
        docker image prune
        docker builder prune
      }

      case "$mode" in
        stats)
          bgc_stats
          ;;
        --dry-run)
          bgc_stats
          print ""
          print "Would run: brew cleanup, nix store gc, npm/pnpm/yarn/uv/pip cache cleanup"
          print "Would remove: Gradle caches, Xcode DerivedData, and ~/Library/Caches contents"
          print "Would ask separately: Docker cleanup"
          ;;
        help)
          bgc_usage
          ;;
        cleanup)
          bgc_stats
          print ""
          read -q "REPLY?Clean development caches? [y/N] "
          print
          if [[ "$REPLY" == [yY] ]]; then
            bgc_cleanup
          else
            print "Development cache cleanup skipped"
          fi
          bgc_docker_cleanup
          ;;
        *)
          bgc_usage >&2
        return 2
          ;;
      esac
    }
  ''}
''
