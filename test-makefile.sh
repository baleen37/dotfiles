#!/usr/bin/env bash

# Makefile 타겟 검증 스크립트
# 사용법: ./test-makefile.sh [target_name]

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# 테스트 결과 카운터
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 타겟 존재 확인 함수
test_target_exists() {
  local target=$1
  local description=$2

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  log_info "Testing target: $target - $description"

  # USER 변수 설정
  export USER=$(whoami)

  # make -n으로 타겟 존재 여부 확인
  if make -n "$target" 2>/dev/null | grep -q "Nothing to be done" || make -n "$target" >/dev/null 2>&1; then
    log_success "✓ $target exists and is executable"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    log_error "✗ $target does not exist or is not executable"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  echo
}

# 모든 테스트 실행
run_all_tests() {
  log_info "Starting Makefile target validation tests..."
  echo

  # 기본 타겟들 테스트
  test_target_exists "help" "Display help information"
  test_target_exists "format" "Auto-format all files"
  test_target_exists "lint" "Run all lint checks"
  test_target_exists "lint-quick" "Quick format and validation"
  test_target_exists "test" "Run core tests"
  test_target_exists "test-quick" "Fast validation (2-3s)"
  test_target_exists "test-all" "Comprehensive test suite"
  test_target_exists "build" "Build current platform"
  test_target_exists "build-current" "Build current platform (alias)"
  test_target_exists "build-switch" "Build system (same as switch)"
  test_target_exists "switch" "Build + apply system config"
  test_target_exists "switch-user" "Apply user config only"

  # 존재하지 않는 타겟들 테스트
  test_target_exists "smoke" "Smoke test target (should fail - not implemented)"
  test_target_exists "platform-info" "Platform info target (should fail - not implemented)"
  test_target_exists "build-switch-dry" "Build switch dry target (should fail - not implemented)"

  # 결과 출력
  log_info "Test Results:"
  log_info "Total tests: $TOTAL_TESTS"
  log_success "Passed: $PASSED_TESTS"
  log_error "Failed: $FAILED_TESTS"

  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "All tests passed!"
    exit 0
  else
    log_error "Some tests failed!"
    exit 1
  fi
}

# 특정 타겟만 테스트
test_single_target() {
  local target=$1
  log_info "Testing single target: $target"

  export USER=$(whoami)

  if make "$target"; then
    log_success "✓ $target executed successfully"
    exit 0
  else
    log_error "✗ $target failed"
    exit 1
  fi
}

# 메인 로직
main() {
  # 현재 디렉토리 확인
  if [ ! -f "Makefile" ]; then
    log_error "Makefile not found in current directory"
    exit 1
  fi

  # make 명령어 확인
  if ! command -v make &>/dev/null; then
    log_error "make command not found"
    exit 1
  fi

  if [ $# -eq 0 ]; then
    run_all_tests
  else
    test_single_target "$1"
  fi
}

# 스크립트 실행
main "$@"
