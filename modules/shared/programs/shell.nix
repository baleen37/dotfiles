# Shell Environment Configuration
#
# Zsh configuration with optimized startup and cross-platform compatibility.
# Extracted from programs.nix following single responsibility principle.
#
# FEATURES:
#   - Powerlevel10k theme with configuration
#   - Optimized 1Password SSH agent detection
#   - Platform-aware PATH and environment setup
#   - IntelliJ IDEA launcher with intelligent detection
#   - Claude CLI shortcuts and git worktree integration
#   - Enhanced SSH wrapper with autossh fallback
#
# ARCHITECTURE:
#   - Single responsibility: Only shell/zsh configuration
#   - Cross-platform: macOS and Linux compatibility
#   - Performance optimized: Cached platform detection
#
# VERSION: 3.0.0 (Extracted from programs.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

let
  inherit (platformInfo) isDarwin isLinux;
  inherit (userInfo) name email;
in
{
  programs = {
    zsh = {
      enable = true;
      autocd = false;
      shellAliases = {
        cc = "claude --dangerously-skip-permissions";
      };
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = lib.cleanSource ../config;
          file = "p10k.zsh";
        }
      ];

      initContent = lib.mkAfter ''
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        # Define variables for directories
        export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
        export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
        export PATH=$HOME/.local/share/bin:$PATH
        export PATH=$HOME/.local/bin:$PATH

        # Remove history data we don't want to see
        export HISTIGNORE="pwd:ls:cd"

        # Set locale for proper UTF-8 support
        export LANG="en_US.UTF-8"
        export LC_ALL="en_US.UTF-8"

        export EDITOR="vim"
        export VISUAL="vim"

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

        # nix shortcuts
        shell() {
            nix-shell '<nixpkgs>' -A "$1"
        }

        # Use difftastic, syntax-aware diffing
        alias diff=difft

        # Always color ls and group directories
        alias ls='ls --color=auto'

        # Auto-update dotfiles on shell startup (with TTL)
        if [[ -x "$HOME/dotfiles/scripts/auto-update-dotfiles" ]]; then
          (nohup "$HOME/dotfiles/scripts/auto-update-dotfiles" --silent &>/dev/null &)
        fi

        # Claude-monitor is now managed via Nix packages

        # Optimized IntelliJ IDEA launcher with platform detection
        idea() {
          # Cached command resolution for performance
          local idea_cmd=""
          local search_paths=()

          # Build platform-specific search paths
          search_paths+=("intellij-idea-ultimate" "intellij-idea-community")

          ${lib.optionalString isDarwin ''
            search_paths+=("/opt/homebrew/bin/idea" "/Applications/IntelliJ IDEA Ultimate.app/Contents/MacOS/idea")
          ''}
          ${lib.optionalString isLinux ''
            search_paths+=("/home/linuxbrew/.linuxbrew/bin/idea" "/usr/local/bin/idea")
          ''}

          # Find first available IDEA installation
          for cmd in "$${search_paths[@]}"; do
            if command -v "$cmd" >/dev/null 2>&1; then
              idea_cmd="$cmd"
              break
            elif [[ -x "$cmd" ]]; then
              idea_cmd="$cmd"
              break
            fi
          done

          if [[ -z "$idea_cmd" ]]; then
            echo "❌ IntelliJ IDEA not found. Install options:"
            echo "   • Nix: nix-env -iA nixpkgs.jetbrains.idea-ultimate"
            ${lib.optionalString isDarwin ''echo "   • Homebrew: brew install --cask intellij-idea"''}
            ${lib.optionalString isLinux ''echo "   • Package manager or direct download"''}
            return 1
          fi

          # Launch with proper background handling
          echo "🚀 Starting IntelliJ IDEA: $idea_cmd"
          nohup "$idea_cmd" "$@" >/dev/null 2>&1 & disown
        }

        # Claude CLI shortcuts
        # Note: 'cc' alias may conflict with system C compiler. Use '\cc' to access system cc if needed.
        alias cc="claude --dangerously-skip-permissions"

        # Claude CLI with Git Worktree workflow
        ccw() {
          local branch_name="$1"

          if [[ -z "$branch_name" ]]; then
            echo "Usage: ccw <branch-name>"
            echo "Creates/switches to git worktree at ../<branch-name> and starts Claude"
            return 1
          fi

          if ! git rev-parse --git-dir >/dev/null 2>&1; then
            echo "Error: Not in a git repository"
            return 1
          fi

          local worktree_path="../$branch_name"

          if [[ -d "$worktree_path" ]]; then
            echo "Switching to existing worktree: $worktree_path"
            cd "$worktree_path"
          else
            echo "Creating new git worktree for branch '$branch_name'..."

            if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
              git worktree add "$worktree_path" "origin/$branch_name"
            else
              git worktree add -b "$branch_name" "$worktree_path"
            fi

            cd "$worktree_path"
          fi

          echo "Worktree: $(pwd) | Branch: $(git branch --show-current)"
          cc
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
      '';
    };
  };
}
