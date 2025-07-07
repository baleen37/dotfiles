{ pkgs, lib, ... }:

let
  # Nix 기반 키보드 설정 모듈 import
  keyboardSettings = import ../../lib/keyboard-input-settings.nix { inherit pkgs lib; };

in
# Nix 구현 테스트
pkgs.runCommand "keyboard-input-settings-nix-test" {
  meta = {
    description = "Keyboard input settings test (Nix implementation TDD)";
  };
} ''
  echo "🧪 Nix 기반 키보드 입력 설정 테스트"
  echo "===================================="
  echo ""

  # Red Phase: 현재는 설정이 없으므로 검증이 실패해야 함
  echo "🔴 Red Phase: 현재 키보드 설정 상태 확인..."
  echo ""

  # 테스트 환경 설정
  export HOME=$(mktemp -d)
  mkdir -p "$HOME/Library/Preferences"

  # 초기 상태에서는 plist 파일이 없어야 함
  if [ -f "$HOME/Library/Preferences/com.apple.HIToolbox.plist" ]; then
    echo "❌ 예상치 못함: plist 파일이 이미 존재"
    exit 1
  else
    echo "✅ 예상됨: plist 파일이 없음 (초기 상태)"
  fi

  # 검증 스크립트가 실패하는지 확인 (Red Phase)
  echo ""
  echo "검증 스크립트 실행 (실패 예상)..."

  if ${keyboardSettings.verify} 2>/dev/null; then
    echo "❌ 예상치 못한 성공 - 검증이 실패해야 합니다"
    exit 1
  else
    echo "✅ 예상된 실패 - Red Phase 완료"
  fi

  echo ""
  echo "🟢 Green Phase: 설정 적용 및 검증..."
  echo ""

  # 설정 적용
  echo "키보드 설정 적용 중..."
  ${keyboardSettings.configure}

  # 설정 적용 후 파일 존재 확인
  if [ -f "$HOME/Library/Preferences/com.apple.HIToolbox.plist" ]; then
    echo "✅ plist 파일 생성됨"
  else
    echo "❌ plist 파일 생성 실패"
    exit 1
  fi

  # 설정 검증
  echo ""
  echo "설정 검증 중..."
  if ${keyboardSettings.verify}; then
    echo "✅ 설정 검증 성공"
  else
    echo "❌ 설정 검증 실패"
    exit 1
  fi

  echo ""
  echo "🔵 Refactor Phase: 코드 품질 검증..."
  echo ""

  # 테스트 스크립트 실행
  echo "통합 테스트 실행 중..."
  if ${keyboardSettings.test}; then
    echo "✅ 모든 테스트 통과"
  else
    echo "❌ 일부 테스트 실패"
    exit 1
  fi

  echo ""
  echo "🎉 TDD 전체 사이클 완료 (Nix 구현)!"
  echo "====================================="
  echo "✅ Red Phase: 실패하는 테스트 작성 및 확인"
  echo "✅ Green Phase: 최소 구현으로 테스트 통과"
  echo "✅ Refactor Phase: 코드 품질 및 구조 개선"
  echo ""
  echo "🔧 Nix 구현의 장점:"
  echo "• 순수 함수형 접근법"
  echo "• libplist 기반 안전한 plist 조작"
  echo "• 선언적 설정 관리"
  echo "• 자동 백업 및 복구"
  echo "• 강타입 시스템의 안전성"
  echo ""
  echo "🎯 사용법: Shift+Cmd+Space로 한영 전환"

  touch $out
''
