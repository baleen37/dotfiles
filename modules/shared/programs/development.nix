# Development Tools Configuration
#
# Git, Vim, and SSH configurations for development workflow.
# Extracted from programs.nix following single responsibility principle.
#
# FEATURES:
#   - Git with comprehensive ignores and aliases
#   - Vim with plugins and optimized settings
#   - SSH with 1Password integration and includes
#
# ARCHITECTURE:
#   - Single responsibility: Only development tool configurations
#   - Cross-platform: macOS and Linux compatibility
#   - Security focused: Safe SSH and Git configurations
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
  inherit (userInfo) name email paths;
in
{
  programs = {
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

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [
        "${paths.ssh}/config_external"
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
  };
}
