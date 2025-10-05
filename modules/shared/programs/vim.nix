# Vim 에디터 설정
#
# Vim 에디터의 플러그인, 키 바인딩, 표시 옵션을 관리하는 모듈
#
# 플러그인:
#   - vim-airline: 상태 표시줄 테마 (bubblegum 테마, Powerline 폰트)
#   - vim-tmux-navigator: Tmux 패널 간 원활한 이동
#   - yank: 클립보드 통합
#
# 주요 설정:
#   - 줄 번호: 상대적 줄 번호 (relativenumber) + 현재 줄 번호
#   - 검색: 증분 검색, 대소문자 무시
#   - 탭/공백: 2칸 들여쓰기, 탭을 공백으로 변환
#   - 백업: 백업 파일 생성 안 함, 스왑 파일 ~/.config/vim/swap
#   - 클립보드: autoselect 모드
#
# 키 바인딩:
#   - Leader: , (comma)
#   - LocalLeader: Space
#   - <Leader>,: 클립보드에서 붙여넣기
#   - <Leader>.: 클립보드로 복사
#   - <Leader>q: 창 닫기
#   - Ctrl+h/j/k/l: 분할 창 이동
#   - Tab/Shift+Tab: 버퍼 이동
#
# VERSION: 3.1.0 (Extracted from development.nix)
# LAST UPDATED: 2024-10-04

{
  config,
  pkgs,
  lib,
  platformInfo,
  userInfo,
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
}
