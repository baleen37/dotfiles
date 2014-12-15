set tabstop=4
set nu
set ts=2
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
set incsearch
set hlsearch

syntax on

" Vundle setting
set nocompatible " not use old vim
set laststatus=2 " for seeing powerline
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
au FILETYPE html set syntax=phtml

" Vundle manage
Plugin 'gmarik/Vundle.vim'

" Plugins
Plugin 'The-NERD-tree'
Plugin 'SuperTab'
Plugin 'https://github.com/Lokaltog/vim-powerline'
Plugin 'https://github.com/mitsuhiko/vim-jinja'
Plugin 'groenewege/vim-less'
Plugin 'L9'
Plugin 'FuzzyFinder'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'https://github.com/tfnico/vim-gradle'

call vundle#end()
filetype plugin indent on

nnoremap <F7> :NERDTree<CR>
map <C-l> :tabn<CR>
map <C-h> :tabp<CR>
nnoremap ; :
