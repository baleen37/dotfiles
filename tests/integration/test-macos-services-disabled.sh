#!/usr/bin/env bash
# TDD Test: macOS Services 비활성화 검증
# Red phase: 실패하는 테스트 작성

set -euo pipefail

# 테스트 설정
TEST_NAME="macOS Services Disabled Test"
SERVICE_KEY="com.apple.Terminal - Search man Page Index in Terminal - searchManPages" # pragma: allowlist secret

echo "🔴 TDD Red Phase: $TEST_NAME"
echo "================================================"

# Test 1: 서비스가 비활성화되었는지 확인
test_service_disabled() {
  echo "Test 1: Checking if 'Search man Page Index in Terminal' service is disabled..."

  # pbs NSServicesStatus에서 서비스 상태 확인
  local service_status
  service_status=$(defaults read pbs NSServicesStatus 2>/dev/null | grep -A 10 "$SERVICE_KEY" || echo "")

  if [[ -z $service_status ]]; then
    echo "❌ FAIL: Service not found in NSServicesStatus"
    return 1
  fi

  # enabled_context_menu이 0인지 확인
  if ! echo "$service_status" | grep -q '"enabled_context_menu" = 0'; then
    echo "❌ FAIL: enabled_context_menu is not disabled (should be 0)"
    return 1
  fi

  # enabled_services_menu가 0인지 확인
  if ! echo "$service_status" | grep -q '"enabled_services_menu" = 0'; then
    echo "❌ FAIL: enabled_services_menu is not disabled (should be 0)"
    return 1
  fi

  echo "✅ PASS: Service is properly disabled"
  return 0
}

# Test 2: Shift+Cmd+A 키 조합이 다른 앱에서 사용 가능한지 확인
test_keyboard_shortcut_available() {
  echo "Test 2: Checking if Shift+Cmd+A is available for other apps..."

  # symbolic hotkeys에서 해당 키 조합이 Terminal 서비스에 할당되지 않았는지 확인
  local symbolic_hotkeys
  symbolic_hotkeys=$(defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null || echo "{}")

  # Shift+Cmd+A (parameters: [65, 0, 1179648])에 해당하는 항목이 없거나 비활성화되어 있는지 확인
  if echo "$symbolic_hotkeys" | grep -q "1179648" && echo "$symbolic_hotkeys" | grep -q '"enabled" = 1'; then
    echo "❌ FAIL: Shift+Cmd+A is still assigned to a system service"
    return 1
  fi

  echo "✅ PASS: Shift+Cmd+A is available for other apps"
  return 0
}

# Test 3: 설정이 영구적으로 저장되었는지 확인
test_settings_persistent() {
  echo "Test 3: Checking if settings are persistent..."

  # defaults 명령으로 설정 확인 (더 정확한 방법)
  local service_config
  service_config=$(defaults read pbs NSServicesStatus 2>/dev/null | grep -A 20 "$SERVICE_KEY" || echo "")

  if [[ -z $service_config ]]; then
    echo "❌ FAIL: Service configuration not found in NSServicesStatus"
    return 1
  fi

  # enabled_context_menu과 enabled_services_menu 값 확인
  if ! echo "$service_config" | grep -q '"enabled_context_menu" = 0' ||
    ! echo "$service_config" | grep -q '"enabled_services_menu" = 0'; then
    echo "❌ FAIL: Settings not properly persisted"
    echo "Current config: $service_config"
    return 1
  fi

  echo "✅ PASS: Settings are persistent"
  return 0
}

# 메인 테스트 실행
main() {
  local failed=0

  echo "Starting TDD Red Phase tests (expecting failures)..."
  echo ""

  # 각 테스트 실행하고 결과 수집
  test_service_disabled || failed=$((failed + 1))
  echo ""
  test_keyboard_shortcut_available || failed=$((failed + 1))
  echo ""
  test_settings_persistent || failed=$((failed + 1))
  echo ""

  echo "================================================"
  if [[ $failed -gt 0 ]]; then
    echo "🔴 TDD Red Phase: $failed test(s) failed (as expected)"
    echo "Next: Implement solution to make tests pass (Green phase)"
    exit 1
  else
    echo "✅ All tests passed (solution already exists)"
    exit 0
  fi
}

main "$@"
