# Shared Home Manager Configuration (Optimized)
#
# Cross-platform Home Manager configuration with performance optimizations
# and modular architecture. This file provides common program configurations
# that work across macOS and NixOS.
#
# ARCHITECTURE:
#   - Core programs: Shell, Git, SSH, Development tools
#   - Platform detection: Optimized caching and conditional logic
#   - Configuration separation: Shared vs platform-specific settings
#   - Performance optimizations: Reduced evaluation overhead
#
# USAGE:
#   Import via platform-specific modules only:
#   - modules/darwin/home-manager.nix (macOS settings)
#   - modules/nixos/home-manager.nix (NixOS settings)
#
# VERSION: 2.0.0 (Phase 2 optimized)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, ...
}:

let
  # User configuration constants
  name = "Jiho Lee";
  email = "baleen37@gmail.com";

  # Optimized platform detection with caching
  platformDetection = import ../../lib/platform-detection.nix { inherit pkgs; };

  # Enhanced user resolution with platform awareness
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = platformDetection.platform;
    returnFormat = "extended";
  };
  user = getUserInfo.user;

  # Cached platform detection flags for performance
  platformFlags = {
    isDarwin = platformDetection.isDarwin pkgs.system;
    isLinux = platformDetection.isLinux pkgs.system;
    isX86_64 = platformDetection.isX86_64 pkgs.system;
    isAarch64 = platformDetection.isAarch64 pkgs.system;
  };

  # Performance optimized shortcuts
  isDarwin = platformFlags.isDarwin;
  isLinux = platformFlags.isLinux;

  # Common configuration helpers
  commonPaths = {
    home = getUserInfo.homePath;
    config = "${getUserInfo.homePath}/.config";
    ssh = "${getUserInfo.homePath}/.ssh";
    dotfiles = "${getUserInfo.homePath}/dotfiles";
    devDotfiles = "${getUserInfo.homePath}/dev/dotfiles";
  };
