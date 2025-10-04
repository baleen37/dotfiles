#!/usr/bin/env bash
# 동적 GUI 앱 링킹 시스템 v2.0 단위 테스트
# TDD 테스트: 완전 동적 감지 및 링킹 기능 테스트

set -euo pipefail

# 테스트 설정
TEST_DIR="/tmp/dynamic-nix-app-links-test"
FAKE_NIX_STORE="$TEST_DIR/fake-nix-store"
FAKE_HOME_APPS="$TEST_DIR/fake-home/Applications"
FAKE_PROFILE="$TEST_DIR/fake-profile"

# 동적 테스트 초기화
setup_dynamic_test() {
  rm -rf "$TEST_DIR"
  mkdir -p "$FAKE_NIX_STORE"
  mkdir -p "$FAKE_HOME_APPS"
  mkdir -p "$FAKE_PROFILE"

  # 1. 전용 처리 앱들 생성
  mkdir -p "$FAKE_NIX_STORE/karabiner-elements-14.13.0/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements.app"
  mkdir -p "$FAKE_NIX_STORE/wezterm-unstable-2025-08-14/Applications/WezTerm.app"

  # 2. 동적 감지될 일반 GUI 앱들 생성
  mkdir -p "$FAKE_NIX_STORE/keepassxc-2.7.10/Applications/KeePassXC.app"
  mkdir -p "$FAKE_NIX_STORE/emacs-30.1/Applications/Emacs.app"
  mkdir -p "$FAKE_NIX_STORE/alacritty-0.15.1/Applications/Alacritty.app"
  mkdir -p "$FAKE_NIX_STORE/google-chrome-138.0/Applications/Google Chrome.app"

  # 3. 제외되어야 할 Qt 개발 도구들
  mkdir -p "$FAKE_NIX_STORE/qttools-5.15.17-bin/bin/Assistant.app"
  mkdir -p "$FAKE_NIX_STORE/qttools-5.15.17-bin/bin/Designer.app"
  mkdir -p "$FAKE_NIX_STORE/qtdeclarative-5.15.17-bin/bin/qml.app"

  # 4. Profile에 있는 앱들
  mkdir -p "$FAKE_PROFILE/Applications/Syncthing.app"
  mkdir -p "$FAKE_PROFILE/Applications/Spotify.app"

  # 앱별 식별 파일 생성
  echo "Karabiner v14" >"$FAKE_NIX_STORE/karabiner-elements-14.13.0/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements.app/info.txt"
  echo "WezTerm" >"$FAKE_NIX_STORE/wezterm-unstable-2025-08-14/Applications/WezTerm.app/info.txt"
  echo "KeePassXC" >"$FAKE_NIX_STORE/keepassxc-2.7.10/Applications/KeePassXC.app/info.txt"
  echo "Emacs" >"$FAKE_NIX_STORE/emacs-30.1/Applications/Emacs.app/info.txt"
  echo "Alacritty" >"$FAKE_NIX_STORE/alacritty-0.15.1/Applications/Alacritty.app/info.txt"
  echo "Chrome" >"$FAKE_NIX_STORE/google-chrome-138.0/Applications/Google Chrome.app/info.txt"
  echo "Assistant" >"$FAKE_NIX_STORE/qttools-5.15.17-bin/bin/Assistant.app/info.txt"
  echo "QML" >"$FAKE_NIX_STORE/qtdeclarative-5.15.17-bin/bin/qml.app/info.txt"
  echo "Syncthing" >"$FAKE_PROFILE/Applications/Syncthing.app/info.txt"
  echo "Spotify" >"$FAKE_PROFILE/Applications/Spotify.app/info.txt"
}

# 실제 구현 로드
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

