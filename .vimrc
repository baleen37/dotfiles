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
Plugin 'L9'
" for tree
Plugin 'The-NERD-tree'
" Easy to find
Plugin 'ctrlp.vim'
" Git Plugin
Plugin 'fugitive.vim'
" statusline plugin
Plugin 'powerline/powerline'
" lean & mean status/tabline for vim that's light as air
Plugin 'bling/vim-airline'
" rails.vim: Ruby on Rails power tools
Plugin 'tpope/vim-rails'
" Vim/Ruby Configuration Files
Plugin 'vim-ruby/vim-ruby'
" check syntax error
Plugin 'syntastic'
" for rails-slim syntax
Plugin 'slim-template/vim-slim.git'
" for javascript syntax
Plugin 'jelera/vim-javascript-syntax'
Plugin 'pangloss/vim-javascript'

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
map <C-t> :tabnew<CR>

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

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