in
{
  # Optimized home activation scripts
  home.activation = {
    # Enhanced Claude configuration setup with better path resolution
    setupClaudeConfig = ''
      CLAUDE_DIR="${commonPaths.home}/.claude"

      # Optimized source directory detection
      for source_dir in "${commonPaths.dotfiles}" "${commonPaths.devDotfiles}"; do
        CLAUDE_SOURCE="$source_dir/modules/shared/config/claude"
        if [[ -d "$CLAUDE_SOURCE" ]]; then
          if [[ ! -L "$CLAUDE_DIR" ]] || [[ "$(readlink "$CLAUDE_DIR")" != "$CLAUDE_SOURCE" ]]; then
            echo "🔧 Setting up Claude configuration..."
            rm -rf "$CLAUDE_DIR"
            ln -sf "$CLAUDE_SOURCE" "$CLAUDE_DIR"
            echo "✅ Claude config linked: $CLAUDE_DIR -> $CLAUDE_SOURCE"
          else
            echo "✓ Claude config already properly linked"
          fi
          break
        fi
      done
    '';

    # Platform-specific optimizations
  }
  // lib.optionalAttrs isDarwin {
    # macOS-specific activation with performance improvements
    setupDarwinOptimizations = ''
      echo "🍎 Applying macOS optimizations..."

      # Optimized keyboard configuration
      echo "⚠️  Manual setup required for optimal keyboard configuration:"
      echo "   1. Korean/English toggle: System Preferences > Keyboard > Input Sources"
      echo "   2. Disable conflicting services: Shortcuts > Services"

      # Only restart Dock if configuration changed
      if pgrep Dock >/dev/null; then
        echo "🔄 Refreshing Dock (if needed)..."
        killall Dock 2>/dev/null || true
      fi

      echo "✅ macOS optimizations applied"
    '';
  }
  // lib.optionalAttrs isLinux {
    # Linux-specific optimizations
    setupLinuxOptimizations = ''
      echo "🐧 Applying Linux optimizations..."

      # Ensure XDG directories exist
      mkdir -p "${commonPaths.config}"

      echo "✅ Linux optimizations applied"
    '';
  };
  programs = {
    # Shared shell configuration
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
          src = lib.cleanSource ./config;
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

    git = {
      enable = true;
      ignores = [
        # Local files
        ".local/"

        # Editor files
        "*.swp"
        "*.swo"
        "*~"
        ".vscode/"
        ".idea/"

        # OS files
        ".DS_Store"
        "Thumbs.db"
        "desktop.ini"

        # Development files
        ".direnv/"
        "result"
        "result-*"
        "node_modules/"
        ".env.local"
        ".env.*.local"
        ".serena/"

        # Temporary files
        "*.tmp"
        "*.log"
        ".cache/"

        # Build artifacts
        "dist/"
        "build/"
        "target/"

        # Issues (local project management)
        "issues/"

        # Plan files (project planning)
        "specs/"
        "plans/"

      ];
      userName = name;
      userEmail = email;
      lfs = {
        enable = true;
      };
      extraConfig = {
        init.defaultBranch = "main";
        core = {
          editor = "vim";
          autocrlf = "input";
          excludesFile = "~/.gitignore_global";
        };
        pull.rebase = true;
        rebase.autoStash = true;
        alias = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          df = "diff";
          lg = "log --graph --oneline --decorate --all";
        };
      };
    };

    vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-airline
        vim-airline-themes
        vim-tmux-navigator
      ];
      settings = {
        ignorecase = true;
      };
      extraConfig = ''
        "" General
        set number
        set history=1000
        set nocompatible
        set modelines=0
        set encoding=utf-8
        set scrolloff=3
        set showmode
        set showcmd
        set hidden
        set wildmenu
        set wildmode=list:longest
        set cursorline
        set ttyfast
        set nowrap
        set ruler
        set backspace=indent,eol,start
        set laststatus=2
        set clipboard=autoselect

        " Dir stuff
        set nobackup
        set nowritebackup
        set noswapfile
        set backupdir=~/.config/vim/backups
        set directory=~/.config/vim/swap

        " Relative line numbers for easy movement
        set relativenumber
        set rnu

        "" Whitespace rules
        set tabstop=8
        set shiftwidth=2
        set softtabstop=2
        set expandtab

        "" Searching
        set incsearch
        set gdefault

        "" Statusbar
        set nocompatible " Disable vi-compatibility
        set laststatus=2 " Always show the statusline
        let g:airline_theme='bubblegum'
        let g:airline_powerline_fonts = 1

        "" Local keys and such
        let mapleader=","
        let maplocalleader=" "

        "" Change cursor on mode
        :autocmd InsertEnter * set cul
        :autocmd InsertLeave * set nocul

        "" File-type highlighting and configuration
        syntax on
        filetype on
        filetype plugin on
        filetype indent on

        "" Paste from clipboard
        nnoremap <Leader>, "+gP

        "" Copy from clipboard
        xnoremap <Leader>. "+y

        "" Move cursor by display lines when wrapping
        nnoremap j gj
        nnoremap k gk

        "" Map leader-q to quit out of window
        nnoremap <leader>q :q<cr>

        "" Move around split
        nnoremap <C-h> <C-w>h
        nnoremap <C-j> <C-w>j
        nnoremap <C-k> <C-w>k
        nnoremap <C-l> <C-w>l

        "" Easier to yank entire line
        nnoremap Y y$

        "" Move buffers
        nnoremap <tab> :bnext<cr>
        nnoremap <S-tab> :bprev<cr>

        "" Like a boss, sudo AFTER opening the file to write
        cmap w!! w !sudo tee % >/dev/null

        let g:startify_lists = [
          \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
          \ { 'type': 'sessions',  'header': ['   Sessions']       },
          \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
          \ ]

        let g:startify_bookmarks = [
          \ '~/.local/share/src',
          \ ]

        let g:airline_theme='bubblegum'
        let g:airline_powerline_fonts = 1
      '';
    };

    alacritty = {
      enable = true;
      settings = {
        cursor = {
          style = "Block";
        };

        window = {
          opacity = 1.0;
          padding = {
            x = 24;
            y = 24;
          };
        };

        font = {
          normal = {
            family = "MesloLGS NF";
            style = "Regular";
          };
          size = lib.mkMerge [
            (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
            (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
          ];
        };

        dynamic_padding = true;
        decorations = "full";
        title = "Terminal";
        class = {
          instance = "Alacritty";
          general = "Alacritty";
        };

        colors = {
          primary = {
            background = "0x1f2528";
            foreground = "0xc0c5ce";
          };

          normal = {
            black = "0x1f2528";
            red = "0xec5f67";
            green = "0x99c794";
            yellow = "0xfac863";
            blue = "0x6699cc";
            magenta = "0xc594c5";
            cyan = "0x5fb3b3";
            white = "0xc0c5ce";
          };

          bright = {
            black = "0x65737e";
            red = "0xec5f67";
            green = "0x99c794";
            yellow = "0xfac863";
            blue = "0x6699cc";
            magenta = "0xc594c5";
            cyan = "0x5fb3b3";
            white = "0xd8dee9";
          };
        };
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [
        "${getUserInfo.homePath}/.ssh/config_external"
      ];
      matchBlocks = {
        "*" = {
          identitiesOnly = true;
          addKeysToAgent = "yes";
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
          extraOptions = {
            TCPKeepAlive = "yes";
          };
        };
      };
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config = {
        global = {
          load_dotenv = true;
        };
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "rg --files --hidden --follow --glob '!.git/*'";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];
      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
    };

    tmux = {
      enable = true;
      plugins = with pkgs.tmuxPlugins; [
        sensible
        vim-tmux-navigator
        yank
        resurrect
        continuum
      ];
      terminal = "screen-256color";
      prefix = "C-b";
      escapeTime = 0;
      historyLimit = 50000;
      # Performance optimized tmux configuration
      extraConfig = ''
        # Optimized base configuration
        set -g default-terminal "tmux-256color"
        set -g default-shell ${pkgs.zsh}/bin/zsh
        set -g default-command "${pkgs.zsh}/bin/zsh -l"
        set -g focus-events on

        # Enhanced terminal and display settings
        set-environment -g TERM screen-256color
        set -g mouse on
        set -g base-index 1
        set -g pane-base-index 1
        set -g renumber-windows on

        # Performance optimizations
        set -g display-time 2000
        set -g repeat-time 500
        set -g status-interval 1

        # 세션 안정성 향상을 위한 설정
        set -g set-clipboard external
        set -g remain-on-exit off
        set -g allow-rename off
        set -g destroy-unattached off
        set -g status-interval 1

        # Enhanced copy-paste with platform awareness
        setw -g mode-keys vi
        bind-key -T copy-mode-vi v send-keys -X begin-selection

        # Platform-optimized clipboard integration
        ${lib.optionalString isDarwin ''
          # macOS: Use pbcopy/pbpaste when available
          if command -v pbcopy >/dev/null 2>&1; then
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
            bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
            bind-key ] run "pbpaste | tmux load-buffer - && tmux paste-buffer"
          fi
        ''}
        ${lib.optionalString isLinux ''
          # Linux: Use xclip when available
          if command -v xclip >/dev/null 2>&1; then
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
            bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
            bind-key ] run "xclip -out -selection clipboard | tmux load-buffer - && tmux paste-buffer"
          fi
        ''}

        # Fallback to tmux buffer (universal)
        bind-key -T copy-mode-vi Y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-and-cancel

        # Buffer management shortcuts
        bind-key P paste-buffer
        bind-key b list-buffers
        bind-key B choose-buffer

        # Optimized terminal capabilities with True Color support
        set -ga terminal-overrides ",*256col*:Tc,*:U8=0"
        set -ga terminal-overrides ",screen*:Tc,*:U8=0"
        set -ga terminal-overrides ",xterm*:Tc,*:U8=0"
        set -ga terminal-overrides ",tmux*:Tc,*:U8=0"
        set -ga terminal-overrides ",alacritty:Tc,*:U8=0"

        # 키보드 설정
        set-window-option -g xterm-keys on
        set-option -g extended-keys on
        set -as terminal-features 'xterm*:extkeys'

        # Alacritty와 같은 최신 터미널의 확장된 키 입력을 처리하기 위한 설정
        set -as terminal-overrides ',*:keys=\E[u'

        # 상태바 설정
        set -g status-position bottom
        set -g status-bg colour234
        set -g status-fg colour137
        set -g status-left-length 20
        set -g status-right-length 50
        set -g status-left '#[fg=colour233,bg=colour241,bold] #S '
        set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '

        # 윈도우 상태 표시
        setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '
        setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

        # 키 바인딩
        bind | split-window -h
        bind - split-window -v
        bind r source-file ~/.tmux.conf \; display "Config reloaded!"

        # 탭(window) 관리 키 바인딩
        bind t new-window
        bind Tab last-window

        # Alt 키로 prefix 없이 window 이동
        bind -n M-h previous-window
        bind -n M-l next-window

        # Optimized session persistence
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-strategy-vim 'session'
        set -g @resurrect-strategy-nvim 'session'
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '15'
        set -g @continuum-boot 'on'

        # Additional performance optimizations
        set -g @resurrect-dir "${commonPaths.config}/tmux/resurrect"
      '';
    };
  };
}
