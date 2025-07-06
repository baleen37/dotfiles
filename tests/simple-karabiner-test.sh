#!/bin/bash

# 간단한 Karabiner-Elements 테스트
echo "🧪 Karabiner-Elements 연동 테스트"

# 테스트 1: 필수 경로 존재
echo "1. 필수 경로 확인..."
if [ -d "/nix/store/vfdwh7882bnr8jnfq66f4fk5cksnigy1-karabiner-elements-14.13.0" ]; then
    echo "  ✓ Karabiner nix store 경로 존재"
else
    echo "  ❌ Karabiner nix store 경로 없음"
    exit 1
fi

# 테스트 2: Nix Apps 디렉토리 확인
echo "2. Nix Apps 디렉토리 확인..."
if [ -d "/Applications/Nix Apps" ]; then
    echo "  ✓ Nix Apps 디렉토리 존재"
else
    echo "  ❌ Nix Apps 디렉토리 없음 - 생성 필요"
fi

# 테스트 3: 심볼릭 링크 확인
echo "3. 심볼릭 링크 확인..."
if [ -L "/Applications/Nix Apps/Karabiner-Elements.app" ]; then
    echo "  ✓ Nix Apps 심볼릭 링크 존재"
    echo "  링크 대상: $(readlink '/Applications/Nix Apps/Karabiner-Elements.app')"
else
    echo "  ❌ Nix Apps 심볼릭 링크 없음"
fi

if [ -L "/Applications/Karabiner-Elements.app" ]; then
    echo "  ✓ 메인 앱 심볼릭 링크 존재"
    echo "  링크 대상: $(readlink '/Applications/Karabiner-Elements.app')"
else
    echo "  ❌ 메인 앱 심볼릭 링크 없음"
fi

echo "테스트 완료"
