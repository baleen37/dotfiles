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
set conceallevel=0
set foldlevelstart=99
set formatoptions+=1
set encoding=utf-8
set nocompatible
filetype plugin on
filetype indent on
let mapleader      = ' '
let maplocalleader = ' '
set t_Co=256                " Explicitly tell vim that the terminal supports 256 colors"

set directory^=$HOME/.vim/swap

function! s:statusline_expr()
  let mod = "%{&modified ? '[+] ' : !&modifiable ? '[x] ' : ''}"
  let ro  = "%{&readonly ? '[RO] ' : ''}"
  let ft  = "%{len(&filetype) ? '['.&filetype.'] ' : ''}"
  let fug = "%{exists('g:loaded_fugitive') ? fugitive#statusline() : ''}"
  let sep = ' %= '
  let pos = ' %-12(%l : %c%V%) '
  let pct = ' %P'

  return '[%n] %F %<'.mod.ro.ft.fug.sep.pos.'%*'.pct
endfunction
let &statusline = s:statusline_expr()

let s:darwin = has('mac')

" NERDTree igtnoret let NERDTreeIgnore = ['\.pyc$', '__pycache__']

" yank text to OS X clipboard
" http://evertpot.com/osx-tmux-vim-copy-paste-clipboard/
set clipboard=unnamed

" 80 chars/line
set textwidth=0
if exists('&colorcolumn')
  set colorcolumn=80
endif

