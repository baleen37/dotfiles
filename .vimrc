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

" NERDTree igtnoret let NERDTreeIgnore = ['\.pyc$', '__pycache__']

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
Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
  let g:tagbar_sort = 0
Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesEnable' }
  let g:indentLine_color_term = 239
  let g:indentLine_color_gui = '#616161'

" git
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" code
Plug 'hynek/vim-python-pep8-indent'
"Plug 'nathanaelkane/vim-indent-guides'
"Plug 'Yggdroot/indentLine'
Plug 'vimwiki/vimwiki'

" lang
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'
Plug 'groenewege/vim-less'
Plug 'leafgarland/typescript-vim'
Plug 'sgur/vim-editorconfig'

" commanders
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mhinz/vim-startify'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
Plug 'tpope/vim-surround'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'ferrine/md-img-paste.vim'
  autocmd FileType markdown nnoremap <buffer> <silent> <leader>v :call mdip#MarkdownClipboardImage()<CR>
  let g:mdip_imgdir = 'images'
  let g:mdip_imgname = 'image'
Plug 'junegunn/vim-easy-align'
Plug 'mzlogin/vim-markdown-toc'

let g:slime_target = "tmux"

call plug#end()
" ----------------------------------------------------------------------------
" Basic mappings
" ----------------------------------------------------------------------------
" Use the Solarized Dark theme
syntax enable
set background=dark
colorscheme solarized

" Goyo + limelight
nnoremap <leader>G :Goyo<CR>
let g:limelight_conceal_ctermfg = 245  " Solarized Base1
let g:limelight_conceal_guifg = '#8a8a8a'  " Solarized Base1


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
let g:vimwiki_list = [
  \{ 
  \  'path': '~/wiki/',
  \  'syntax': 'markdown',
  \  'ext': '.md'
  \},
\]
let g:vimwiki_conceallevel = 0
" directory change current path
nnoremap <leader>cd :cd %:p:h<CR>

" toggle Markdown preview 
nmap <leader>p <Plug>MarkdownPreviewToggle
