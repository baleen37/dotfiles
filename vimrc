let $PATH = '/usr/local/bin:'.$PATH

call plug#begin('~/.vim/plugged')

" color
Plug 'altercation/vim-colors-solarized'

" interface
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'majutsushi/tagbar'

" git
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" code
Plug 'hynek/vim-python-pep8-indent'
"Plug 'nathanaelkane/vim-indent-guides'
"Plug 'Yggdroot/indentLine'

" lang
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'
Plug 'groenewege/vim-less'
Plug 'leafgarland/typescript-vim'


" commanders
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'jpalardy/vim-slime'
let g:slime_target = "tmux"

call plug#end()

" ----------------------------------------------------------------------------
" Basic settings
" ----------------------------------------------------------------------------

set nu
set rnu
set autoindent
set smartindent
set hlsearch
set incsearch
set autoread                " detect when a file is changed
set expandtab
set tabstop=2
set shiftwidth=2
set exrc
set backspace=indent,eol,start
set secure
set encoding=utf-8
set t_Co=256                " Explicitly tell vim that the terminal supports 256 colors"
syntax on

" solarized
set background=dark
colorscheme solarized

" NERDTree igtnore
let NERDTreeIgnore = ['\.pyc$', '__pycache__']

" yank text to OS X clipboard
" http://evertpot.com/osx-tmux-vim-copy-paste-clipboard/
set clipboard=unnamed

" ----------------------------------------------------------------------------
" Basic mappings
" ----------------------------------------------------------------------------


nmap <F8> :TagbarToggle<CR>

" The-NERD-tree
map <C-t> :tabnew<CR>
nnoremap ]t :tabn<cr>
nnoremap [t :tabp<cr>
nnoremap <F10> :NERDTreeToggle<cr>

" recreate tags
map <F5> :!ctags -R –c++-kinds=+p –fields=+iaS –extra=+q .<CR>

" fzf
nnoremap <leader><tab> :FZF<CR>

" ctags
set tags=./tags;/
