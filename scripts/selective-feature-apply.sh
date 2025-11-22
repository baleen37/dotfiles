#!/bin/bash

# 선택적 기능 적용 스크립트
# dotfiles의 특정 기능만 WSL+NixOS에 적용

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎯 dotfiles 선택적 기능 적용 도구"
echo "📁 dotfiles 경로: $DOTFILES_DIR"
echo ""

# 기능 선택 메뉴
show_menu() {
    echo "📋 적용할 기능을 선택하세요 (숫자로 선택, 여러 개 가능):"
    echo ""
    echo "1) 🔧 개발 도구 (git, vim, zsh) - 기본 설정"
    echo "2) 🐚 Shell 환경 (zsh + fzf + 알리어스)"
    echo "3) 📝 편집기 (vim + 플러그인 + 테마)"
    echo "4) 🌐 Git 설정 (dotfiles 스타일)"
    echo "5) 🤖 Claude Code 통합"
    echo "6) 📦 패키지 개발자 환경"
    echo "7) 🛠️  전체 적용 (1-6 모두)"
    echo "8) ❓ 도움말 및 정보"
    echo "q) 🚪 종료"
    echo ""
}

# 도움말 표시
show_help() {
    echo ""
    echo "📖 도움말 및 정보"
    echo "=================="
    echo ""
    echo "🔧 개발 도구 (1):"
    echo "   - Git 기본 설정"
    echo "   - Vim 기본 설정"
    echo "   - Zsh 기본 설정"
    echo "   - 기본 알리어스"
    echo ""
    echo "🐚 Shell 환경 (2):"
    echo "   - Zsh + Powerlevel10k 테마"
    echo "   - FZF 퍼지 검색 통합"
    echo "   - Git, 파일, SSH 알리어스"
    echo "   - Nix 단축 함수"
    echo ""
    echo "📝 편집기 (3):"
    echo "   - Vim 최신 설정"
    echo "   - vim-plug 플러그인 매니저"
    echo "   - FZF, NERDTree, Git 통합"
    echo "   - Gruvbox 테마"
    echo ""
    echo "🌐 Git 설정 (4):"
    echo "   - baleen37 스타일 Git 설정"
    echo "   - 전역 유저 설정"
    echo "   - 기본 브랜치 설정"
    echo "   - Git 알리어스"
    echo ""
    echo "🤖 Claude Code (5):"
    echo "   - Claude Code 설정 연결"
    echo "   - CLI 단축키 설정"
    echo "   - 스킬 및 명령어 설정"
    echo ""
    echo "📦 개발 환경 (6):"
    echo "   - 다양한 언어 개발 환경"
    echo "   - npm, cargo, go 경로 설정"
    echo "   - 개발 관련 알리어스"
    echo ""
    echo "🛠️  전체 적용 (7):"
    echo "   - 위 모든 기능 적용"
    echo ""
    echo "📁 파일 위치:"
    echo "   - 설정: ~/.zshrc, ~/.vimrc, ~/.gitconfig"
    echo "   - 백업: *.backup 파일로 생성"
    echo "   - dotfiles: $DOTFILES_DIR"
    echo ""
}

# 개발 도구 기본 설정
apply_dev_tools() {
    echo "🔧 개발 도구 기본 설정 적용 중..."

    # Git 기본 설정
    git config --global init.defaultBranch "main"
    git config --global pull.rebase false
    git config --global core.autocrlf input

    echo "   ✅ Git 기본 설정 완료"

    # vim 기본 설정
    if [ -f ~/.vimrc ]; then
        cp ~/.vimrc ~/.vimrc.backup
    fi

    cat > ~/.vimrc << 'EOF'
" Basic vim configuration
set number
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
syntax on
set background=dark
EOF

    echo "   ✅ Vim 기본 설정 완료"
}

# Shell 환경 설정
apply_shell_env() {
    echo "🐚 Shell 환경 설정 적용 중..."

    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc ~/.zshrc.backup
    fi

    # zsh이 설치되어 있는지 확인
    if command -v zsh &> /dev/null; then
        cat > ~/.zshrc << 'EOF'
# Zsh configuration (from baleen37/dotfiles)

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Basic aliases
alias la='ls -la --color=auto'
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'

# Git aliases
alias ga='git add'
alias gc='git commit'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'

# Environment
export EDITOR="vim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# FZF integration
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# Nix shortcuts
shell() {
    nix-shell '<nixpkgs>' -A "$1"
}
EOF

        echo "   ✅ Zsh 설정 완료"
        echo "   💡 적용하려면: chsh -s \$(which zsh) 또는 zsh 실행"
    else
        echo "   ⚠️  Zsh가 설치되지 않음"
    fi
}

# 편집기 설정
apply_editor() {
    echo "📝 편집기 설정 적용 중..."

    if [ -f ~/.vimrc ]; then
        cp ~/.vimrc ~/.vimrc.backup
    fi

    # vim-plug 설치
    if [ ! -f ~/.vim/autoload/plug.vim ]; then
        echo "   📦 vim-plug 설치 중..."
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    cat > ~/.vimrc << 'EOF'
" Enhanced vim configuration (from baleen37/dotfiles)

" Basic settings
set number relativenumber
set tabstop=2 shiftwidth=2 expandtab smartindent
set wrap smartcase noswapfile nobackup
set undodir=~/.vim/undodir undofile
set incsearch scrolloff=8
set termguicolors

" vim-plug plugins
call plug#begin()

    " Essential
    Plug 'tpope/vim-sensible'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'preservim/nerdtree'

    " Git
    Plug 'tpope/vim-fugitive'

    " Syntax
    Plug 'sheerun/vim-polyglot'

    " Theme
    Plug 'morhetz/gruvbox'

call plug#end()

" Settings
colorscheme gruvbox
set background=dark

" Mappings
nnoremap <C-p> :FZF<CR>
nnoremap <C-n> :NERDTreeToggle<CR>
EOF

    mkdir -p ~/.vim/undodir

    echo "   ✅ Vim 고급 설정 완료"
    echo "   💡 Vim에서 :PlugInstall 실행 필요"
}

