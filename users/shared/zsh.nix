# Zsh Shell Environment Configuration
#
# Extracted from modules/shared/programs/zsh/default.nix
#
# Features:
#   - fzf integration: Fuzzy finder with Ctrl+R (history), Ctrl+T (files), Alt+C (dirs)
#   - Powerlevel10k theme: Advanced prompt theme and configuration
#   - 1Password SSH agent: Cross-platform socket auto-detection and connection
#   - PATH management: npm, pnpm, local bin directories auto-add
#   - IntelliJ IDEA launcher: Cross-platform installation path auto-detection
#   - Claude CLI integration:
#       - cc: Claude Code quick execution (skip permission checks)
#       - ccw: Git worktree creation/switch + Claude execution
#   - SSH wrapper: Auto-reconnection support via autossh
#   - dotfiles auto-update: Background updates on shell startup
#
# Environment Variables:
#   - EDITOR/VISUAL: vim
#   - LANG/LC_ALL: en_US.UTF-8
#   - SSH_AUTH_SOCK: 1Password agent socket auto-setup
#

{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin;
  inherit (pkgs.stdenv) isLinux;
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Default options for better UX
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
      "--preview-window 'right:50%:wrap'"
      "--bind 'ctrl-/:toggle-preview'"
      "--color=fg:#d0d0d0,bg:#121212,hl:#5f87af"
      "--color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff"
      "--color=info:#afaf87,prompt:#d7005f,pointer:#af5fff"
      "--color=marker:#87ff00,spinner:#af5fff,header:#87afaf"
    ];

    # File search command (Ctrl+T)
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    ];

    # Directory search command (Alt+C)
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'tree -C {} | head -200'"
    ];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
    autocd = false;

    # Skip compaudit security checks for 40x faster startup (2.3s -> 0.06s)
    # Safe in Nix environment where all paths are immutable
    enableCompletion = true;
    completionInit = "autoload -Uz compinit && compinit -C";

    shellAliases = {
      # Claude CLI shortcut
      cc = "claude --dangerously-skip-permissions";

      # OpenCode CLI shortcut
      oc = "opencode";

      # Git aliases
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";

      # Use difftastic for syntax-aware diffing
      diff = "difft";

      # Always color ls and group directories
      ls = "ls --color=auto";

      la = "ls -la --color=auto";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = lib.mkAfter ''
      # Nix daemon initialization
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # PATH configuration - Global package managers
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$HOME/.local/bin:$PATH
      # Cargo (Rust)
      export PATH=$HOME/.cargo/bin:$PATH
      # Go
      export PATH=$HOME/go/bin:$PATH
      # Gem (Ruby) - only if GEM_HOME is set to user directory
      if [[ -n "$GEM_HOME" ]]; then
        export PATH=$GEM_HOME/bin:$PATH
      fi

      # Homebrew PATH configuration (macOS only)
      ${lib.optionalString isDarwin ''
        if [[ -d /opt/homebrew ]]; then
          export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        fi
      ''}

      # History configuration
      export HISTIGNORE="pwd:ls:cd"

      # Locale settings for UTF-8 support
      export LANG="en_US.UTF-8"
      export LC_ALL="en_US.UTF-8"

      # Editor preferences
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

      # Setup SSH agent for GUI applications (IntelliJ IDEA, etc.)
      setup_ssh_agent_for_gui

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
          echo "✨ IntelliJ IDEA started in background with SSH agent integration"
        else
          echo "❌ IntelliJ IDEA not found. Please install it first."
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
          echo "✅ SSH agent configured for GUI applications"
        fi
      }

      # Claude Code Worktree - Create git worktree and launch Claude Code
      # Usage: ccw <branch-name>
      ccw() {
        # Validate input
        if [[ $# -eq 0 ]]; then
          echo "Usage: ccw <branch-name>"
          return 1
        fi

        local branch_name="$1"

        # Check if in a git repository
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
          echo "❌ Not a git repository"
          return 1
        fi

        # Sanitize branch name: replace slashes with hyphens
        local worktree_dir=".worktrees/$${branch_name//\//-}"

        # Check if worktree directory already exists
        if [[ -d "$worktree_dir" ]]; then
          echo "❌ Worktree already exists: $worktree_dir"
          return 1
        fi

        # Find base branch (main or master)
        local base_branch
        if git rev-parse --verify main >/dev/null 2>&1; then
          base_branch="main"
        elif git rev-parse --verify master >/dev/null 2>&1; then
          base_branch="master"
        else
          echo "❌ No main or master branch found"
          return 1
        fi

        # Create worktree
        if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
          # Branch exists - create worktree from existing branch
          git worktree add "$worktree_dir" "$branch_name"
        else
          # Branch doesn't exist - create new branch from base
          git worktree add -b "$branch_name" "$worktree_dir" "$base_branch"
        fi

        # If worktree creation succeeded, navigate and launch Claude Code
        if [[ $? -eq 0 ]]; then
          echo "✅ Worktree created: $worktree_dir"
          cd "$worktree_dir" && cc
        else
          echo "❌ Failed to create worktree"
          return 1
        fi
      }
    '';
  };
}
