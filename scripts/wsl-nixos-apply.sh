#!/bin/bash

# WSL+NixOS 환경에 dotfiles 기능 적용 스크립트
# 실제 사용자: nixos
# 호스트 이름: nixos

set -e

echo "🚀 WSL+NixOS 환경에 dotfiles 기능 적용 시작..."

# 현재 환경 정보
export USER=$(whoami)  # nixos
export HOSTNAME=$(hostname)  # nixos

echo "👤 사용자: $USER"
echo "🖥️  호스트: $HOSTNAME"
echo "📁 작업 디렉토리: $(pwd)"

# 1. 환경 변수 설정
echo "🔧 환경 변수 설정 중..."

# dotfiles 기본 환경 변수 설정
export EDITOR="vim"
export VISUAL="vim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# PATH 설정 - dotfiles 기반
export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
export PATH=$HOME/.local/share/bin:$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/go/bin:$PATH

# 2. 필수 패키지 설치 확인
echo "📦 필수 패키지 확인 중..."

packages=(
    "git"
    "vim"
    "zsh"
    "fzf"
    "fd"
    "bat"
    "tree"
    "curl"
    "wget"
    "jq"
    "ripgrep"
)

missing_packages=()
for pkg in "${packages[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        missing_packages+=("$pkg")
    fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
    echo "⚠️  누락된 패키지: ${missing_packages[*]}"
    echo "💡 NixOS에서는 다음 명령어로 설치하세요:"
    echo "   sudo nixos-rebuild switch"
    echo "   (configuration.nix에 패키지 추가 필요)"
else
    echo "✅ 모든 필수 패키지가 설치됨"
fi

# 3. Zsh 설정 파일 연결
echo "🐚 Zsh 설정 적용 중..."

# 기존 설정 백업
if [ -f ~/.zshrc ]; then
    echo "   기존 ~/.zshrc를 ~/.zshrc.backup으로 백업"
    mv ~/.zshrc ~/.zshrc.backup
fi

# Zsh 설정 파일 생성 (dotfiles 기반)
cat > ~/.zshrc << 'EOF'
# Zsh configuration for WSL+NixOS (based on baleen37/dotfiles)

# Zsh basic settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Key bindings
bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Environment variables (from dotfiles)
export EDITOR="vim"
export VISUAL="vim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# PATH configuration (from dotfiles)
export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
export PATH=$HOME/.local/share/bin:$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/go/bin:$PATH

# Nix daemon initialization
if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi

# Git aliases (from dotfiles)
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gdiff='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gs='git status'
alias gt='git tag'

# File aliases (from dotfiles)
alias la='ls -la --color=auto'
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'

# FZF integration (from dotfiles)
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)

    # FZF default options
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'

    # File search (Ctrl+T)
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    fi

    # Directory search (Alt+C)
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
fi

# Nix shortcuts (from dotfiles)
shell() {
    nix-shell '<nixpkgs>' -A "$1"
}

# Enhanced SSH wrapper (from dotfiles)
ssh() {
    if command -v autossh >/dev/null 2>&1; then
        AUTOSSH_POLL=60 AUTOSSH_FIRST_POLL=30 autossh -M 0 \
            -o "ServerAliveInterval=30" \
            -o "ServerAliveCountMax=3" \
            "$@"
    else
        command ssh \
            -o "ServerAliveInterval=60" \
            -o "ServerAliveCountMax=3" \
            -o "TCPKeepAlive=yes" \
            "$@"
    fi
}

# WSL specific improvements
if command -v wslpath &> /dev/null; then
    # Windows path conversion shortcuts
    alias winpath='wslpath -w'
    alias unixpath='wslpath -u'
fi

# Dotfiles management shortcut
if [ -d ~/dotfiles ]; then
    alias dotfiles='cd ~/dotfiles'
fi

# Claude CLI shortcut (if available)
if command -v claude &> /dev/null; then
    alias cc='claude --dangerously-skip-permissions'
fi
EOF

