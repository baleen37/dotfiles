#!/usr/bin/env bash
# ABOUTME: user-resolution.nix 통합 테스트
# ABOUTME: 사용자 해석, 환경 변수 처리, 플랫폼별 경로 생성 실제 환경 통합 검증

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 공통 라이브러리 로드
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

# 테스트 헬퍼 함수
assert_test() {
  local condition="$1"
  local test_name="$2"
  local expected="${3:-}"
  local actual="${4:-}"

  if eval "$condition"; then
    log_success "$test_name"
    ((TESTS_PASSED++))
    return 0
  else
    if [[ -n $expected && -n $actual ]]; then
      log_fail "$test_name"
      log_error "  예상: $expected"
      log_error "  실제: $actual"
    else
      log_fail "$test_name"
      log_debug "  실패한 조건: $condition"
    fi
    ((TESTS_FAILED++))
    return 1
  fi
}

# user-resolution.nix 평가 헬퍼 함수
eval_user_resolution() {
  local options="$1"
  local attribute="${2:-}"

  if [[ -n $attribute ]]; then
    nix eval --impure --expr "(import $PROJECT_ROOT/lib/user-resolution.nix $options).${attribute}" 2>/dev/null | tr -d '"'
  else
    nix eval --impure --expr "(import $PROJECT_ROOT/lib/user-resolution.nix $options)" 2>/dev/null | tr -d '"'
  fi
}

# 기본 사용자 해석 테스트
test_basic_user_resolution() {
  log_header "기본 사용자 해석 테스트"

  # 유효한 사용자명으로 테스트
  local resolved_user=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; }')
  assert_test "[[ '$resolved_user' == 'testuser' ]]" "기본 사용자 해석" "testuser" "$resolved_user"

  # 다른 환경 변수 테스트 (CUSTOM_USER)
  local custom_user=$(eval_user_resolution '{ envVar = "CUSTOM_USER"; mockEnv = { CUSTOM_USER = "customuser"; }; }')
  assert_test "[[ '$custom_user' == 'customuser' ]]" "커스텀 환경 변수 사용자 해석" "customuser" "$custom_user"

  # SUDO_USER 우선순위 테스트
  local sudo_user=$(eval_user_resolution '{ mockEnv = { USER = "root"; SUDO_USER = "realuser"; }; allowSudoUser = true; }')
  assert_test "[[ '$sudo_user' == 'realuser' ]]" "SUDO_USER 우선 처리" "realuser" "$sudo_user"
}

# 사용자명 검증 테스트
test_username_validation() {
  log_header "사용자명 검증 테스트"

  # 유효한 사용자명들
  local valid_users=("user" "test_user" "user123" "user.name" "user-name")
  for user in "${valid_users[@]}"; do
    local result=$(eval_user_resolution "{ mockEnv = { USER = \"$user\"; }; }")
    assert_test "[[ '$result' == '$user' ]]" "유효한 사용자명: $user" "$user" "$result"
  done

  # 잘못된 사용자명으로 에러 발생 테스트
  local invalid_users=("" " " "user@domain" "user#123" "123user")
  for user in "${invalid_users[@]}"; do
    if eval_user_resolution "{ mockEnv = { USER = \"$user\"; }; }" >/dev/null 2>&1; then
      log_fail "잘못된 사용자명이 허용됨: $user"
      ((TESTS_FAILED++))
    else
      log_success "잘못된 사용자명 거부: $user"
      ((TESTS_PASSED++))
    fi
  done
}

# CI 환경 fallback 테스트
test_ci_environment() {
  log_header "CI 환경 fallback 테스트"

  # GitHub Actions 환경 시뮬레이션
  local github_user=$(eval_user_resolution '{ mockEnv = { GITHUB_ACTIONS = "true"; }; }')
  assert_test "[[ '$github_user' == 'runner' ]]" "GitHub Actions 환경 fallback" "runner" "$github_user"

  # 일반 CI 환경 시뮬레이션
  local ci_user=$(eval_user_resolution '{ mockEnv = { CI = "true"; }; }')
  assert_test "[[ '$ci_user' == 'runner' ]]" "일반 CI 환경 fallback" "runner" "$ci_user"
}

# 플랫폼별 경로 생성 테스트
test_platform_paths() {
  log_header "플랫폼별 경로 생성 테스트"

  # Darwin 경로 테스트
  local darwin_home=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "darwin"; returnFormat = "extended"; }' "homePath")
  assert_test "[[ '$darwin_home' == '/Users/testuser' ]]" "Darwin home 경로" "/Users/testuser" "$darwin_home"

  # Linux 경로 테스트
  local linux_home=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "linux"; returnFormat = "extended"; }' "homePath")
  assert_test "[[ '$linux_home' == '/home/testuser' ]]" "Linux home 경로" "/home/testuser" "$linux_home"

  # SSH 경로 테스트
  local ssh_path=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "darwin"; returnFormat = "extended"; }' "utils.getSshPath")
  assert_test "[[ '$ssh_path' == '/Users/testuser/.ssh' ]]" "SSH 디렉토리 경로" "/Users/testuser/.ssh" "$ssh_path"

  # Config 경로 테스트
  local config_path=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "linux"; returnFormat = "extended"; }' "utils.getConfigPath")
  assert_test "[[ '$config_path' == '/home/testuser/.config' ]]" "Config 디렉토리 경로" "/home/testuser/.config" "$config_path"
}

