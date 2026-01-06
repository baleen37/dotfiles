# Vim Editor Configuration
#
# Extracted from modules/shared/programs/vim.nix
#
# Features:
#   - vim-airline: Status line theme (bubblegum theme, Powerline fonts)
#   - vim-tmux-navigator: Seamless navigation between Tmux panes
#   - yank: Clipboard integration
#
# Key Settings:
#   - Line numbers: Relative line numbers + current line number
#   - Search: Incremental search, ignore case
#   - Tab/Space: 2-space indent, convert tabs to spaces
#   - Backup: No backup files, swap files in ~/.config/vim/swap
#   - Clipboard: autoselect mode
#
# Key Bindings:
#   - Leader: , (comma)
#   - LocalLeader: Space
#   - <Leader>,: Paste from clipboard
#   - <Leader>.: Copy to clipboard
#   - <Leader>q: Close window
#   - Ctrl+h/j/k/l: Navigate split windows
#   - Tab/Shift+Tab: Navigate buffers
#

{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.vim = {
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
      set laststatus=2 " Always show statusline
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
    '';
  };
}
