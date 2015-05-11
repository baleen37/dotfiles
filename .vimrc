set nu
set sw=2
set sts=2
set showmatch
set shiftwidth=2
set si
set cin
set cinoptions+=j1
set backspace=2
set backspace=indent,eol,start
set ignorecase
set smartcase
set expandtab
set incsearch
set hlsearch

" Vundle setting
set nocompatible " not use old vim
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Vundle manage
Plugin 'gmarik/Vundle.vim'

" Plugins
Plugin 'The-NERD-tree'
Plugin 'L9'
Plugin 'https://github.com/Lokaltog/vim-powerline'
Plugin 'https://github.com/tfnico/vim-gradle'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'pangloss/vim-javascript'
Plugin 'ctrlp.vim'
Plugin 'rails.vim'
Plugin 'slim-template/vim-slim.git'
Plugin 'AutoComplPop'
Plugin 'fugitive.vim'

" All of your Plugins must be added before the following line
call vundle#end()
filetype plugin indent on

" vim-powerline
set nocompatible   " Disable vi-compatibility
set laststatus=2   " Always show the statusline
set encoding=utf-8 " Necessary to show Unicode glyphs

" The-NERD-tree
map <Tab> gt
map <S-Tab> gT

" vim-nerdtree
map <C-n> :NERDTreeToggle<CR>

" solarized
let g:solarized_termcolors=256
syntax enable
set background=dark
colorscheme solarized

"ctrlp.vim
let g:ctrlp_map = '<c-p>'
nnoremap ; :

" vim-javascript-syntax
au FileType javascript call JavaScriptFold()
