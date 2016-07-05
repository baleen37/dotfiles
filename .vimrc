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
" for tree
Plugin 'The-NERD-tree'
" Easy to find
Plugin 'ctrlp.vim'
" statusline plugin
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
" check syntax error
Plugin 'syntastic'
" for auto complete
Plugin 'Valloric/YouCompleteMe'

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
let NERDTreeIgnore = ['\.pyc$']

" vim-nerdtree
map <C-n> :NERDTreeToggle<CR>

" solarized
let g:solarized_termcolors=256
syntax enable
set background=dark
colorscheme solarized

"ctrlp.vim
let g:ctrlp_map = '<c-p>'

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" copy into clipboard
vnoremap <C-c> "*y

" use ; instead of :
nnoremap ; :

" goto sensible position
nnoremap <leader>g :YcmCompleter GoTo<CR>
