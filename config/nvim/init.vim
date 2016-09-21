source ~/.config/nvim/plugins.vim

set nocompatible            " not compatible with vi
set autoread                " detect when a file is changed
set nu
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

" solarized
set background=dark
colorscheme solarized

" vim-powerline
set nocompatible   " Disable vi-compatibility

" The-NERD-tree
map <Tab> gt
map <S-Tab> gT
map <C-t> :tabnew<CR>
let NERDTreeIgnore = ['\.pyc$', '__pycache__']

"fzf
nnoremap <c-p> :FZF<CR>

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" airline options
let g:airline_theme='solarized'

" <F10> vim-nerdtree
map <F10> :NERDTreeToggle<CR>

" <F11> tagbar
nmap <F11> :TagbarToggle<CR>

" copy into clipboard
vnoremap <C-c> "*y

" use ; instead of :
nnoremap ; :

" goto sensible position
" nnoremap <leader>g :YcmCompleter GoTo<CR>

" shortcut  ipdb
nnoremap <leader>p oimport pudb; pudb.set_trace()<Esc>

set laststatus=2