# Git 설정
apply_git() {
    echo "🌐 Git 설정 적용 중..."

    # 사용자 정보 입력 받기
    echo "   Git 사용자 정보를 입력하세요:"
    read -p "   이름 [NixOS User]: " git_name
    read -p "   이메일 [nixos@localhost]: " git_email

    git_name=${git_name:-"NixOS User"}
    git_email=${git_email:-"nixos@localhost"}

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch "main"
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global credential.helper store

    # baleen37 스타일 알리어스
    git config --global alias.a "add"
    git config --global alias.c "commit"
    git config --global alias.co "checkout"
    git config --global alias.cp "cherry-pick"
    git config --global alias.diff "diff"
    git config --global alias.l "log --oneline --graph --decorate"
    git config --global alias.p "push"
    git config --global alias.s "status"
    git config --global alias.t "tag"

    echo "   ✅ Git 설정 완료"
    echo "   👤 사용자: $git_name"
    echo "   📧 이메일: $git_email"
}

# Claude Code 설정
apply_claude() {
    echo "🤖 Claude Code 설정 적용 중..."

    if [ -d ~/.claude ]; then
        echo "   ✅ Claude Code 설정 디렉토리 존재"

        # dotfiles의 Claude 설정 연결
        if [ -d "$DOTFILES_DIR/users/shared/.config/claude" ]; then
            echo "   🔗 dotfiles Claude 설정 연결 중..."

            # 기존 설정 백업
            for file in ~/.claude/settings.json; do
                if [ -f "$file" ]; then
                    cp "$file" "$file.backup"
                fi
            done

            # 심볼릭 링크 생성
            for file in "$DOTFILES_DIR"/users/shared/.config/claude/*; do
                if [ -f "$file" ]; then
                    ln -sf "$file" ~/.claude/
                fi
            done

            echo "   ✅ Claude 설정 연결 완료"
        fi

        # CLI 단축키 설정
        if command -v claude &> /dev/null; then
            # zsh에 단축키 추가
            if [ -f ~/.zshrc ]; then
                grep -q "alias cc=" ~/.zshrc || echo 'alias cc="claude --dangerously-skip-permissions"' >> ~/.zshrc
                echo "   ✅ Claude CLI 단축키 설정 완료"
            fi
        else
            echo "   ⚠️  Claude CLI가 설치되지 않음"
        fi
    else
        echo "   ℹ️  Claude Code가 설치되지 않음"
        echo "   💡 설치 방법: npm install -g @anthropic-ai/claude-cli"
    fi
}

# 개발 환경 설정
apply_dev_env() {
    echo "📦 개발 환경 설정 적용 중..."

    # PATH 설정
    if [ -f ~/.zshrc ]; then
        # 기존 PATH 설정 확인
        if ! grep -q "npm-global" ~/.zshrc; then
            cat >> ~/.zshrc << 'EOF'

# Development PATH configuration (from baleen37/dotfiles)
export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
export PATH=$HOME/.local/share/bin:$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/go/bin:$PATH

# Node.js
if command -v npm &> /dev/null; then
    export npm_config_prefix=~/.npm-global
fi

# Python
export PIP_USER=true
EOF
            echo "   ✅ 개발 환경 PATH 설정 완료"
        fi
    fi

    # 개발 도구 별칭 추가
    if [ -f ~/.zshrc ]; then
        cat >> ~/.zshrc << 'EOF'

# Development aliases
if command -v docker &> /dev/null; then
    alias d='docker'
    alias dc='docker-compose'
fi

if command -v kubectl &> /dev/null; then
    alias k='kubectl'
fi
EOF
        echo "   ✅ 개발 도우미 별칭 설정 완료"
    fi
}

# 전체 적용
apply_all() {
    echo "🛠️  전체 기능 적용 중..."
    apply_dev_tools
    apply_shell_env
    apply_editor
    apply_git
    apply_claude
    apply_dev_env
    echo "   ✅ 전체 기능 적용 완료"
}

# 메인 루프
main() {
    cd "$DOTFILES_DIR"

    while true; do
        show_menu
        read -p "선택: " choice
        echo ""

        case $choice in
            1)
                apply_dev_tools
                ;;
            2)
                apply_shell_env
                ;;
            3)
                apply_editor
                ;;
            4)
                apply_git
                ;;
            5)
                apply_claude
                ;;
            6)
                apply_dev_env
                ;;
            7)
                apply_all
                ;;
            8)
                show_help
                ;;
            q|Q)
                echo "👋 종료합니다."
                break
                ;;
            *)
                echo "❌ 잘못된 선택입니다."
                ;;
        esac

        echo ""
        echo "계속하려면 Enter를 누르세요..."
        read
        clear
    done
}

# 스크립트 실행
main "$@"