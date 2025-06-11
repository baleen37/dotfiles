{ config, pkgs, lib, ... }:

let name = "Jiho Lee";
    getUser = import ../../lib/get-user.nix { };
    user = getUser;
    email = "baleen37@gmail.com"; in
{
  # Shared shell configuration
  zsh = {
    enable = true;
    autocd = false;
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

    initContent = lib.mkBefore ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Define variables for directories
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$HOME/.local/bin:$PATH

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"

      export EDITOR="vim"
      export VISUAL="vim"

      # 1Password SSH agent (데스크톱 앱)
      # Group Container 디렉토리를 동적으로 찾기
      for container_dir in ~/Library/Group\ Containers/*.com.1password/t/agent.sock; do
        if [[ -S "$container_dir" ]]; then
          export SSH_AUTH_SOCK="$container_dir"
          break
        fi
      done
      
      # 기본 위치들도 확인
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
      
      # Use Cursor as code editor
      alias code=cursor

      # Initialize direnv
      eval "$(direnv hook zsh)"
      
      # Auto-update dotfiles on shell startup (with TTL)
      if [[ -x "$HOME/dotfiles/scripts/auto-update-dotfiles" ]]; then
        "$HOME/dotfiles/scripts/auto-update-dotfiles" --silent &
      fi
    '';
  };

  git = {
    enable = true;
    ignores = [
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
      
      # Temporary files
      "*.tmp"
      "*.log"
      ".cache/"
      
      # Build artifacts
      "dist/"
      "build/"
      "target/"
      
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
    plugins = with pkgs.vimPlugins; [ vim-airline vim-airline-themes vim-startify vim-tmux-navigator ];
    settings = { ignorecase = true; };
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
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${user}/.ssh/config_external"
      )
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${user}/.ssh/config_external"
      )
    ];
    extraConfig = ''
      Host *
        IdentitiesOnly yes
        AddKeysToAgent yes
    '' + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        UseKeychain yes
    '';
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
      set -g default-terminal "screen-256color"
      set -g focus-events on
      set -g mouse on
      set -g base-index 1
      set -g pane-base-index 1
      set -g renumber-windows on

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
      
      # 세션 저장/복원 설정
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'
      '';
    };


}
