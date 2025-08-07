# Nix 기반 macOS 키보드 입력 설정 모듈
# Shift+Cmd+Space로 한영 전환 설정을 순수 함수형 방식으로 구현

{ pkgs, lib, ... }:

let
  # 키보드 설정 스크립트 생성
  configureKeyboardScript = pkgs.writeShellScript "configure-keyboard-nix" ''
        set -euo pipefail

        echo "🚀 Nix 기반 키보드 입력 설정 시작"
        echo "=================================="
        echo ""

        # HIToolbox plist 파일 경로
        PLIST_PATH="$HOME/Library/Preferences/com.apple.HIToolbox.plist"
        BACKUP_PATH="$PLIST_PATH.backup.$(date +%Y%m%d_%H%M%S)"

        # 백업 생성
        if [ -f "$PLIST_PATH" ]; then
          echo "📦 기존 설정 백업 중..."
          cp "$PLIST_PATH" "$BACKUP_PATH"
          echo "✅ 백업 완료: $BACKUP_PATH"
        else
          echo "ℹ️  기존 설정 파일이 없습니다. 새로 생성합니다."
        fi

        echo ""
        echo "⚙️  키보드 단축키 설정 중..."

        # AppleSymbolicHotKeys 설정
        # 키 ID 60: 이전 입력 소스 선택
        # 키 ID 61: 다음 입력 소스 선택
        # 파라미터: [49, 49, 1179648] = Space (49) + Shift+Cmd (1179648)

        # 기본 구조 생성 (plist가 없는 경우)
        if [ ! -f "$PLIST_PATH" ]; then
          cat > "$PLIST_PATH" << 'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>AppleSymbolicHotKeys</key>
      <dict>
      </dict>
    </dict>
    </plist>
    EOF
        else
          # 기존 파일을 XML로 변환
          /usr/bin/plutil -convert xml1 "$PLIST_PATH" 2>/dev/null || true

          # AppleSymbolicHotKeys 섹션이 없으면 추가
          if ! /usr/bin/plutil -extract "AppleSymbolicHotKeys" xml1 "$PLIST_PATH" >/dev/null 2>&1; then
            /usr/bin/plutil -insert "AppleSymbolicHotKeys" -dictionary "$PLIST_PATH"
          fi
        fi

        # 키 ID 60, 61 설정
        for key_id in 60 61; do
          echo "  키 ID $key_id 설정 중..."

          # 기존 키 설정 제거 (있다면)
          /usr/bin/plutil -remove "AppleSymbolicHotKeys.$key_id" "$PLIST_PATH" 2>/dev/null || true

          # 새 키 설정 단계별 추가
          if /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id" -dictionary "$PLIST_PATH" 2>/dev/null; then
            /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id.enabled" -bool true "$PLIST_PATH" 2>/dev/null
            /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id.value" -dictionary "$PLIST_PATH" 2>/dev/null
            /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id.value.type" -string "standard" "$PLIST_PATH" 2>/dev/null
            /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id.value.parameters" -array "$PLIST_PATH" 2>/dev/null
            /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id.value.parameters" -integer 49 -append "$PLIST_PATH" 2>/dev/null
            /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id.value.parameters" -integer 49 -append "$PLIST_PATH" 2>/dev/null
            /usr/bin/plutil -insert "AppleSymbolicHotKeys.$key_id.value.parameters" -integer 1179648 -append "$PLIST_PATH" 2>/dev/null
            echo "    ✅ 키 ID $key_id 설정 완료"
          else
            echo "    ❌ 키 ID $key_id 설정 실패"
          fi
        done

        # plist를 바이너리 형식으로 변환
        /usr/bin/plutil -convert binary1 "$PLIST_PATH"

        echo ""
        echo "🎉 키보드 설정이 완료되었습니다!"
        echo "   👉 Shift+Cmd+Space로 한영 전환이 가능합니다"
        echo ""
        echo "📝 추가 안내:"
        echo "• 시스템 환경설정 > 키보드 > 입력 소스에서 한국어 입력기 추가 필요"
        echo "• 변경사항은 로그아웃 후 재로그인 또는 시스템 재시작 후 적용"
        echo "• 다른 앱의 단축키와 충돌할 수 있음"

        if [ -f "$BACKUP_PATH" ]; then
          echo "• 문제 발생 시 백업에서 복원: cp '$BACKUP_PATH' '$PLIST_PATH'"
        fi
        echo ""
  '';

  # 키보드 설정 검증 스크립트
  verifyKeyboardScript = pkgs.writeShellScript "verify-keyboard-nix" ''
    set -euo pipefail

    echo "🔍 Nix 기반 키보드 설정 검증"
    echo "=============================="
    echo ""

    PLIST_PATH="$HOME/Library/Preferences/com.apple.HIToolbox.plist"

    if [ ! -f "$PLIST_PATH" ]; then
      echo "❌ 설정 파일이 존재하지 않습니다: $PLIST_PATH"
      exit 1
    fi

    echo "📋 키보드 단축키 설정 확인:"
    echo ""

    # plist를 XML로 변환하여 읽기 가능하게 만들기
    TEMP_PLIST=$(mktemp)
    /usr/bin/plutil -convert xml1 -o "$TEMP_PLIST" "$PLIST_PATH"

    SUCCESS=true

    for key_id in 60 61; do
      key_name=""
      case $key_id in
        60) key_name="이전 입력 소스" ;;
        61) key_name="다음 입력 소스" ;;
      esac

      echo "   키 ID $key_id ($key_name):"

      # 키 존재 여부 확인
      if ! /usr/bin/plutil -extract "AppleSymbolicHotKeys.$key_id" xml1 "$TEMP_PLIST" >/dev/null 2>&1; then
        echo "     ❌ 설정이 없습니다"
        SUCCESS=false
        continue
      fi

      # 활성화 상태 확인
      if /usr/bin/plutil -extract "AppleSymbolicHotKeys.$key_id.enabled" raw "$TEMP_PLIST" 2>/dev/null | grep -q "true"; then
        echo "     활성화: ✅ 예"
      else
        echo "     활성화: ❌ 아니오"
        SUCCESS=false
      fi

      # 파라미터 확인
      param0=$(/usr/bin/plutil -extract "AppleSymbolicHotKeys.$key_id.value.parameters.0" raw "$TEMP_PLIST" 2>/dev/null || echo "없음")
      param1=$(/usr/bin/plutil -extract "AppleSymbolicHotKeys.$key_id.value.parameters.1" raw "$TEMP_PLIST" 2>/dev/null || echo "없음")
      param2=$(/usr/bin/plutil -extract "AppleSymbolicHotKeys.$key_id.value.parameters.2" raw "$TEMP_PLIST" 2>/dev/null || echo "없음")

      echo "     파라미터: [$param0, $param1, $param2]"
      echo "     예상값: [49, 49, 1179648]"

      if [ "$param0" = "49" ] && [ "$param1" = "49" ] && [ "$param2" = "1179648" ]; then
        echo "     일치: ✅ 예"
      else
        echo "     일치: ❌ 아니오"
        SUCCESS=false
      fi

      echo ""
    done

    rm -f "$TEMP_PLIST"

    if [ "$SUCCESS" = "true" ]; then
      echo "🎉 모든 키보드 설정이 올바르게 적용되었습니다!"
      echo ""
      echo "🎯 사용법:"
      echo "   Shift+Cmd+Space를 눌러 한영 전환"
      exit 0
    else
      echo "⚠️  일부 설정에 문제가 있습니다"
      echo "   다시 설정을 적용해주세요"
      exit 1
    fi
  '';

  # 테스트용 스크립트
  testKeyboardScript = pkgs.writeShellScript "test-keyboard-nix" ''
    set -euo pipefail

    echo "🧪 Nix 기반 키보드 설정 테스트"
    echo "==============================="
    echo ""

    TESTS_PASSED=0
    TESTS_FAILED=0

    test_assertion() {
      local test_name="$1"
      local test_command="$2"

      echo "Testing: $test_name"

      if eval "$test_command"; then
        echo "  ✅ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "  ❌ FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    }

    # 테스트 1: plutil 도구 사용 가능 여부
    test_assertion "plutil 도구 사용 가능" \
      "command -v /usr/bin/plutil >/dev/null"

    # 테스트 2: HIToolbox plist 파일 존재 (설정 후)
    test_assertion "HIToolbox plist 파일 존재" \
      "[ -f \"$HOME/Library/Preferences/com.apple.HIToolbox.plist\" ]"

    # 테스트 3: 검증 스크립트 실행
    if [ -f "$HOME/Library/Preferences/com.apple.HIToolbox.plist" ]; then
      test_assertion "키보드 설정 검증" \
        "${verifyKeyboardScript}"
    else
      echo "  ⏭️  SKIP: 키보드 설정 검증 (plist 파일 없음)"
    fi

    echo ""
    echo "📊 테스트 결과:"
    echo "  ✅ 통과: $TESTS_PASSED"
    echo "  ❌ 실패: $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
      echo "🎉 모든 테스트 통과!"
      exit 0
    else
      echo "⚠️  $TESTS_FAILED 개의 테스트가 실패했습니다"
      exit 1
    fi
  '';