# 확장된 반환 형식 테스트
test_extended_return_format() {
  log_header "확장된 반환 형식 테스트"

  # 사용자 정보 확인
  local user_name=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "darwin"; returnFormat = "extended"; }' "userConfig.name")
  assert_test "[[ '$user_name' == 'testuser' ]]" "확장 형식 사용자명" "testuser" "$user_name"

  # 플랫폼 정보 확인
  local platform=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "darwin"; returnFormat = "extended"; }' "platform")
  assert_test "[[ '$platform' == 'darwin' ]]" "확장 형식 플랫폼" "darwin" "$platform"

  # 플랫폼 체크 함수 테스트
  local is_darwin=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "darwin"; returnFormat = "extended"; }' "utils.isDarwin")
  assert_test "[[ '$is_darwin' == 'true' ]]" "Darwin 플랫폼 체크" "true" "$is_darwin"

  local is_linux=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; platform = "linux"; returnFormat = "extended"; }' "utils.isLinux")
  assert_test "[[ '$is_linux' == 'true' ]]" "Linux 플랫폼 체크" "true" "$is_linux"
}

# auto-detection 테스트
test_auto_detection() {
  log_header "자동 감지 기능 테스트"

  # auto-detection 활성화된 경우
  local auto_user=$(eval_user_resolution '{ mockEnv = {}; enableAutoDetect = true; }')
  assert_test "[[ '$auto_user' == 'auto-detected-user' ]]" "자동 감지 활성화" "auto-detected-user" "$auto_user"

  # auto-detection 비활성화된 경우 (default 제공)
  local default_user=$(eval_user_resolution '{ mockEnv = {}; enableAutoDetect = false; default = "fallback"; }')
  assert_test "[[ '$default_user' == 'fallback' ]]" "기본값 fallback" "fallback" "$default_user"
}

# 디버그 모드 테스트
test_debug_mode() {
  log_header "디버그 모드 테스트"

  # 디버그 출력이 있는지 확인 (stderr에 출력됨)
  local debug_output=$(eval_user_resolution '{ mockEnv = { USER = "testuser"; }; debugMode = true; }' 2>&1)
  assert_test "[[ '$debug_output' =~ 'user-resolution' ]]" "디버그 출력 확인"
}

# 에러 메시지 품질 테스트
test_error_messages() {
  log_header "에러 메시지 품질 테스트"

  # 도움이 되는 에러 메시지가 생성되는지 확인
  local error_output=$(eval_user_resolution '{ mockEnv = {}; enableAutoDetect = false; }' 2>&1 || true)

  assert_test "[[ '$error_output' =~ 'Failed to detect valid user' ]]" "에러 메시지 제목 포함"
  assert_test "[[ '$error_output' =~ 'export USER=' ]]" "해결 방법 제안 포함"
  assert_test "[[ '$error_output' =~ 'Debug info:' ]]" "디버그 정보 포함"
}

# 성능 테스트
test_performance() {
  log_header "성능 테스트"

  local start_time=$(date +%s%N)
  for i in {1..50}; do
    eval_user_resolution '{ mockEnv = { USER = "testuser"; }; }' >/dev/null
  done
  local end_time=$(date +%s%N)
  local duration=$(((end_time - start_time) / 1000000)) # 밀리초 변환

  # 50회 평가가 200ms 이하여야 함 (평균 4ms per call)
  assert_test "[[ $duration -lt 200 ]]" "50회 평가가 200ms 이내 완료" "<200ms" "${duration}ms"
}

# 정리 함수
cleanup_test_environment() {
  log_debug "테스트 환경 정리: $TEST_DIR"
  rm -rf "$TEST_DIR"
}

# 메인 테스트 실행
main() {
  log_header "User Resolution 포괄적 테스트 시작"
  log_info "테스트 디렉토리: $TEST_DIR"
  log_info "프로젝트 루트: $PROJECT_ROOT"

  # 신호 핸들러 설정
  setup_signal_handlers

  # Nix 명령어 확인
  if ! command -v nix >/dev/null 2>&1; then
    log_error "nix 명령어를 찾을 수 없습니다"
    exit 1
  fi

  # 단위 테스트 실행
  test_basic_user_resolution
  test_username_validation
  test_ci_environment
  test_platform_paths
  test_extended_return_format
  test_auto_detection
  test_debug_mode
  test_error_messages
  test_performance

  # 결과 출력
  log_separator
  log_header "테스트 결과"
  log_info "통과: $TESTS_PASSED"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    log_error "실패: $TESTS_FAILED"
    log_error "일부 테스트가 실패했습니다."
    exit 1
  else
    log_success "모든 테스트가 통과했습니다! 🎉"
    exit 0
  fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
