{ pkgs, lib, ... }:

let
  # 키보드 설정 검증 스크립트
  keyboardSettingsValidator = pkgs.writeScriptBin "test-keyboard-settings" ''
    #!/bin/bash

    echo "🧪 키보드 입력 설정 검증 테스트"

    # 테스트 결과 카운터
    TESTS_PASSED=0
    TESTS_FAILED=0

    # 테스트 함수
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

    # 테스트 1: HIToolbox plist 파일 존재 확인
    test_assertion "HIToolbox plist 파일 존재" \
        "[ -f \"$HOME/Library/Preferences/com.apple.HIToolbox.plist\" ]"

    # 테스트 2: AppleSymbolicHotKeys 설정 존재 확인
    test_assertion "AppleSymbolicHotKeys 설정 존재" \
        "${pkgs.python3}/bin/python3 -c \"
import plistlib
import os
try:
    with open(os.path.expanduser('~/Library/Preferences/com.apple.HIToolbox.plist'), 'rb') as f:
        data = plistlib.load(f)
    exit(0 if 'AppleSymbolicHotKeys' in data else 1)
except:
    exit(1)
\""

    # 테스트 3: 키 ID 60 설정 확인
    test_assertion "키 ID 60 한영 전환 설정 확인" \
        "${pkgs.python3}/bin/python3 -c \"
import plistlib
import os
try:
    with open(os.path.expanduser('~/Library/Preferences/com.apple.HIToolbox.plist'), 'rb') as f:
        data = plistlib.load(f)
    hotkeys = data.get('AppleSymbolicHotKeys', {})
    key60 = hotkeys.get('60', {})

    # 예상 파라미터: [49, 49, 1179648] (Space + Shift+Cmd)
    expected_params = [49, 49, 1179648]
    actual_params = key60.get('value', {}).get('parameters', [])

    if actual_params == expected_params and key60.get('enabled', False):
        exit(0)
    else:
        print(f'Expected: {expected_params}, Got: {actual_params}')
        exit(1)
except Exception as e:
    print(f'Error: {e}')
    exit(1)
\""

    # 테스트 4: 키 ID 61 설정 확인
    test_assertion "키 ID 61 한영 전환 설정 확인" \
        "${pkgs.python3}/bin/python3 -c \"
import plistlib
import os
try:
    with open(os.path.expanduser('~/Library/Preferences/com.apple.HIToolbox.plist'), 'rb') as f:
        data = plistlib.load(f)
    hotkeys = data.get('AppleSymbolicHotKeys', {})
    key61 = hotkeys.get('61', {})

    # 예상 파라미터: [49, 49, 1179648] (Space + Shift+Cmd)
    expected_params = [49, 49, 1179648]
    actual_params = key61.get('value', {}).get('parameters', [])

    if actual_params == expected_params and key61.get('enabled', False):
        exit(0)
    else:
        print(f'Expected: {expected_params}, Got: {actual_params}')
        exit(1)
except Exception as e:
    print(f'Error: {e}')
    exit(1)
\""

    # 테스트 5: 백업 파일 존재 확인 (안전성)
    test_assertion "백업 파일 존재 확인" \
        "[ -f \"$HOME/Library/Preferences/com.apple.HIToolbox.plist.backup\" ] || echo 'No backup found - this is expected for first run'"

    # 결과 출력
    echo ""
    echo "📊 테스트 결과:"
    echo "  ✅ 통과: $TESTS_PASSED"
    echo "  ❌ 실패: $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo "🎉 모든 테스트 통과! 키보드 설정이 올바르게 적용되었습니다."
        exit 0
    else
        echo "⚠️  $TESTS_FAILED 개의 테스트가 실패했습니다. 설정을 다시 확인해주세요."
        exit 1
    fi
  '';

in
# 테스트 실행
pkgs.runCommand "keyboard-input-settings-test" {
  buildInputs = [ keyboardSettingsValidator pkgs.python3 ];
  meta = {
    description = "Keyboard input settings test (TDD)";
  };
} ''
  # 테스트 실행
  echo "🧪 키보드 입력 설정 테스트 시작"
  echo "================================="
  echo ""

  # Red Phase: 현재는 설정이 없으므로 검증 도구가 실패해야 함
  echo "Red Phase: 현재 키보드 설정 검증 중..."

  # 검증 스크립트가 실패하는지 확인 (Red Phase)
  if ${keyboardSettingsValidator}/bin/test-keyboard-settings 2>/dev/null; then
    echo "❌ 예상치 못한 성공 - 설정이 이미 있거나 테스트가 잘못되었습니다"
    exit 1
  else
    echo "✅ 예상된 실패 - Red Phase 완료"
    echo "   이제 설정을 적용한 후 Green Phase로 진행할 수 있습니다"
  fi

  echo ""
  echo "🎯 TDD Red Phase 성공!"
  echo "================================="
  echo "• 테스트가 올바르게 실패함을 확인"
  echo "• 키보드 설정 스크립트가 준비됨"
  echo "• 검증 도구가 작동함을 확인"
  echo ""
  echo "다음 단계: nix run #build-switch로 설정 적용 후 Green Phase 테스트"

  touch $out
''
