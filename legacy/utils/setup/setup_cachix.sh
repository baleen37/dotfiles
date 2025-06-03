#!/bin/sh

# Cachix 설치 및 설정
if ! command -v cachix &> /dev/null; then
  echo "Cachix 설치 중..."
  nix-env -iA cachix -f https://cachix.org/api/v1/install
fi

# 캐시 활성화
echo "Cachix 캐시 활성화 중..."
cachix use baleen-dotfiles

# Nix 캐시 설정 확인
echo "Nix 캐시 설정 확인 중..."
cat ~/.config/nix/nix.conf || true

echo "Cachix 설정이 완료되었습니다."