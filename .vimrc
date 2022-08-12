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
let mapleader      = ' '
let maplocalleader = ' '
set t_Co=256                " Explicitly tell vim that the terminal supports 256 colors"

set directory^=$HOME/.vim/swap

let s:darwin = has('mac')

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
Plug 'junegunn/seoul256.vim'
let g:seoul256_background = 236

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
" Plug 'vimwiki/vimwiki'

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
Plug 'ludovicchabant/vim-gutentags'
"Plug 'preservim/vim-markdown'
Plug 'neoclide/coc.nvim', {'branch': 'release'}


let g:slime_target = "tmux"

call plug#end()
" ----------------------------------------------------------------------------
" Basic mappings
" ----------------------------------------------------------------------------
" Use the Solarized Dark theme
syntax enable
set background=dark

let g:seoul256_background = 236
colo seoul256

" Goyo + limelight
nnoremap <Leader>G :Goyo<CR>
let g:limelight_conceal_ctermfg = 245  " Solarized Base1
let g:limelight_conceal_guifg = '#8a8a8a'  " Solarized Base1


nmap <F8> :TagbarToggle<CR>

" ----------------------------------------------------------------------------
" markdown-preview
" ----------------------------------------------------------------------------
if s:darwin && executable('x5050')
  function! MKDPSplit(url)
    let script = '
    \│ ~/Library/Application\ Support/iTerm2/iterm2env/versions/*/bin/python3 <<_
    \│ import iterm2
    \│ async def main(connection):
    \│   app = await iterm2.async_get_app(connection)
    \│   window = app.current_terminal_window
    \│   if window is not None:
    \│     await window.async_set_fullscreen(False)
    \│ iterm2.run_until_complete(main)
    \│ _
    \│ x5050 left '.shellescape(a:url)
    call system(join(split(script, '│ '), "\n"))
  endfunction
  let g:mkdp_browserfunc = 'MKDPSplit'
endif
let g:mkdp_open_to_the_world = 1
let g:mkdp_auto_close = 0
let g:mkdp_open_ip = '127.0.0.1'


" The-NERD-tree
map <C-t> :tabnew<CR>
nnoremap ]t :tabn<cr>
nnoremap [t :tabp<cr>
nnoremap <Leader>n :NERDTreeToggle<cr>

" fzf
nnoremap <silent> <leader>f :FZF<cr>
nnoremap <silent> <leader>F :FZF ~<cr>

" ctags
set tags=./tags/;
" directory change current path
nnoremap <leader>cd :cd %:p:h<CR>

" toggle Markdown preview 
nmap <leader>p <Plug>MarkdownPreviewToggle

" tagbar
let g:tagbar_type_vimwiki = {
    \ 'ctagstype' : 'vimwiki',
    \ 'sort': 0,
    \ 'kinds' : [
        \ 'h:Heading'
    \ ]
\ }
nnoremap <Leader>t :TagbarToggle<cr>

" gutentags
set statusline+=%{gutentags#statusline()}


map gt <Nop>