echo "   ✅ Zsh 설정 파일 생성 완료"

# 4. Git 설정
echo "🔀 Git 설정 적용 중..."

# Git 전역 설정
git config --global user.name "NixOS User"
git config --global user.email "nixos@localhost"
git config --global init.defaultBranch "main"
git config --global pull.rebase false
git config --global core.autocrlf input

# 5. Vim 설정
echo "📝 Vim 설정 적용 중..."

# 기존 vimrc 백업
if [ -f ~/.vimrc ]; then
    echo "   기존 ~/.vimrc를 ~/.vimrc.backup으로 백업"
    mv ~/.vimrc ~/.vimrc.backup
fi

# 기본 vimrc 설정
cat > ~/.vimrc << 'EOF'
" Basic vim configuration (inspired by baleen37/dotfiles)

" Basic settings
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set wrap
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set scrolloff=8

" Color scheme
syntax on
set background=dark
set termguicolors

" Plugins (vim-plug)
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
    " Essential plugins
    Plug 'tpope/vim-sensible'
    Plug 'preservim/nerdtree'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Git integration
    Plug 'tpope/vim-fugitive'

    " Syntax highlighting
    Plug 'sheerun/vim-polyglot'

    " Themes
    Plug 'morhetz/gruvbox'
call plug#end()

" Plugin configurations
colorscheme gruvbox

" FZF configuration
nnoremap <C-p> :FZF<CR>
nnoremap <C-b> :Buffers<CR>

" NERDTree configuration
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
EOF

# vimrc를 위한 .vim 디렉토리 설정
mkdir -p ~/.vim/undodir

echo "   ✅ Vim 설정 파일 생성 완료"

# 6. Claude Code 설정 (설치된 경우)
echo "🤖 Claude Code 설정 확인 중..."

if [ -d ~/.claude ]; then
    echo "   ✅ Claude Code 설정 디렉토리 존재"

    # Claude Code 설정 파일이 있는지 확인
    if [ -d ~/dotfiles/users/shared/.config/claude ]; then
        echo "   💡 dotfiles Claude 설정을 연결할 수 있습니다:"
        echo "      ln -sf ~/dotfiles/users/shared/.config/claude/* ~/.claude/"
    fi
else
    echo "   ℹ️  Claude Code가 설치되지 않음"
fi

# 7. 완료 요약
echo ""
echo "🎉 설정 적용 완료!"
echo ""
echo "📋 적용된 기능:"
echo "   ✅ Zsh shell 환경 (dotfiles 기반 알리어스 및 함수)"
echo "   ✅ Git 전역 설정"
echo "   ✅ Vim 설정 및 플러그인"
echo "   ✅ 환경 변수 설정 (PATH, editor 등)"
echo "   ✅ FZF 통합 (설치된 경우)"
echo ""
echo "🔄 다음 단계:"
echo "   1. zsh 실행: 'chsh -s \$(which zsh)' 또는 그냥 'zsh' 입력"
echo "   2. vim 플러그인 설치: vim 열고 ':PlugInstall' 실행"
echo "   3. 설정 확인: 'source ~/.zshrc'"
echo ""
echo "📁 중요 파일:"
echo "   - ~/.zshrc (Zsh 설정)"
echo "   - ~/.vimrc (Vim 설정)"
echo "   - ~/.gitconfig (Git 설정)"
echo ""
echo "🔧 WSL 특화 기능:"
echo "   - winpath/unixpath: Windows-Unix 경로 변환"
echo "   - dotfiles: ~/dotfiles로 빠른 이동"
echo "   - cc: Claude CLI 단축키 (설치된 경우)"
echo ""
echo "⚠️  주의사항:"
echo "   - NixOS 전역 패키지는 configuration.nix에서 관리"
echo "   - 시스템 전체 설정을 변경하려면 sudo nixos-rebuild switch 필요"
echo "   - 이 설정은 사용자 환경에만 적용됨"

echo "✨ 설정 완료! 새 터미널을 열거나 'source ~/.zshrc'를 실행하세요."