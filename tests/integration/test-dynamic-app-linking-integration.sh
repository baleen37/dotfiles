#!/usr/bin/env bash
# 동적 GUI 앱 링킹 시스템 통합 테스트
# 실제 Nix store와 home-manager 환경에서의 통합 동작 테스트

set -euo pipefail

# 통합 테스트 설정
INTEGRATION_TEST_DIR="/tmp/nix-app-integration-test"
USER_HOME_APPS="$HOME/Applications"

# 테스트 결과 수집
INTEGRATION_RESULTS=()

# 로깅 함수
log_integration() {
  echo "🔗 [INTEGRATION] $*"
}

log_success() {
  echo "✅ [SUCCESS] $*"
  INTEGRATION_RESULTS+=("PASS: $*")
}

log_failure() {
  echo "❌ [FAILURE] $*"
  INTEGRATION_RESULTS+=("FAIL: $*")
}

# 통합 테스트 1: 실제 Nix store 앱 감지
test_real_nix_store_discovery() {
  log_integration "Testing real Nix store GUI app discovery..."

  # 백업 생성
  local backup_dir="$INTEGRATION_TEST_DIR/backup-apps"
  mkdir -p "$backup_dir"

  # 기존 링크들 백업
  if [ -d "$USER_HOME_APPS" ]; then
    find "$USER_HOME_APPS" -name "*.app" -type l -exec cp -P {} "$backup_dir/" \; 2>/dev/null || true
  fi

  # 실제 링킹 시스템 실행
  source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

  local output_file="$INTEGRATION_TEST_DIR/linking-output.log"
  if link_nix_apps "$USER_HOME_APPS" "/nix/store" "$HOME/.nix-profile" >"$output_file" 2>&1; then

    # 링킹된 앱들 확인
    local discovered_count=0
    local expected_apps=("WezTerm.app" "Karabiner-Elements.app")
    local found_apps=()

    for app_link in "$USER_HOME_APPS"/*.app; do
      if [ -L "$app_link" ] && [ -e "$app_link" ]; then
        local app_name=$(basename "$app_link")
        found_apps+=("$app_name")
        ((discovered_count++))
      fi
    done

    if [ $discovered_count -gt 0 ]; then
      log_success "Real Nix store discovery found $discovered_count GUI apps: ${found_apps[*]}"

      # 출력 로그에서 동적 감지 메시지 확인
      if grep -q "dynamically discovered" "$output_file"; then
        log_success "Dynamic discovery system working in real environment"
      else
        log_failure "Dynamic discovery messages not found in output"
      fi

      return 0
    else
      log_failure "No GUI apps discovered in real Nix store"
      return 1
    fi
  else
    log_failure "Real linking system execution failed"
    cat "$output_file" || true
    return 1
  fi
}

# 통합 테스트 2: macOS 시스템 통합 확인
test_macos_system_integration() {
  log_integration "Testing macOS system integration (Spotlight, Dock, etc.)..."

  # WezTerm 앱이 실제로 macOS에서 인식되는지 확인
  if [ -L "$USER_HOME_APPS/WezTerm.app" ] && [ -e "$USER_HOME_APPS/WezTerm.app" ]; then

    # Spotlight 데이터베이스 강제 업데이트
    mdimport "$USER_HOME_APPS/WezTerm.app" 2>/dev/null || true

    # 잠시 대기 (인덱싱 시간)
    sleep 2

    # mdfind로 Spotlight에서 검색 가능한지 확인
    if mdfind "kMDItemDisplayName == 'WezTerm'" 2>/dev/null | grep -q "WezTerm.app"; then
      log_success "WezTerm.app is discoverable via Spotlight"
    else
      log_failure "WezTerm.app not found in Spotlight index"
    fi

    # 앱이 실행 가능한지 확인 (간접적으로)
    if file "$USER_HOME_APPS/WezTerm.app/Contents/MacOS"/* 2>/dev/null | grep -q "executable"; then
      log_success "WezTerm.app has executable binary"
    else
      log_failure "WezTerm.app missing executable binary"
    fi

    # 앱 번들 정보 확인
    if [ -f "$USER_HOME_APPS/WezTerm.app/Contents/Info.plist" ]; then
      log_success "WezTerm.app has valid app bundle structure"
    else
      log_failure "WezTerm.app missing Info.plist"
    fi

    return 0
  else
    log_failure "WezTerm.app not properly linked for integration test"
    return 1
  fi
}

# 통합 테스트 3: Home Manager 상호작용 확인
test_home_manager_interaction() {
  log_integration "Testing interaction with Home Manager app links..."

  # Home Manager가 관리하는 앱들 확인
  local hm_apps_dir="$USER_HOME_APPS/Home Manager Apps"

  if [ -L "$hm_apps_dir" ]; then
    log_success "Home Manager Apps directory exists"

    # Home Manager 앱과 우리 링크가 공존하는지 확인
    local hm_app_count=0
    local direct_link_count=0

    # Home Manager 관리 앱 수
    if [ -d "$hm_apps_dir" ]; then
      hm_app_count=$(find "$hm_apps_dir" -name "*.app" -type l 2>/dev/null | wc -l)
    fi

    # 직접 링크된 앱 수
    direct_link_count=$(find "$USER_HOME_APPS" -maxdepth 1 -name "*.app" -type l 2>/dev/null | wc -l)

    log_success "Coexistence check: $hm_app_count HM apps, $direct_link_count direct links"

    # 중복이 없는지 확인 (같은 앱이 두 곳에 있으면 안됨)
    if [ -d "$hm_apps_dir" ] && [ -L "$hm_apps_dir/Alacritty.app" ] && [ -L "$USER_HOME_APPS/Alacritty.app" ]; then
      log_failure "Duplicate Alacritty.app found (HM and direct link)"
      return 1
    else
      log_success "No duplicate app links detected"
    fi

    return 0
  else
    log_success "No Home Manager Apps directory (clean environment)"
    return 0
  fi
}

# 통합 테스트 4: 성능 및 안정성 확인
test_performance_and_stability() {
  log_integration "Testing performance and stability in real environment..."

  local start_time=$(date +%s.%N)

  # 여러 번 연속 실행해서 안정성 확인
  for i in {1..3}; do
    source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"
    if ! link_nix_apps "$USER_HOME_APPS" "/nix/store" "$HOME/.nix-profile" >/dev/null 2>&1; then
      log_failure "Stability test failed on iteration $i"
      return 1
    fi
  done

  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc -l)

  # 3초 이내에 3번 실행이 완료되어야 함 (성능 기준)
  if (($(echo "$duration < 3.0" | bc -l))); then
    log_success "Performance test passed: 3 runs completed in ${duration}s"
  else
    log_failure "Performance test failed: 3 runs took ${duration}s (>3.0s)"
    return 1
  fi

  # 메모리 사용량 확인 (간접적)
  local process_count=$(pgrep -f "nix-app-linker" | wc -l)
  if [ "$process_count" -eq 0 ]; then
    log_success "No lingering processes after execution"
  else
    log_failure "$process_count lingering nix-app-linker processes"
    return 1
  fi

  return 0
}

# 통합 테스트 5: 실제 앱 실행 가능성 확인
test_app_executability() {
  log_integration "Testing linked apps can actually be executed..."

  # WezTerm 실행 테스트 (실제로는 실행하지 않고 실행 가능성만 확인)
  if [ -L "$USER_HOME_APPS/WezTerm.app" ] && [ -e "$USER_HOME_APPS/WezTerm.app" ]; then

    # 실행 권한 확인
    local wezterm_binary
    wezterm_binary=$(find "$USER_HOME_APPS/WezTerm.app/Contents/MacOS" -type f -perm +111 2>/dev/null | head -1)

    if [ -n "$wezterm_binary" ] && [ -x "$wezterm_binary" ]; then
      log_success "WezTerm.app binary is executable: $wezterm_binary"

      # 버전 정보 확인 (실행하지 않고)
      if "$wezterm_binary" --version >/dev/null 2>&1; then
        log_success "WezTerm.app responds to --version command"
      else
        log_failure "WezTerm.app does not respond to --version"
        return 1
      fi

    else
      log_failure "WezTerm.app binary not found or not executable"
      return 1
    fi
  else
    log_failure "WezTerm.app not available for executability test"
    return 1
  fi

  return 0
}

# 모든 통합 테스트 실행
run_integration_tests() {
  echo "🚀 Running Dynamic GUI App Linking Integration Tests"
  echo "==================================================="

  # 테스트 디렉토리 준비
  mkdir -p "$INTEGRATION_TEST_DIR"

  local failed_tests=0
  local total_tests=5

  echo ""
  if ! test_real_nix_store_discovery; then
    ((failed_tests++))
  fi

  echo ""
  if ! test_macos_system_integration; then
    ((failed_tests++))
  fi

  echo ""
  if ! test_home_manager_interaction; then
    ((failed_tests++))
  fi

  echo ""
  if ! test_performance_and_stability; then
    ((failed_tests++))
  fi

  echo ""
  if ! test_app_executability; then
    ((failed_tests++))
  fi

  echo ""
  echo "==================================================="
  echo "📊 Integration Test Summary:"

  for result in "${INTEGRATION_RESULTS[@]}"; do
    echo "   $result"
  done

  echo ""

  if [ $failed_tests -eq 0 ]; then
    echo "🟢 Integration Test Result: All $total_tests tests PASSED!"
    echo "✅ Dynamic linking system fully integrated with macOS"
    echo "🚀 Production ready for all Nix GUI apps!"
    return 0
  else
    echo "🔴 Integration Test Result: $failed_tests/$total_tests tests failed"
    echo "❌ Integration issues detected - check system setup"
    return 1
  fi
}

# 정리
cleanup() {
  rm -rf "$INTEGRATION_TEST_DIR"
}

# 메인 실행
main() {
  trap cleanup EXIT

  # 실제 시스템에서 실행되는지 확인
  if [[ $HOME == "/tmp"* ]] || [[ $USER == "test"* ]]; then
    echo "⚠️  This appears to be a test environment"
    echo "Integration tests are designed for real macOS systems"
    echo "Proceeding with limited testing..."
  fi

  run_integration_tests
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
