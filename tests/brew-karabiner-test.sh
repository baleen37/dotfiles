#!/bin/bash

# TDD Red Phase: Brew Karabiner-Elements 설치 테스트
echo "🧪 Brew Karabiner-Elements 설치 테스트"

# 테스트 1: brew cask에 karabiner-elements 존재 확인
echo "1. Brew cask 설정 확인..."
if grep -q "karabiner-elements" /Users/baleen/dotfiles/modules/platform/darwin/casks.nix; then
    echo "  ✓ karabiner-elements가 casks.nix에 있음"
else
    echo "  ❌ karabiner-elements가 casks.nix에 없음"
    exit 1
fi

# 테스트 2: nix 설정에서 karabiner-elements 제거 확인
echo "2. Nix 설정에서 karabiner-elements 제거 확인..."
if ! grep -q "karabiner-elements-v14" /Users/baleen/dotfiles/modules/platform/darwin/home-manager.nix; then
    echo "  ✓ karabiner-elements-v14가 nix 설정에서 제거됨"
else
    echo "  ❌ karabiner-elements-v14가 여전히 nix 설정에 있음"
    exit 1
fi

# 테스트 3: brew로 설치된 karabiner-elements 확인
echo "3. Brew로 설치된 karabiner-elements 확인..."
if [ -d "/Applications/Karabiner-Elements.app" ]; then
    if [ -L "/Applications/Karabiner-Elements.app" ]; then
        echo "  ⚠️  karabiner-elements가 심볼릭 링크로 존재 (nix 설정 미완전 제거)"
        echo "  링크 대상: $(readlink '/Applications/Karabiner-Elements.app')"
    else
        echo "  ✓ karabiner-elements가 brew로 설치됨 (실제 앱)"
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
