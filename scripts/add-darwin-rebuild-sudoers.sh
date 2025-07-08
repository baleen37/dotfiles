#!/bin/bash
# add-darwin-rebuild-sudoers.sh
# Claude Code / nix-darwin build-switch 권한 설정 스크립트

set -euo pipefail

SUDOERS_FILE="/etc/sudoers.d/darwin-rebuild"
SUDOERS_CONTENT="# Darwin rebuild permissions for Claude Code
%admin ALL=(ALL) NOPASSWD: /nix/store/*/sw/bin/darwin-rebuild
%wheel ALL=(ALL) NOPASSWD: /nix/store/*/sw/bin/darwin-rebuild"

# 권한 확인
if [[ $EUID -ne 0 ]]; then
   echo "이 스크립트는 sudo로 실행해야 합니다."
   echo "사용법: sudo ./scripts/add-darwin-rebuild-sudoers.sh"
   exit 1
fi

# sudoers.d 디렉토리 생성
mkdir -p /etc/sudoers.d

# 기존 파일 백업
if [[ -f "$SUDOERS_FILE" ]]; then
    cp "$SUDOERS_FILE" "${SUDOERS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "기존 설정 파일을 백업했습니다: ${SUDOERS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 설정 파일 생성
echo "$SUDOERS_CONTENT" > "$SUDOERS_FILE"

# 권한 설정
chmod 0440 "$SUDOERS_FILE"

# 문법 검사
if visudo -c -f "$SUDOERS_FILE"; then
    echo "✅ sudoers 설정이 성공적으로 추가되었습니다."
    echo "파일 위치: $SUDOERS_FILE"
    echo ""
    echo "이제 다음 명령을 패스워드 없이 실행할 수 있습니다:"
    echo "  nix run #build-switch"
else
    echo "❌ sudoers 설정에 오류가 있습니다. 파일을 제거합니다."
    rm -f "$SUDOERS_FILE"
    exit 1
fi
