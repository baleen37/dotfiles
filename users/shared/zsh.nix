# Zsh Shell Environment Configuration
#
# Extracted from modules/shared/programs/zsh/default.nix
#
# Features:
#   - fzf integration: Fuzzy finder with Ctrl+R (history), Ctrl+T (files), Alt+C (dirs)
#   - Starship prompt: Fast, minimal, cross-shell prompt
#   - 1Password SSH agent: Cross-platform socket auto-detection and connection
#   - PATH management: npm, pnpm, local bin directories auto-add
#   - IntelliJ IDEA launcher: Cross-platform installation path auto-detection
#   - Claude CLI integration:
#       - cc: Claude Code quick execution (skip permission checks)
#       - cco: Claude Code via OpenAI-compatible proxy
#       - ccz: Claude Code via Z.ai GLM API
#       - oc: OpenCode quick execution
#       - gw: Git worktree creation/switch + AI tool execution (cc/cco/ccz/oc)
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
  inherit (pkgs.stdenv) isDarwin isLinux;
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

  # Direnv auto-allow configuration
  # Automatically trust all .envrc files in the user's home directory
  # This eliminates the need to manually run `direnv allow` for each project
  xdg.configFile."direnv/direnv.toml".text = ''
    [whitelist]
    prefix = [ "${config.home.homeDirectory}/" ]
  '';

  programs.zsh = {
    enable = true;
    autocd = false;
    dotDir = config.home.homeDirectory;

    # Skip compaudit security checks for 40x faster startup (2.3s -> 0.06s)
    # Safe in Nix environment where all paths are immutable
    enableCompletion = true;
    completionInit = "autoload -Uz compinit && compinit -C";

    shellAliases = {
      # Multi-level directory navigation
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "......" = "cd ../../../../..";

      # Claude CLI shortcuts are now functions in initContent (cc, cco, ccz)

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

    plugins = [ ];

    initContent = lib.mkAfter ''
      # =============================================================================
      # Section: Nix daemon initialization
      # =============================================================================
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Local overrides (not tracked in git)
      if [[ -f ~/.zshrc.local ]]; then
        . ~/.zshrc.local
      fi

      # =============================================================================
      # Section: Claude Code wrapper functions
      # =============================================================================
      #   cc/cc-h/cc-l:   Anthropic API (sonnet/opus/haiku)
      #   cco/cco-h/cco-l: OpenAI-compatible proxy
      #   ccz/ccz-h/ccz-l: Z.ai GLM API
      #   cck:            Kimi API via OpenAI-compatible proxy
      # Configure cco/ccz/cck models in ~/.zshrc.local

      # Internal helper - do not call directly
      _cc_run() {
        local model="$1"; shift
        if [[ -n "$model" ]]; then
          command claude --dangerously-skip-permissions --model "$model" "$@"
        else
          command claude --dangerously-skip-permissions "$@"
        fi
      }

      # Parse -h/--high and -l/--low model flags
      # Usage: local parsed=$(_cc_parse_model_flags <default> <high> <low> "$@")
      # Outputs "<consumed>|<model>" to stdout
      _cc_parse_model_flags() {
        local default_model="$1"
        local high_model="$2"
        local low_model="$3"
        shift 3
        local model="$default_model"
        local consumed=0

        while [[ $# -gt 0 ]]; do
          case "$1" in
            -h|--high)
              model="$high_model"
              shift
              consumed=$((consumed + 1))
              ;;
            -l|--low)
              model="$low_model"
              shift
              consumed=$((consumed + 1))
              ;;
            --)
              shift
              consumed=$((consumed + 1))
              break
              ;;
            -*)
              break
              ;;
            *)
              break
              ;;
          esac
        done

        echo "$consumed|$model"
      }

      cc() {
        local parsed=$(_cc_parse_model_flags "" "opus" "haiku" "$@")
        local consumed="''${parsed%%|*}"
        local model="''${parsed#*|}"
        shift "$consumed"
        _cc_run "$model" "$@"
      }

      # cco: Configure in ~/.zshrc.local:
      #   CCO_BASE_URL, CCO_AUTH_TOKEN
      #   CCO_OPUS_MODEL, CCO_SONNET_MODEL, CCO_HAIKU_MODEL
      _cco_run() {
        local model="$1"; shift
        ANTHROPIC_BASE_URL="''${CCO_BASE_URL:-http://127.0.0.1:8317}" \
        ANTHROPIC_AUTH_TOKEN="''${CCO_AUTH_TOKEN:-sk-dummy}" \
        ANTHROPIC_DEFAULT_OPUS_MODEL="''${CCO_OPUS_MODEL:-}" \
        ANTHROPIC_DEFAULT_SONNET_MODEL="''${CCO_SONNET_MODEL:-}" \
        ANTHROPIC_DEFAULT_HAIKU_MODEL="''${CCO_HAIKU_MODEL:-}" \
        _cc_run "$model" "$@"
      }

      cco() {
        local parsed=$(_cc_parse_model_flags "''${CCO_SONNET_MODEL:?Set CCO_SONNET_MODEL in ~/.zshrc.local}" "''${CCO_OPUS_MODEL:?Set CCO_OPUS_MODEL in ~/.zshrc.local}" "''${CCO_HAIKU_MODEL:?Set CCO_HAIKU_MODEL in ~/.zshrc.local}" "$@")
        local consumed="''${parsed%%|*}"
        local model="''${parsed#*|}"
        shift "$consumed"
        _cco_run "$model" "$@"
      }

      # ccz: Configure in ~/.zshrc.local:
      #   CCZ_TOKEN, CCZ_HAIKU_MODEL, CCZ_SONNET_MODEL, CCZ_OPUS_MODEL
      _ccz_run() {
        local model="$1"; shift
        ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
        ANTHROPIC_AUTH_TOKEN="''${CCZ_TOKEN:-}" \
        ANTHROPIC_DEFAULT_HAIKU_MODEL="''${CCZ_HAIKU_MODEL:-}" \
        ANTHROPIC_DEFAULT_SONNET_MODEL="''${CCZ_SONNET_MODEL:-}" \
        ANTHROPIC_DEFAULT_OPUS_MODEL="''${CCZ_OPUS_MODEL:-}" \
        _cc_run "$model" "$@"
      }

      ccz() {
        local parsed=$(_cc_parse_model_flags "''${CCZ_SONNET_MODEL:?Set CCZ_SONNET_MODEL in ~/.zshrc.local}" "''${CCZ_OPUS_MODEL:?Set CCZ_OPUS_MODEL in ~/.zshrc.local}" "''${CCZ_HAIKU_MODEL:?Set CCZ_HAIKU_MODEL in ~/.zshrc.local}" "$@")
        local consumed="''${parsed%%|*}"
        local model="''${parsed#*|}"
        shift "$consumed"
        _ccz_run "$model" "$@"
      }

      # cck: Kimi API via OpenAI-compatible proxy
      # Configure in ~/.zshrc.local:
      #   CCK_BASE_URL, CCK_AUTH_TOKEN
      #   CCK_HIGH_MODEL, CCK_LOW_MODEL
      _cck_run() {
        local model="$1"; shift
        ANTHROPIC_BASE_URL="''${CCK_BASE_URL:-http://127.0.0.1:8317}" \
        ANTHROPIC_AUTH_TOKEN="''${CCK_AUTH_TOKEN:-sk-dummy}" \
        _cc_run "$model" "$@"
      }

      cck() {
        local parsed=$(_cc_parse_model_flags "''${CCK_MED_MODEL:-kimi-k2.5}" "''${CCK_HIGH_MODEL:-kimi-k2-thinking}" "''${CCK_LOW_MODEL:-kimi-k2}" "$@")
        local consumed="''${parsed%%|*}"
        local model="''${parsed#*|}"
        shift "$consumed"
        _cck_run "$model" "$@"
      }

      # =============================================================================
      # Section: Environment and PATH setup
      # =============================================================================
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

      # npm configuration
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"

      # GitHub CLI token
      export GITHUB_TOKEN=$(gh auth token)

      # =============================================================================
      # Section: SSH agent setup
      # =============================================================================
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

      # =============================================================================
      # Section: Utility functions
      # =============================================================================
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

      # =============================================================================
      # Section: Git worktree wrapper
      # =============================================================================
      # Build Claude environment prefix for gw() function
      # Usage: _gw_build_claude_env <base_url> <auth_token> [opus_model] [sonnet_model] [haiku_model]
      # Outputs: Complete environment prefix string for eval
      _gw_build_claude_env() {
        local base_url="$1"
        local auth_token="$2"
        local opus_model="''${3:-}"
        local sonnet_model="''${4:-}"
        local haiku_model="''${5:-}"

        local env_prefix="ANTHROPIC_BASE_URL=\"$base_url\" ANTHROPIC_AUTH_TOKEN=\"$auth_token\""

        [[ -n "$opus_model" ]] && env_prefix="$env_prefix ANTHROPIC_DEFAULT_OPUS_MODEL=\"$opus_model\""
        [[ -n "$sonnet_model" ]] && env_prefix="$env_prefix ANTHROPIC_DEFAULT_SONNET_MODEL=\"$sonnet_model\""
        [[ -n "$haiku_model" ]] && env_prefix="$env_prefix ANTHROPIC_DEFAULT_HAIKU_MODEL=\"$haiku_model\""

        echo "$env_prefix command claude --dangerously-skip-permissions"
      }

      # Git Worktree wrapper - Create git worktree and launch AI tool
      # Usage: gw <branch-name> [subcmd]
      #   subcmd: cc (default), ccz, oc
      gw() {
        local branch_name="$1"
        local subcmd="''${2:-cc}"

        # Validate arguments
        if [[ $# -eq 0 ]]; then
          echo "Usage: gw <branch-name> [subcmd]"
          echo "  subcmd: cc (default), cco, ccz, cck, oc"
          return 1
        fi

        # Validate subcmd early
        case "$subcmd" in
          cc|cco|ccz|cck|oc)
            ;;
          *)
            echo "Error: Unknown subcmd '$subcmd'. Use: cc, cco, ccz, cck, or oc" >&2
            return 1
            ;;
        esac

        # Map subcmd to tool command
        local tool_command
        case "$subcmd" in
          cc)
            tool_command="claude --dangerously-skip-permissions"
            ;;
          cco)
            tool_command=$(_gw_build_claude_env \
              "''${CCO_BASE_URL:-http://127.0.0.1:8317}" \
              "''${CCO_AUTH_TOKEN:-sk-dummy}" \
              "''${CCO_OPUS_MODEL:-}" \
              "''${CCO_SONNET_MODEL:-}" \
              "''${CCO_HAIKU_MODEL:-}")
            ;;
          ccz)
            tool_command=$(_gw_build_claude_env \
              "https://api.z.ai/api/anthropic" \
              "''${CCZ_TOKEN:-}" \
              "''${CCZ_OPUS_MODEL:-}" \
              "''${CCZ_SONNET_MODEL:-}" \
              "''${CCZ_HAIKU_MODEL:-}")
            ;;
          cck)
            tool_command=$(_gw_build_claude_env \
              "''${CCK_BASE_URL:-http://127.0.0.1:8317}" \
              "''${CCK_AUTH_TOKEN:-sk-dummy}")
            ;;
          oc)
            tool_command="opencode"
            ;;
        esac

        # ANSI color codes
        local RED='\033[0;31m'
        local GREEN='\033[0;32m'
        local YELLOW='\033[0;33m'
        local BLUE='\033[0;34m'
        local RESET='\033[0m'

        # Helper: Print colored message to stderr (so command substitution doesn't capture it)
        local _msg() {
          local color="$1"
          shift
          echo "''${color}$*''${RESET}" >&2
        }

        # Helper: Print error and exit
        local _error() {
          _msg "$RED" "$@"
          return 1
        }

        # Helper: Sanitize branch name for directory (replace / with -)
        local _sanitize_branch() {
          echo ".worktrees/''${1//\//-}"
        }

        # Helper: Find base branch (main or master)
        local _find_base_branch() {
          if git rev-parse --verify main >/dev/null 2>&1; then
            echo "main"
          elif git rev-parse --verify master >/dev/null 2>&1; then
            echo "master"
          else
            return 1
          fi
        }

        # Helper: Check if worktree directory exists
        local _check_worktree_exists() {
          if [[ -d "$1" ]]; then
            _error "Worktree already exists: $1"
            return 1
          fi
          return 0
        }

        # Helper: Create worktree with existing or new branch
        # Outputs error messages to stderr on failure, returns exit code
        local _create_worktree() {
          local branch="$1"
          local worktree_dir="$2"
          local base_branch="$3"
          local error_output

          if git rev-parse --verify "$branch" >/dev/null 2>&1; then
            _msg "$BLUE" "Branch '$branch' already exists. Using existing branch."
            error_output=$(git worktree add "$worktree_dir" "$branch" 2>&1)
          else
            _msg "$GREEN" "Creating new branch '$branch' (base: $base_branch)"
            error_output=$(git worktree add -b "$branch" "$worktree_dir" "$base_branch" 2>&1)
          fi

          local result=$?
          if [[ $result -ne 0 ]]; then
            echo "$error_output" >&2
          fi
          return $result
        }

        # Helper: Handle hierarchical branch conflicts
        local _handle_ref_conflict() {
          local branch="$1"
          local error_output="$2"

          if ! echo "$error_output" | grep -q "cannot lock ref"; then
            return 1
          fi

          local existing_branch=$(git branch --list | grep -E "^\s+$branch/" | head -1 | sed 's/^[* ]*//')
          if [[ -z "$existing_branch" ]]; then
            return 1
          fi

          _msg "$YELLOW" "Branch '$branch' conflicts with existing branch '$existing_branch'"
          _msg "$BLUE" "Using existing branch: $existing_branch"
          echo "$existing_branch"
          return 0
        }

        # Main logic
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
          _error "Not a git repository"
          return 1
        fi

        local worktree_dir=$(_sanitize_branch "$branch_name")

        _check_worktree_exists "$worktree_dir" || return 1

        local base_branch=$(_find_base_branch)
        if [[ -z "$base_branch" ]]; then
          _error "No main or master branch found"
          return 1
        fi

        local create_error
        if ! create_error=$(_create_worktree "$branch_name" "$worktree_dir" "$base_branch"); then
          # Try to handle hierarchical ref conflict
          local resolved_branch=$(_handle_ref_conflict "$branch_name" "$create_error")
          if [[ -n "$resolved_branch" ]]; then
            worktree_dir=$(_sanitize_branch "$resolved_branch")
            _check_worktree_exists "$worktree_dir" || return 1

            if ! git worktree add "$worktree_dir" "$resolved_branch" >/dev/null 2>&1; then
              _error "Failed to create worktree"
              return 1
            fi
          else
            _error "Failed to create worktree"
            echo "$create_error" >&2
            return 1
          fi
        fi

        _msg "$GREEN" "Worktree created: $worktree_dir"
        cd "$worktree_dir" && eval "$tool_command"
      }
    '';
  };
}
