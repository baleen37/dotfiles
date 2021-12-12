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
set nocompatible
filetype plugin on
filetype indent on
set t_Co=256                " Explicitly tell vim that the terminal supports 256 colors"

" NERDTree igtnore
let NERDTreeIgnore = ['\.pyc$', '__pycache__']

" yank text to OS X clipboard
" http://evertpot.com/osx-tmux-vim-copy-paste-clipboard/
set clipboard=unnamed

" ----------------------------------------------------------------------------
" Vim Plugins
" ----------------------------------------------------------------------------
"  " auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

call plug#begin()

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
Plug 'lervag/wiki.vim'
Plug 'lervag/wiki-ft.vim'

" lang
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'
Plug 'groenewege/vim-less'
Plug 'leafgarland/typescript-vim'

" commanders
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'mhinz/vim-startify'
let g:slime_target = "tmux"

call plug#end()
" ----------------------------------------------------------------------------
" Basic mappings
" ----------------------------------------------------------------------------
" Use the Solarized Dark theme
syntax enable
set background=dark
colorscheme solarized


nmap <F8> :TagbarToggle<CR>

" The-NERD-tree
map <C-t> :tabnew<CR>
nnoremap ]t :tabn<cr>
nnoremap [t :tabp<cr>
nnoremap <F10> :NERDTreeToggle<cr>

" recreate tags
map <F5> :!ctags -R –c++-kinds=+p –fields=+iaS –extra=+q .<CR>

" fzf
nnoremap <silent> <leader>f :FZF<cr>
nnoremap <silent> <leader>F :FZF ~<cr>

" ctags
set tags=./tags;/

" vimwiki
let g:wiki_root = '~/Dropbox/wiki'
let g:wiki_filetypes = ['wiki']
let g:wiki_link_extension = '.wiki'

" directory change current path
nnoremap <leader>cd :cd %:p:h<CR>
