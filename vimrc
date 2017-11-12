let $PATH = '/usr/local/bin:'.$PATH

call plug#begin('~/.vim/plugged')

" color
Plug 'altercation/vim-colors-solarized'

" interface
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'scrooloose/syntastic'
Plug 'majutsushi/tagbar'

" git
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" complete
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --tern-completer' }

" code
Plug 'hynek/vim-python-pep8-indent'
"Plug 'nathanaelkane/vim-indent-guides'
"Plug 'Yggdroot/indentLine'

" lang
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'
Plug 'groenewege/vim-less'

" commanders
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

call plug#end()

set nocompatible            " not compatible with vi
set autoread                " detect when a file is changed
set nu
set rnu
set expandtab
set autoindent
set smartindent
set tabstop=2
set shiftwidth=2
set hlsearch
set incsearch

syntax on                   " switch syntax highlighting on

set t_Co=256                " Explicitly tell vim that the terminal supports 256 colors"

if !has('nvim')
	set encoding=utf-8 " Necessary to show Unicode glyphs
endif

" ----------------------------------------------------------------------------
" solarized
" ----------------------------------------------------------------------------
set background=dark
colorscheme solarized

" ----------------------------------------------------------------------------
" vim-powerline
" ----------------------------------------------------------------------------
set nocompatible   " Disable vi-compatibility

" ----------------------------------------------------------------------------
" The-NERD-tree
" ----------------------------------------------------------------------------
map <Tab> gt
map <S-Tab> gT
map <C-t> :tabnew<CR>
let NERDTreeIgnore = ['\.pyc$', '__pycache__']

" ----------------------------------------------------------------------------
" fzf
" ----------------------------------------------------------------------------
nnoremap <c-p> :FZF<CR>

" ----------------------------------------------------------------------------
" Syntastic
" ----------------------------------------------------------------------------
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
let g:syntastic_python_checkers=['pep8', 'python']

" airline options
let g:airline_theme='solarized'

" <F10> vim-nerdtree
map <F10> :NERDTreeToggle<CR>

" <F11> tagbar
nmap <F11> :TagbarToggle<CR>

" copy into clipboard
vnoremap <C-c> "*y

" ----------------------------------------------------------------------------
" YcmComplete
" ----------------------------------------------------------------------------
nnoremap <leader>g :YcmCompleter GoTo<CR>
nnoremap <leader>gr :YcmCompleter GoToReferences<CR>
nnoremap <leader>gd :YcmCompleter GetDoc<CR>
let g:ycm_python_binary_path = 'python'

" ----------------------------------------------------------------------------
" indentLine
" ----------------------------------------------------------------------------
let g:indentLine_enabled = 0
"autocmd FileType python,javascript IndentLinesEnable

" shortcut  ipdb
nnoremap <leader>p oimport pudb; pudb.set_trace()<Esc>

set laststatus=2

let g:python_host_prog = $HOME . "/.pyenv/versions/neovim2/bin/python"
let g:python3_host_prog = $HOME . "/.pyenv/versions/neovim3/bin/python"

autocmd filetype c nnoremap <F4> :w <bar> exec '!gcc '.shellescape('%').' -o '.shellescape('%:r').' && ./'.shellescape('%:r')<CR>
autocmd filetype cpp nnoremap <F4> :w <bar> exec '!g++ '.shellescape('%').' -o '.shellescape('%:r').' && ./'.shellescape('%:r')<CR>

" yank text to OS X clipboard
" " http://evertpot.com/osx-tmux-vim-copy-paste-clipboard/
set clipboard=unnamed
