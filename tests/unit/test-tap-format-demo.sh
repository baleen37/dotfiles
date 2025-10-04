#!/usr/bin/env bash
# ABOUTME: TAP (Test Anything Protocol) 형식 출력 데모
# ABOUTME: CI/CD 통합을 위한 표준 테스트 리포팅 형식 검증

set -euo pipefail

# 공통 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# TAP 데모용 커스텀 setup
setup_custom() {
  log_debug "TAP 형식 테스트 커스텀 setup 실행"

  # TAP 테스트용 작업공간 생성
  TAP_WORKSPACE="$TEST_CASE_TEMP_DIR/tap_workspace"
  mkdir -p "$TAP_WORKSPACE"
  export TAP_WORKSPACE
}

teardown_custom() {
  log_debug "TAP 형식 테스트 커스텀 teardown 실행"
}

# 다양한 결과를 보여주는 테스트 함수들
test_tap_success() {
  local test_file="$TAP_WORKSPACE/success.txt"
  echo "success" >"$test_file"

  if [[ $TEST_OUTPUT_FORMAT == "tap" ]]; then
    assert_equals_tap "success" "$(cat "$test_file")" "TAP 성공 테스트"
    assert_file_exists_tap "$test_file" "TAP 파일 존재 확인"
  else
    assert_equals "success" "$(cat "$test_file")" "일반 성공 테스트"
    assert_file_exists "$test_file" "일반 파일 존재 확인"
  fi
}

test_tap_failure() {
  # 이 테스트는 의도적으로 실패할 수 있도록 설계
  local test_value="${FORCE_FAILURE:-success}"

  if [[ $TEST_OUTPUT_FORMAT == "tap" ]]; then
    assert_equals_tap "expected" "$test_value" "TAP 실패 테스트 (의도적)"
  else
    # 일반 모드에서는 실패하지 않도록
    assert_equals "success" "$test_value" "일반 모드 성공 테스트"
  fi
}

test_tap_command_success() {
  if [[ $TEST_OUTPUT_FORMAT == "tap" ]]; then
    assert_command_tap "[ -d '$TAP_WORKSPACE' ]" "TAP 명령어 성공 테스트"
    assert_command_tap "echo 'hello' | grep 'hello'" "TAP 파이프 명령어 테스트"
  else
    assert_command "[ -d '$TAP_WORKSPACE' ]" "일반 명령어 성공 테스트"
    assert_command "echo 'hello' | grep 'hello'" "일반 파이프 명령어 테스트"
  fi
}

test_tap_skip_demonstration() {
  if [[ ${SKIP_SLOW_TESTS:-false} == "true" ]]; then
    if [[ $TEST_OUTPUT_FORMAT == "tap" ]]; then
      skip_test_tap "SKIP_SLOW_TESTS가 설정됨" "느린 테스트"
    else
      skip_test "SKIP_SLOW_TESTS가 설정됨"
    fi
    return
  fi

  # 건너뛰지 않는 경우 정상 테스트 실행
  local result="completed"
  if [[ $TEST_OUTPUT_FORMAT == "tap" ]]; then
    assert_equals_tap "completed" "$result" "건너뛸 수 있는 테스트 (실행됨)"
  else
    assert_equals "completed" "$result" "건너뛸 수 있는 테스트 (실행됨)"
  fi
}

# 표준 모드와 TAP 모드 비교 데모
demo_standard_vs_tap() {
  echo
  echo "=== 표준 출력 형식으로 테스트 실행 ==="
  export TEST_OUTPUT_FORMAT="standard"

  begin_test_suite "TAP 데모 (표준 형식)"
  run_test "표준 성공 테스트" test_tap_success
  run_test "표준 명령어 테스트" test_tap_command_success
  run_test "표준 건너뛰기 테스트" test_tap_skip_demonstration
  end_test_suite "TAP 데모 (표준 형식)"

  # 결과 초기화
  TESTS_PASSED=0
  TESTS_FAILED=0
  TESTS_SKIPPED=0
  TAP_TEST_COUNT=0
  TAP_PLAN_EMITTED=false

  echo
  echo "=== TAP 출력 형식으로 동일한 테스트 실행 ==="
  export TEST_OUTPUT_FORMAT="tap"

  auto_begin_test_suite "TAP 데모 (TAP 형식)" 3
  auto_run_test "TAP 성공 테스트" test_tap_success
  auto_run_test "TAP 명령어 테스트" test_tap_command_success
  auto_run_test "TAP 건너뛰기 테스트" test_tap_skip_demonstration
  auto_end_test_suite "TAP 데모 (TAP 형식)"
}

# 메인 실행 함수
main() {
  # 명령줄 인수로 출력 형식 지정 가능
  if [[ ${1:-} == "--tap" ]]; then
    export TEST_OUTPUT_FORMAT="tap"
  elif [[ ${1:-} == "--demo" ]]; then
    demo_standard_vs_tap
    return
  fi

  # 환경 검증
  validate_test_environment || {
    if [[ $TEST_OUTPUT_FORMAT == "tap" ]]; then
      tap_bail_out "테스트 환경 검증 실패"
    else
      log_error "테스트 환경 검증 실패"
    fi
    exit 1
  }

  if [[ $TEST_OUTPUT_FORMAT == "tap" ]]; then
    # TAP 형식으로 실행
    auto_begin_test_suite "TAP 형식 데모" 4
    auto_run_test "TAP 성공 테스트" test_tap_success
    auto_run_test "TAP 실패 테스트" test_tap_failure
    auto_run_test "TAP 명령어 테스트" test_tap_command_success
    auto_run_test "TAP 건너뛰기 테스트" test_tap_skip_demonstration
    auto_end_test_suite "TAP 형식 데모"
  else
    # 표준 형식으로 실행
    begin_test_suite "TAP 형식 데모 (표준 출력)"
    run_test "성공 테스트" test_tap_success
    run_test "명령어 테스트" test_tap_command_success
    run_test "건너뛰기 테스트" test_tap_skip_demonstration
    end_test_suite "TAP 형식 데모 (표준 출력)"
  fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
