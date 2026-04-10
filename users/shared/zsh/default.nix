# Zsh Shell Environment Configuration
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
#       - gw: Git worktree creation/switch
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
  isDarwin,
  ...
}:

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

      # Codex CLI shortcut
      cx = "codex --dangerously-bypass-approvals-and-sandbox";

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
      ${import ./claude-wrappers.nix}
      # =============================================================================
      # Section: Environment and PATH setup
      # =============================================================================
      ${import ./env.nix}
      # Homebrew PATH configuration (macOS only)
      ${lib.optionalString isDarwin ''
        if [[ -d /opt/homebrew ]]; then
          export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        fi
      ''}

      # =============================================================================
      # Section: SSH agent setup
      # =============================================================================
      ${import ./ssh-agent.nix { inherit isDarwin lib; }}

      # =============================================================================
      # Section: Utility functions
      # =============================================================================
      ${import ./functions.nix}

      # =============================================================================
      # Section: Git worktree wrapper
      # =============================================================================
      ${import ./gw.nix}
    '';
  };
}
