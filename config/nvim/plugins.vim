call plug#begin('~/.config/nvim/plugged')

" color
Plug 'altercation/vim-colors-solarized'

" interface
Plug 'The-NERD-tree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'syntastic'
Plug 'majutsushi/tagbar'

" git
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" complete
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --tern-completer' }
" Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Plug 'zchee/deoplete-jedi'
" Plug 'carlitux/deoplete-ternjs'

" code
Plug 'hynek/vim-python-pep8-indent'
Plug 'Yggdroot/indentLine'

" lang
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'

" commanders
Plug 'freitass/todo.txt-vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'groenewege/vim-less'

call plug#end()