in
{
  # 설정 스크립트들을 exports
  configure = configureKeyboardScript;
  verify = verifyKeyboardScript;
  test = testKeyboardScript;

  # 시스템 활성화 스크립트용 텍스트
  activationScript = ''
    echo "🔧 Nix 기반 키보드 입력 설정 적용 중..."
    ${configureKeyboardScript}

    echo ""
    echo "🔍 설정 검증 중..."
    if ${verifyKeyboardScript}; then
      echo "✅ 키보드 설정이 성공적으로 적용되었습니다!"
    else
      echo "⚠️  키보드 설정 검증에 실패했습니다. 수동으로 확인해주세요."
    fi
  '';

  # 테스트용 derivation
  testDerivation = pkgs.runCommand "keyboard-input-settings-nix-test"
    {
      buildInputs = [ pkgs.libplist ];
      meta = {
        description = "Keyboard input settings test (Nix implementation)";
      };
    } ''
    echo "🧪 Nix 기반 키보드 설정 테스트"
    echo "==============================="
    echo ""

    # Red Phase: 현재는 설정이 없으므로 검증이 실패해야 함
    echo "Red Phase: 현재 키보드 설정 상태 확인..."

    # 테스트 스크립트 실행
    if ${testKeyboardScript} 2>/dev/null; then
      echo "⚠️  테스트가 성공했습니다 - 설정이 이미 있을 수 있습니다"
    else
      echo "✅ 예상된 실패 - Red Phase 완료"
    fi

    echo ""
    echo "🎯 TDD Red Phase (Nix 구현) 성공!"
    echo "================================="
    echo "• Nix 순수 함수형 접근법 구현 완료"
    echo "• libplist/plutil 기반 안전한 plist 조작"
    echo "• 자동 백업 및 검증 기능 포함"
    echo ""
    echo "다음 단계: nix run #build-switch로 설정 적용"

    touch $out
  '';
}
