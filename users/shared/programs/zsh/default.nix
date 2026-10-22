# Zsh Shell Environment Configuration
#
# Features:
#   - fzf integration: Fuzzy finder with Ctrl+R (history), Ctrl+T (files), Alt+C (dirs)
#   - Powerlevel10k prompt: instant prompt, async git status
#   - 1Password SSH agent: Cross-platform socket auto-detection and connection
#   - PATH management: npm, pnpm, local bin directories auto-add
#   - Claude CLI integration:
#       - cc: Claude Code quick execution (skip permission checks)
#       - oc: OpenCode quick execution
#       - wt: Git worktree creation/switch
#   - SSH wrapper: Auto-reconnection support via autossh
#   - dotfiles auto-update: Background updates on shell startup
#
# Environment Variables:
#   - EDITOR/VISUAL: vim
#   - LANG/LC_ALL: en_US.UTF-8
#   - SSH_AUTH_SOCK: 1Password agent socket auto-setup
#

{
  inputs,
  pkgs,
  lib,
  config,
  isDarwin,
  ...
}:

let
  cfg = config.modules.programs.zsh;
  worktreePackage = pkgs.worktree;
  # Shell init scripts are generated at build time, so shell startup does not
  # fork each tool just to print the same script again.
  wtShellInit = pkgs.runCommand "wt-zsh-init" { } ''
    ${worktreePackage}/bin/wt config shell init zsh > $out
  '';
  zoxideShellInit = pkgs.runCommand "zoxide-zsh-init" { } ''
    ${pkgs.zoxide}/bin/zoxide init zsh > $out
  '';
  # `direnv-instant hook zsh` prints this file verbatim (include_str!).
  direnvInstantHook = "${inputs.direnv-instant}/hooks/zsh.sh";
in
{
  options.modules.programs.zsh.enable = lib.mkEnableOption "Zsh shell environment" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ worktreePackage ];

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;

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
      fileWidget = {
        command = "fd --type f --hidden --follow --exclude .git";
        options = [
          "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
        ];
      };

      # Directory search command (Alt+C)
      changeDirWidget = {
        command = "fd --type d --hidden --follow --exclude .git";
        options = [
          "--preview 'tree -C {} | head -200'"
        ];
      };
    };

    programs.zoxide = {
      enable = true;
      # Sourced from a build-time script in initContent below.
      enableZshIntegration = false;
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = false;
      nix-direnv.enable = true;
    };

    programs.direnv-instant = {
      enable = true;
      # Hooked up in initContent below, with a fast path outside .envrc trees.
      enableZshIntegration = false;
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
        vi = "nvim";
        vim = "nvim";

        # Multi-level directory navigation: `cd ...`, `cd ....` etc. is
        # handled by the cd function override in functions.nix.
        ".." = "cd ..";

        # Claude CLI shortcut is defined in initContent (cc)

        # OpenCode CLI shortcut
        oc = "opencode";

        # Codex CLI shortcut
        co = "codex --dangerously-bypass-approvals-and-sandbox";

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

      # After docker completion (1500) and powerlevel10k (1510); see powerlevel10k.nix.
      initContent = lib.mkOrder 1520 ''
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
        ${import ./claude-wrappers.nix { inherit isDarwin lib; }}
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
        ${import ./functions.nix { inherit isDarwin lib; }}

        # =============================================================================
        # Section: zoxide and direnv
        # =============================================================================
        source ${zoxideShellInit}

        # direnv-instant runs `direnv export` on every prompt, three processes
        # each time. Outside any .envrc tree with nothing loaded there is nothing
        # to export, so skip it there.
        typeset -g __DIRENV_INSTANT_HOOKED=1
        source ${direnvInstantHook}
        _direnv_hook_fast() {
          if [[ -z $DIRENV_DIR && -z $__DIRENV_INSTANT_CURRENT_DIR ]]; then
            local dir=$PWD
            until [[ -e $dir/.envrc ]]; do
              [[ $dir == / ]] && return
              dir=''${dir:h}
            done
          fi
          _direnv_hook
        }
        add-zsh-hook precmd _direnv_hook_fast
        add-zsh-hook chpwd _direnv_hook_fast
        add-zsh-hook zshexit _direnv_exit_cleanup
        _direnv_hook_fast

        # =============================================================================
        # Section: Git worktree wrapper
        # =============================================================================
        source ${wtShellInit}
        functions[_wt_generated]="$functions[wt]"
        wt() {
          local -a wt_original_path
          wt_original_path=("''${path[@]}")
          local -a path
          path=("${worktreePackage}/bin" "''${wt_original_path[@]}")
          _wt_generated "$@"
        }
      '';
    };
  };
}
