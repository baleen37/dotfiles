# Shared Home Manager Programs Configuration
#
# IMPORTANT: This file contains ONLY truly cross-platform configurations.
# Platform-specific settings should be added in:
# - modules/darwin/home-manager.nix (macOS-specific)
# - modules/nixos/home-manager.nix (NixOS-specific)
#
# DO NOT import this file directly at system level - it should only be
# imported within Home Manager context via platform-specific modules.
#
# GUARD: This file should only be imported within Home Manager context
# If you see evaluation errors, check that this file is not being imported
# directly in system configuration (hosts/*/default.nix)

{
  config,
  pkgs,
  lib,
  ...
}:

let
  name = "Jiho Lee";

  # Import optimized platform detection utilities
  platformDetection = import ../../lib/platform-detection.nix { inherit pkgs; };

  getUserInfo = import ../../lib/user-resolution.nix {
    platform = platformDetection.platform;
    returnFormat = "extended";
  };
  user = getUserInfo.user;
  email = "baleen37@gmail.com";

  # Platform detection for conditional configurations (now using optimized detection)
  isDarwin = platformDetection.isDarwin pkgs.system;
  isLinux = platformDetection.isLinux pkgs.system;
in
{
  # Home activation scripts
  home.activation = {
    # Simple Claude .claude directory symlink
    setupClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_DIR="$HOME/.claude"
      SOURCE_DIR="$HOME/dotfiles/modules/shared/config/claude"

      if [[ ! -d "$SOURCE_DIR" ]]; then
        SOURCE_DIR="$HOME/dev/dotfiles/modules/shared/config/claude"
      fi

      if [[ -d "$SOURCE_DIR" ]]; then
        mkdir -p "$HOME"
        rm -rf "$CLAUDE_DIR"
        ln -sf "$SOURCE_DIR" "$CLAUDE_DIR"
        echo "✓ Claude config linked: $CLAUDE_DIR -> $SOURCE_DIR"
      fi
    '';
  }
  // lib.optionalAttrs isDarwin {
    setupKeyboardInput = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting up keyboard input configuration..."

      # 한영키 전환을 Shift+Cmd+Space로 설정
      # Note: 복잡한 nested dictionary는 macOS에서 지원되지 않아 비활성화
      echo "⚠️  Keyboard shortcut configuration skipped (requires manual setup)"
      echo "   To set Korean/English toggle to Shift+Cmd+Space:"
      echo "   System Preferences > Keyboard > Shortcuts > Input Sources"

      # 추가 macOS 설정들
      echo "Applying additional macOS user-level settings..."

      # macOS Services 설정 (Shift+Cmd+A 충돌 방지)
      echo "🔧 Disabling 'Search man Page Index in Terminal' service..."
      # Note: 복잡한 -dict-add 명령도 문제가 될 수 있어 비활성화
      echo "   Manual setup required: System Preferences > Keyboard > Shortcuts > Services"
      echo "✅ Service configuration noted for manual setup"

      # Dock 설정 적용
      $DRY_RUN_CMD killall Dock 2>/dev/null || true
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

        # 1Password SSH agent setup (platform-specific)
        ${lib.optionalString isDarwin ''
          # Darwin: Group Container 디렉토리를 동적으로 찾기
          for container_dir in ~/Library/Group\ Containers/*.com.1password/t/agent.sock; do
            if [[ -S "$container_dir" ]]; then
              export SSH_AUTH_SOCK="$container_dir"
              break
            fi
          done 2>/dev/null || true
        ''}

        # 기본 위치들도 확인 (cross-platform)
        if [[ -z "$${SSH_AUTH_SOCK:-}" ]]; then
          _1password_sockets=(
            ~/.1password/agent.sock
            /tmp/1password-ssh-agent.sock
          )

          for sock in "$${_1password_sockets[@]}"; do
            if [[ -S "$sock" ]]; then
              export SSH_AUTH_SOCK="$sock"
              break
            fi
          done
        fi

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

        # IntelliJ IDEA 백그라운드 실행 함수 (platform-aware)
        idea() {
          local idea_cmd=""

          # 1. Nix 환경에서 IDEA 확인 (우선순위)
          if command -v intellij-idea-ultimate >/dev/null 2>&1; then
            idea_cmd="intellij-idea-ultimate"
          elif command -v intellij-idea-community >/dev/null 2>&1; then
            idea_cmd="intellij-idea-community"
          ${lib.optionalString isDarwin ''
            # 2. Darwin Homebrew 경로 확인
            elif [[ -x "/opt/homebrew/bin/idea" ]]; then
              idea_cmd="/opt/homebrew/bin/idea"
          ''}
          ${lib.optionalString isLinux ''
            # 2. Linux Homebrew 경로 확인
            elif [[ -x "/home/linuxbrew/.linuxbrew/bin/idea" ]]; then
              idea_cmd="/home/linuxbrew/.linuxbrew/bin/idea"
          ''}
          # 3. 일반 PATH에서 확인 (최후 수단)
          elif command -v idea >/dev/null 2>&1; then
            # 무한 재귀 방지: 현재 함수가 아닌 실제 바이너리인지 확인
            local idea_path=$(command -v idea)
            if ! [[ "$idea_path" =~ function ]] && [[ -x "$idea_path" ]]; then
              idea_cmd="$idea_path"
            else
              echo "Error: IntelliJ IDEA executable not found."
              return 1
            fi
          else
            echo "Error: IntelliJ IDEA not found. Please install via:"
            echo "  - Nix: nix-env -iA nixpkgs.jetbrains.idea-ultimate"
            ${lib.optionalString isDarwin ''echo "  - Homebrew (macOS): brew install --cask intellij-idea"''}
            ${lib.optionalString isLinux ''echo "  - Homebrew (Linux): brew install --cask intellij-idea"''}
            return 1
          fi

          # 백그라운드에서 IDEA 실행
          if ! nohup "$idea_cmd" "$@" >/dev/null 2>&1 &; then
            echo "Error: Failed to start IntelliJ IDEA with command: $idea_cmd"
            return 1
          fi

          echo "IntelliJ IDEA started in background with: $idea_cmd"
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

        # SSH wrapper using autossh for automatic reconnection
        ssh() {
          # Check if autossh is available
          if command -v autossh >/dev/null 2>&1; then
            # Use autossh for automatic reconnection
            # -M 0 disables autossh monitoring port (relies on SSH's ServerAliveInterval)
            autossh -M 0 "$@"
          else
            # Fallback to regular ssh
            command ssh "$@"
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
      extraConfig = ''
        # 기본 설정
        set -g default-terminal "tmux-256color"
        set -g default-shell ${config.programs.zsh.package}/bin/zsh
        set -g default-command "${config.programs.zsh.package}/bin/zsh -l"
        set -g focus-events on

        # TERM 환경변수 설정 (색상 코드 표시 문제 해결)
        set-environment -g TERM screen-256color
        set -g mouse on
        set -g base-index 1
        set -g pane-base-index 1
        set -g renumber-windows on

        # 세션 안정성 향상을 위한 설정
        set -g set-clipboard external
        set -g remain-on-exit off
        set -g allow-rename off
        set -g destroy-unattached off
        set -g status-interval 1

        # SSH/복사-붙여넣기 최적화 (tmux 3.5a)
        setw -g mode-keys vi
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        # tmux 내부 클립보드 설정 (모든 환경에서 동작)
        set -g set-clipboard off  # tmux buffer만 사용
        # tmux buffer로 복사 (확실하고 간단함)
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-and-cancel
        # 추가 단축키
        bind-key P paste-buffer  # Prefix + P로 붙여넣기
        bind-key b list-buffers  # Prefix + b로 버퍼 목록 보기
        bind-key B choose-buffer # Prefix + B로 버퍼 선택

        # 터미널 특성 오버라이드 - 색상 지원만
        # True Color 지원
        set -ga terminal-overrides ",*256col*:Tc"
        set -ga terminal-overrides ",screen*:Tc"
        set -ga terminal-overrides ",xterm*:Tc"
        set -ga terminal-overrides ",tmux*:Tc"

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

        # 세션 저장/복원 설정
        set -g @resurrect-capture-pane-contents 'on'
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '15'
      '';
    };
  };
}
