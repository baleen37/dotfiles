call plug#begin('~/.config/nvim/plugged')

" color
Plug 'altercation/vim-colors-solarized'

" interface
Plug 'The-NERD-tree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'syntastic'
Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }

" git
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" complete
" Plug 'Valloric/YouCompleteMe'

" code
Plug 'hynek/vim-python-pep8-indent'
Plug 'Yggdroot/indentLine'

" lang
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'

" commanders
Plug 'freitass/todo.txt-vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

call plug#end()