# 테스트 1: 동적 GUI 앱 감지 테스트
test_dynamic_app_discovery() {
  echo "🧪 Test 1: Dynamic GUI app discovery should find all Applications/*.app"

  setup_dynamic_test

  if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1; then
    local discovered_apps=0
    local expected_apps=("WezTerm.app" "KeePassXC.app" "Emacs.app" "Alacritty.app" "Google Chrome.app")

    for app in "${expected_apps[@]}"; do
      if [ -L "$FAKE_HOME_APPS/$app" ] && [ -e "$FAKE_HOME_APPS/$app" ]; then
        ((discovered_apps++))
      else
        echo "❌ Missing: $app"
      fi
    done

    if [ $discovered_apps -eq ${#expected_apps[@]} ]; then
      echo "✅ PASS: All $discovered_apps GUI apps dynamically discovered and linked"
      return 0
    else
      echo "❌ FAIL: Only $discovered_apps/${#expected_apps[@]} apps discovered"
      return 1
    fi
  else
    echo "❌ FAIL: link_nix_apps function failed"
    return 1
  fi
}

# 테스트 2: Qt 개발 도구 제외 테스트
test_qt_tools_exclusion() {
  echo "🧪 Test 2: Qt development tools should be excluded from linking"

  setup_dynamic_test

  if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1; then
    local excluded_apps=("Assistant.app" "Designer.app" "qml.app")
    local properly_excluded=0

    for app in "${excluded_apps[@]}"; do
      if [ ! -L "$FAKE_HOME_APPS/$app" ]; then
        ((properly_excluded++))
      else
        echo "❌ Should be excluded but linked: $app"
      fi
    done

    if [ $properly_excluded -eq ${#excluded_apps[@]} ]; then
      echo "✅ PASS: All $properly_excluded Qt tools properly excluded"
      return 0
    else
      echo "❌ FAIL: Only $properly_excluded/${#excluded_apps[@]} tools excluded"
      return 1
    fi
  else
    echo "❌ FAIL: link_nix_apps function failed"
    return 1
  fi
}

# 테스트 3: 특별 처리 앱들 테스트
test_special_handling_apps() {
  echo "🧪 Test 3: Special handling apps (Karabiner, WezTerm) should work correctly"

  setup_dynamic_test

  if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1; then
    # Karabiner 특별 경로 확인
    if [ -L "$FAKE_HOME_APPS/Karabiner-Elements.app" ]; then
      local karabiner_target=$(readlink "$FAKE_HOME_APPS/Karabiner-Elements.app")
      if [[ $karabiner_target == *"Library/Application Support"* ]]; then
        echo "✅ Karabiner: Special path handling working"
      else
        echo "❌ Karabiner: Wrong path - $karabiner_target"
        return 1
      fi
    else
      echo "❌ Karabiner: Not linked"
      return 1
    fi

    # WezTerm 확인
    if [ -L "$FAKE_HOME_APPS/WezTerm.app" ]; then
      echo "✅ WezTerm: Successfully linked"
    else
      echo "❌ WezTerm: Not linked"
      return 1
    fi

    echo "✅ PASS: All special handling apps working correctly"
    return 0
  else
    echo "❌ FAIL: link_nix_apps function failed"
    return 1
  fi
}

# 테스트 4: Profile 앱들 처리 테스트
test_profile_apps_handling() {
  echo "🧪 Test 4: Apps in profile should be processed correctly"

  setup_dynamic_test

  if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1; then
    local profile_apps=("Syncthing.app" "Spotify.app")
    local linked_profile_apps=0

    for app in "${profile_apps[@]}"; do
      if [ -L "$FAKE_HOME_APPS/$app" ] && [ -e "$FAKE_HOME_APPS/$app" ]; then
        ((linked_profile_apps++))
      else
        echo "❌ Profile app not linked: $app"
      fi
    done

    if [ $linked_profile_apps -eq ${#profile_apps[@]} ]; then
      echo "✅ PASS: All $linked_profile_apps profile apps processed correctly"
      return 0
    else
      echo "❌ FAIL: Only $linked_profile_apps/${#profile_apps[@]} profile apps linked"
      return 1
    fi
  else
    echo "❌ FAIL: link_nix_apps function failed"
    return 1
  fi
}

# 테스트 5: 기존 링크 재사용 테스트
test_existing_link_reuse() {
  echo "🧪 Test 5: Existing valid links should be reused for performance"

  setup_dynamic_test

  # 첫 번째 실행
  link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1

  # 기존 링크 타임스탬프 저장
  local original_timestamp
  if [ -L "$FAKE_HOME_APPS/KeePassXC.app" ]; then
    original_timestamp=$(stat -f "%m" "$FAKE_HOME_APPS/KeePassXC.app" 2>/dev/null || stat -c "%Y" "$FAKE_HOME_APPS/KeePassXC.app")
  else
    echo "❌ SETUP FAIL: KeePassXC.app not linked initially"
    return 1
  fi

  sleep 1

  # 두 번째 실행 (기존 링크 재사용되어야 함)
  if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1; then
    local new_timestamp
    if [ -L "$FAKE_HOME_APPS/KeePassXC.app" ]; then
      new_timestamp=$(stat -f "%m" "$FAKE_HOME_APPS/KeePassXC.app" 2>/dev/null || stat -c "%Y" "$FAKE_HOME_APPS/KeePassXC.app")
    fi

    if [ "$original_timestamp" = "$new_timestamp" ]; then
      echo "✅ PASS: Existing valid link was reused (performance optimization)"
      return 0
    else
      echo "❌ FAIL: Link was recreated instead of reused"
      return 1
    fi
  else
    echo "❌ FAIL: Second run failed"
    return 1
  fi
}

# 모든 테스트 실행
run_all_dynamic_tests() {
  echo "🚀 Running Dynamic GUI App Linking Tests v2.0"
  echo "=============================================="

  local failed_tests=0
  local total_tests=5

  if ! test_dynamic_app_discovery; then
    ((failed_tests++))
  fi

  echo ""

  if ! test_qt_tools_exclusion; then
    ((failed_tests++))
  fi

  echo ""

  if ! test_special_handling_apps; then
    ((failed_tests++))
  fi

  echo ""

  if ! test_profile_apps_handling; then
    ((failed_tests++))
  fi

  echo ""

  if ! test_existing_link_reuse; then
    ((failed_tests++))
  fi

  echo ""
  echo "=============================================="

  if [ $failed_tests -eq 0 ]; then
    echo "🟢 Dynamic Linking System Result: All $total_tests tests PASSED!"
    echo "✅ Complete dynamic app discovery working correctly"
    echo "🚀 System ready for any new GUI apps automatically!"
    return 0
  else
    echo "🔴 Test Result: $failed_tests/$total_tests tests failed"
    echo "❌ Dynamic system needs fixes"
    return 1
  fi
}

# 정리
cleanup() {
  rm -rf "$TEST_DIR"
}

# 메인 실행
main() {
  trap cleanup EXIT
  run_all_dynamic_tests
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
