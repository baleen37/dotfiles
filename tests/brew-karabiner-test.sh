#!/bin/bash

# Karabiner-Elements Nix 설치 상태 테스트
echo "🧪 Karabiner-Elements Nix 관리 상태 테스트"

# 테스트 1: Nix에서 karabiner-elements 관리 확인
echo "1. Nix 설정에서 karabiner-elements 확인..."
if grep -q "karabiner-elements-v14" /Users/baleen/dev/dotfiles/modules/darwin/home-manager.nix; then
    echo "  ✓ karabiner-elements-v14가 nix 설정에 있음"
else
    echo "  ❌ karabiner-elements-v14가 nix 설정에 없음"
    exit 1
fi

# 테스트 2: brew cask에서 karabiner-elements 부재 확인 (현재 nix로 관리)
echo "2. Brew cask 설정 확인..."
if ! grep -q "karabiner-elements" /Users/baleen/dev/dotfiles/modules/darwin/casks.nix; then
    echo "  ✓ karabiner-elements가 brew cask에 없음 (nix로 관리 중)"
else
    echo "  ❌ karabiner-elements가 brew cask에 있음 (중복 관리)"
    exit 1
fi

# 테스트 3: nix로 설치된 karabiner-elements 확인
echo "3. Nix로 설치된 karabiner-elements 확인..."
if [ -d "/Applications/Karabiner-Elements.app" ]; then
    if [ -L "/Applications/Karabiner-Elements.app" ]; then
        echo "  ✓ karabiner-elements가 심볼릭 링크로 존재 (nix 관리)"
        echo "  링크 대상: $(readlink '/Applications/Karabiner-Elements.app')"
    else
        echo "  ⚠️  karabiner-elements가 실제 앱으로 존재 (brew 설치일 가능성)"
    fi
else
    echo "  ❌ karabiner-elements가 설치되지 않음"
    exit 1
fi

# 테스트 4: 설정 파일 경로 확인
echo "4. 설정 파일 경로 확인..."
if [ -f "$HOME/.config/karabiner/karabiner.json" ]; then
    echo "  ✓ 설정 파일이 올바른 경로에 있음"
else
    echo "  ❌ 설정 파일이 올바른 경로에 없음"
    exit 1
fi

# 테스트 5: 기존 설정 내용 확인
echo "5. 기존 설정 내용 확인..."
if grep -q "Right Command" "$HOME/.config/karabiner/karabiner.json"; then
    echo "  ✓ 기존 설정 내용이 보존됨"
else
    echo "  ❌ 기존 설정 내용이 보존되지 않음"
    exit 1
fi

echo "✅ 모든 테스트 통과"
