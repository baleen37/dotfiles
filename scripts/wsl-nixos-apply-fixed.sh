#!/bin/bash

# WSL+NixOS 환경에 dotfiles 기능 적용 스크립트 (수정판)
# NixOS 환경의 제약 사항을 고려한 버전

set -e

echo "🚀 WSL+NixOS 환경에 dotfiles 기능 적용 시작 (수정판)..."

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
)

missing_packages=()
available_packages=()

for pkg in "${packages[@]}"; do
    if command -v "$pkg" &> /dev/null; then
        available_packages+=("$pkg")
    else
        missing_packages+=("$pkg")
    fi
done

echo "✅ 설치된 패키지: ${available_packages[*]}"
if [ ${#missing_packages[@]} -gt 0 ]; then
    echo "⚠️  누락된 패키지: ${missing_packages[*]}"
    echo "💡 NixOS에서는 configuration.nix에 패키지 추가 후 'sudo nixos-rebuild switch' 실행 필요"
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

# NixOS specific helper
nixos-info() {
    echo "NixOS System Info:"
    echo "=================="
    echo "System: $(uname -a)"
    echo "Nix version: $(nix --version)"
    echo "Current generation: $(nix-store --query --references /run/current-system | wc -l) packages"
    echo "User: $USER"
    echo "Home: $HOME"
}
EOF

echo "   ✅ Zsh 설정 파일 생성 완료"

# 4. Git 설정 (NixOS 환경 고려)
echo "🔀 Git 설정 적용 중..."

# 사용자 레벨 git 설정 시도
if [ -w ~/.config ]; then
    git config --global user.name "NixOS User" 2>/dev/null || echo "   ⚠️  Git 사용자 이름 설정 실패 (관리자 권한 필요)"
    git config --global user.email "nixos@localhost" 2>/dev/null || echo "   ⚠️  Git 사용자 이메일 설정 실패 (관리자 권한 필요)"
    git config --global init.defaultBranch "main" 2>/dev/null || echo "   ⚠️  Git 기본 브랜치 설정 실패"
    git config --global pull.rebase false 2>/dev/null || echo "   ⚠️  Git pull 설정 실패"
    git config --global core.autocrlf input 2>/dev/null || echo "   ⚠️  Git autocrlf 설정 실패"

    echo "   💡 Git 설정 성공 (일부 항목은 관리자 권한 필요)"
else
    echo "   ⚠️  ~/.config 디렉토리 쓰기 권한 없음"
    echo "   💡 Git 설정은 수동으로 필요시 관리자 권한으로 설정:"
    echo "      git config --global user.name 'Your Name'"
    echo "      git config --global user.email 'your.email@example.com'"
fi

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

" Basic plugins (vim-plug style, but simplified)
if !exists('g:vscode')
    " FZF integration
    if executable('fzf')
        set rtp+=~/.fzf
    endif

    " Basic mappings
    if has('nvim')
        nnoremap <C-p> :Files<CR>
    elseif executable('fzf')
        command! -bang -nargs=? -complete=dir Files call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
        nnoremap <C-p> :Files<CR>
    endif
endif

" NixOS specific settings
set nocompatible
filetype plugin indent on

" WSL specific improvements
if has('wsl')
    set clipboard=unnamedplus
endif
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

        # 실제 연결 시도
        for file in ~/dotfiles/users/shared/.config/claude/*; do
            if [ -f "$file" ]; then
                ln -sf "$file" ~/.claude/ 2>/dev/null && echo "   ✅ $(basename "$file") 연결 성공" || echo "   ⚠️  $(basename "$file") 연결 실패"
            fi
        done
    fi
else
    echo "   ℹ️  Claude Code가 설치되지 않음"
    echo "   💡 설치 방법: npm install -g @anthropic-ai/claude-cli"
fi

# 7. NixOS 전용 스크립트 생성
echo "🏗️  NixOS 전용 도우미 스크립트 생성 중..."

cat > ~/nixos-dotfiles-helper.sh << 'EOF'
#!/bin/bash

# NixOS + dotfiles 도우미 스크립트

case "$1" in
    "packages")
        echo "설치된 개발 패키지:"
        nix-store -q --references /run/current-system/sw | grep -E "(git|vim|zsh|fzf|fd|bat)" | sort
        ;;
    "update")
        echo "⚠️  NixOS 시스템 업데이트는 관리자 권한 필요:"
        echo "   sudo nixos-rebuild switch"
        ;;
    "shell")
        if [ -n "$2" ]; then
            nix-shell '<nixpkgs>' -A "$2"
        else
            echo "사용법: $0 shell <package-name>"
            echo "예: $0 shell python3"
        fi
        ;;
    "info")
        echo "NixOS + dotfiles 환경 정보:"
        echo "==========================="
        echo "사용자: $(whoami)"
        echo "호스트: $(hostname)"
        echo "Nix 버전: $(nix --version | head -1)"
        echo "시스템: $(uname -a)"
        echo "dotfiles: $HOME/dotfiles"
        ;;
    *)
        echo "NixOS dotfiles 도우미"
        echo "===================="
        echo "사용법: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  packages - 설치된 개발 패키지 목록"
        echo "  update   - 시스템 업데이트 안내"
        echo "  shell    - 임시 패키지 셸 실행"
        echo "  info     - 환경 정보 출력"
        ;;
esac
EOF

chmod +x ~/nixos-dotfiles-helper.sh

echo "   ✅ 도우미 스크립트 생성 완료 (~/nixos-dotfiles-helper.sh)"

# 8. 완료 요약
echo ""
echo "🎉 설정 적용 완료!"
echo ""
echo "📋 적용된 기능:"
echo "   ✅ Zsh shell 환경 (dotfiles 기반 알리어스 및 함수)"
if [ -w ~/.config ]; then
    echo "   ✅ Git 전역 설정 (일부 항목)"
else
    echo "   ⚠️  Git 설정 (권한 제한으로 일부만 적용)"
fi
echo "   ✅ Vim 설정"
echo "   ✅ 환경 변수 설정 (PATH, editor 등)"
if command -v fzf &> /dev/null; then
    echo "   ✅ FZF 통합"
else
    echo "   ⚠️  FZF 통합 (패키지 미설치)"
fi
echo ""
echo "🔄 다음 단계:"
echo "   1. zsh 실행: 'chsh -s \$(which zsh)' 또는 그냥 'zsh' 입력"
echo "   2. 설정 확인: 'source ~/.zshrc'"
echo "   3. 도우미 스크립트: './nixos-dotfiles-helper.sh info'"
echo ""
echo "📁 중요 파일:"
echo "   - ~/.zshrc (Zsh 설정)"
echo "   - ~/.vimrc (Vim 설정)"
echo "   - ~/nixos-dotfiles-helper.sh (도우미 스크립트)"
echo "   - 백업: *.backup 파일"
echo ""
echo "🔧 NixOS 특화 기능:"
echo "   - nixos-info: 시스템 정보 표시"
echo "   - shell: 임시 패키지 셸"
echo "   - winpath/unixpath: WSL 경로 변환"
echo "   - dotfiles: ~/dotfiles로 빠른 이동"
echo ""
echo "⚠️  주의사항:"
echo "   - NixOS 전역 패키지는 configuration.nix에서 관리"
echo "   - 시스템 전체 설정을 변경하려면 sudo nixos-rebuild switch 필요"
echo "   - Git 설정의 일부는 관리자 권한 필요"

# 9. 즉시 테스트 가능한 명령어
echo ""
echo "🧪 즉시 테스트:"
echo "   ./nixos-dotfiles-helper.sh info"
echo "   ./nixos-dotfiles-helper.sh packages"

echo ""
echo "✨ 설정 완료! 새 터미널을 열거나 'source ~/.zshrc'를 실행하세요."
echo "🎯 'zsh'를 실행하여 새 환경을 바로 사용해보세요!"