" Tabs
nnoremap ]t :tabn<cr>
nnoremap [t :tabp<cr>

" <tab> / <s-tab> circular windows navigation
nnoremap <tab>   <c-w>w
nnoremap <S-tab> <c-w>W

" ----------------------------------------------------------------------------
" <leader>ij | Open in IntelliJ
" ----------------------------------------------------------------------------
if s:darwin
  nnoremap <silent> <leader>ij :call system('nohup "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" '.expand('%:p').'> /dev/null 2>&1 < /dev/null &')<cr>
endif

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
"Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesEnable' }
Plug 'Yggdroot/indentLine'
  autocmd! User indentLine doautocmd indentLine Syntax
  let g:indentLine_color_term = 239
  let g:indentLine_color_gui = '#616161'

" git
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" code
Plug 'hynek/vim-python-pep8-indent'
"Plug 'nathanaelkane/vim-indent-guides'

" lang
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'
Plug 'groenewege/vim-less'
Plug 'leafgarland/typescript-vim'
Plug 'sgur/vim-editorconfig'

" edit
Plug 'AndrewRadev/switch.vim'
  let g:switch_mapping = '-'
  let g:switch_custom_definitions = [
  \   ['MON', 'TUE', 'WED', 'THU', 'FRI']
  \ ]
Plug 'tpope/vim-markdown'
Plug 'lervag/vim-rainbow-lists'
Plug 'lervag/lists.vim'
  let g:lists_filetypes = ['markdown']
" Plug 'preservim/vim-markdown'
"   let g:vim_markdown_frontmatter = 1
"   let g:vim_markdown_conceal = 1
"   let g:vim_markdown_conceal_code_blocks = 0
"   let g:vim_markdown_fenced_languages = [
"      \ 'css', 'erb=eruby', 'javascript', 'js=javascript', 'json=javascript', 'ruby', 'sass', 'xml', 'html',
"      \ 'sh', 'bash=sh', 'scala', 'java']


" commanders
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mhinz/vim-startify'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
Plug 'tpope/vim-surround'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
  nmap <Leader>l <Plug>(Limelight)
  xmap <Leader>l <Plug>(Limelight)
  nnoremap <Leader>ll :Limelight!<cr>
Plug 'ferrine/md-img-paste.vim'
  autocmd FileType markdown nnoremap <buffer> <silent> <leader>v :call mdip#MarkdownClipboardImage()<CR>
  let g:mdip_imgdir = 'images'
  let g:mdip_imgname = 'image'
Plug 'junegunn/vim-easy-align'
Plug 'mzlogin/vim-markdown-toc'
Plug 'ludovicchabant/vim-gutentags'
"Plug 'preservim/vim-markdown'
" Plug 'preservim/vim-markdown'
  " let g:vim_markdown_frontmatter = 1
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'lervag/wiki.vim'
  let g:wiki_filetypes = ['md']
  let g:wiki_link_extension = '.md'
  let g:wiki_root = '~/Dropbox/wiki/'
  let g:wiki_link_target_type = 'md'
  let g:wiki_journal = {
    \ 'name': 'diary',
    \ 'frequency': 'daily',
    \ 'date_format': {
    \   'daily' : '%Y-%m-%d',
    \   'weekly' : '%Y_w%V',
    \   'monthly' : '%Y_m%m',
    \ },
    \ 'index_use_journal_scheme': v:true,
    \}

"" 
Plug 'lervag/wiki-ft.vim'
  autocmd BufNewFile,BufFilePre,BufRead *.md set filetype=wiki
  
"   
"Plug 'Furkanzmc/zettelkasten.nvim'

if has('nvim')
  Plug 'github/copilot.vim'
endif



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
let g:limelight_paragraph_span = 1
let g:limelight_priority = -1

function! s:goyo_enter()
  if has('gui_running')
    set fullscreen
    set background=light
    set linespace=7
  elseif exists('$TMUX')
    silent !tmux set status off
  endif
  Limelight
  let &l:statusline = '%M'
  hi StatusLine ctermfg=red guifg=red cterm=NONE gui=NONE
endfunction

function! s:goyo_leave()
  if has('gui_running')
    set nofullscreen
    set background=dark
    set linespace=0
  elseif exists('$TMUX')
    silent !tmux set status on
  endif
  Limelight!
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

nnoremap <Leader>G :Goyo<CR>

nmap <F8> :TagbarToggle<CR>

" ----------------------------------------------------------------------------
" markdown-preview
" ----------------------------------------------------------------------------
" if s:darwin && executable('x5050')
"   function! MKDPSplit(url)
"     let script = '
"     \│ ~/Library/Application\ Support/iTerm2/iterm2env/versions/*/bin/python3 <<_
"     \│ import iterm2
"     \│ async def main(connection):
"     \│   app = await iterm2.async_get_app(connection)
"     \│   window = app.current_terminal_window
"     \│   if window is not None:
"     \│     await window.async_set_fullscreen(False)
"     \│ iterm2.run_until_complete(main)
"     \│ _
"     \│ x5050 left '.shellescape(a:url)
"     call system(join(split(script, '│ '), "\n"))
"   endfunction
"   let g:mkdp_browserfunc = 'MKDPSplit'
" endif
let g:mkdp_open_to_the_world = 1
let g:mkdp_auto_close = 0
let g:mkdp_open_ip = '127.0.0.1'
let g:mkdp_browser = 'safari'


" The-NERD-tree
map <C-t> :tabnew<CR>
nnoremap <Leader>n :NERDTreeToggle<cr>

" fzf
nnoremap <silent> <Leader><Leader> :Files<CR>
nnoremap <silent> <Leader>f :Files <C-W><CR>
nnoremap <silent> <Leader><Enter>  :Buffers<CR>
nnoremap <silent> <Leader>C        :Colors<CR>
nnoremap <silent> <Leader>L        :Lines<CR>
nnoremap <silent> <Leader>ag       :Ag <C-R><C-W><CR>
nnoremap <silent> <Leader>AG       :Ag <C-R><C-A><CR>
xnoremap <silent> <Leader>ag       y:Ag <C-R>"<CR>
nnoremap <silent> <Leader>`        :Marks<CR>

imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
inoremap <expr> <c-x><c-d> fzf#vim#complete#path('blsd')
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)
inoremap <expr> <c-x><c-f> fzf#vim#complete#path('rg --files')



function! s:copy_results(lines)
  let joined_lines = join(a:lines, "\n")
  if len(a:lines) > 1
    let joined_lines .= "\n"
  endif
  let @+ = joined_lines
endfunction

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit',
  \ 'ctrl-y': function('s:copy_results'),
  \ }

function! s:plug_help_sink(line)
  let dir = g:plugs[a:line].dir
  for pat in ['doc/*.txt', 'README.md']
    let match = get(split(globpath(dir, pat), "\n"), 0, '')
    if len(match)
      execute 'tabedit' match
      return
    endif
  endfor
  tabnew
  execute 'Explore' dir
endfunction

command! PlugHelp call fzf#run(fzf#wrap({
  \ 'source': sort(keys(g:plugs)),
  \ 'sink':   function('s:plug_help_sink')}))

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let options = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  let options = fzf#vim#with_preview(options, 'right', 'ctrl-/')
  call fzf#vim#grep(initial_command, 1, options, a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

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


" zettelkasten
let g:zettelkasten = "~/Dropbox/wiki/"
" command! -nargs=1 NewZettel :execute ":e" zettelkasten . strftime("%Y%m%d%H%M") . "-<args>.md"
command! -nargs=1 NewZettel :execute ":e" zettelkasten . "/<args>/" . strftime("%y%m%d%H%M%S") . ".md"
nnoremap <leader>z :NewZettel 

" make_note_link: List -> Str
" returned string: [Title](YYYYMMDDHH.md)
function! s:make_note_link(l)
        " fzf#vim#complete returns a list with all info in index 0
        let line = split(a:l[0], ':')
        let ztk_id = l:line[0]
        let ztk_title = substitute(l:line[1], '\#\s\+', '', 'g')
        let mdlink = "[" . ztk_title ."](". ztk_id .")"
        return mdlink
endfunction
" mnemonic link zettel
inoremap <expr> <c-l>z fzf#vim#complete({
  \ 'source':  'rg --no-heading --smart-case  ^\#',
  \ 'reducer': function('<sid>make_note_link'),
  \ 'options': '--multi --reverse --margin 15%,0',
  \ 'up':    5})

