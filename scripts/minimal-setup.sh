#!/bin/bash

# 최소한의 dotfiles 기능만 적용하는 스크립트

echo "🔧 최소한의 dotfiles 설정 적용 중..."

# 1. 기본 알리아스 설정
echo "   알리아스 설정 추가..."
cat >> ~/.bashrc << 'EOF'

# Minimal dotfiles aliases
alias la='ls -la --color=auto'
alias ll='ls -l --color=auto'
alias ga='git add'
alias gc='git commit'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'

# WSL helpers
if command -v wslpath &> /dev/null; then
    alias winpath='wslpath -w'
    alias unixpath='wslpath -u'
fi

# Dotfiles shortcut
if [ -d ~/dotfiles ]; then
    alias dotfiles='cd ~/dotfiles'
fi

# Environment
export EDITOR="vim"
export PATH=$HOME/.npm-global/bin:$HOME/.local/bin:$PATH
EOF

echo "   ✅ 최소 설정 완료"
echo "   💡 적용하려면: source ~/.bashrc"
echo "   💡 Zsh를 사용하려면: sudo nixos-rebuild switch (zsh 추가 후)"