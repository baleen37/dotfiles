#!/usr/bin/env bash
# ABOUTME: 테스트 프레임워크 자체 검증 테스트
# ABOUTME: 새로운 assertion 함수들이 올바르게 작동하는지 확인

set -euo pipefail

# 테스트 디렉토리 경로
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-framework.sh"

# 테스트용 임시 디렉토리
TEST_TEMP_DIR=""
TEST_CASE_TEMP_DIR=""
TEST_SUITE_TEMP_DIR=""
TEST_CASE_START_TIME=""

# 커스텀 Setup - 기본 setup_test_case에 추가로 실행됨
setup_custom() {
    # 임시 디렉토리들 설정
    TEST_SUITE_TEMP_DIR=$(mktemp -d)
    TEST_CASE_TEMP_DIR="$TEST_SUITE_TEMP_DIR/test-case"
    TEST_TEMP_DIR="$TEST_CASE_TEMP_DIR/framework-test"
    TEST_CASE_START_TIME=$(date +%s%N)

    mkdir -p "$TEST_CASE_TEMP_DIR"
    mkdir -p "$TEST_TEMP_DIR"
    log_debug "프레임워크 테스트용 디렉토리 생성: $TEST_TEMP_DIR"
}

# 커스텀 Teardown
teardown_custom() {
    # 추가 정리 작업 (기본 teardown_test_case가 TEST_CASE_TEMP_DIR 정리)
    if [[ -n "${TEST_TEMP_DIR:-}" ]]; then
        log_debug "프레임워크 테스트용 디렉토리는 기본 teardown에서 정리됨"
    fi
}

# ==================== 테스트 케이스들 ====================

test_assert_equals() {
    assert_equals "hello" "hello" "동일한 문자열 비교"
    assert_equals "123" "123" "동일한 숫자 문자열 비교"

    local var1="test"
    local var2="test"
    assert_equals "$var1" "$var2" "변수 값 비교"
}

test_assert_not_equals() {
    assert_not_equals "hello" "world" "다른 문자열 확인"
    assert_not_equals "123" "456" "다른 숫자 확인"
}

test_assert_contains() {
    assert_contains "hello world" "world" "문자열 포함 확인"
    assert_contains "testing 123" "123" "숫자 포함 확인"

    local output="Error: File not found"
    assert_contains "$output" "Error" "에러 메시지 포함 확인"
}

test_assert_regex() {
    assert_regex "test@example.com" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "이메일 형식 검증"
    assert_regex "192.168.1.1" "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" "IP 주소 형식 검증"
    assert_regex "v1.2.3" "^v[0-9]+\.[0-9]+\.[0-9]+$" "버전 형식 검증"
}

test_assert_command() {
    assert_command "true" "true 명령어 실행"
    assert_command "echo 'test' | grep 'test'" "파이프 명령어 실행"
    assert_command "[ 1 -eq 1 ]" "조건 테스트 명령어"
}

test_assert_command_fails() {
    assert_command_fails "false" "false 명령어 실패 확인"
    assert_command_fails "[ 1 -eq 2 ]" "실패하는 조건 테스트"
    assert_command_fails "grep 'nonexistent' /dev/null" "grep 실패 확인"
}

test_file_assertions() {
    # 파일 생성 후 테스트
    local test_file="$TEST_TEMP_DIR/test.txt"
    echo "content" > "$test_file"
    assert_file_exists "$test_file" "생성된 파일 존재 확인"

    # 디렉토리 테스트
    assert_directory_exists "$TEST_TEMP_DIR" "임시 디렉토리 존재 확인"

    # 심볼릭 링크 테스트
    local link_target="$TEST_TEMP_DIR/target.txt"
    local symlink="$TEST_TEMP_DIR/link.txt"
    echo "target" > "$link_target"
    ln -s "$link_target" "$symlink"
    assert_symlink "$symlink" "심볼릭 링크 확인"
}

test_empty_assertions() {
    local empty_var=""
    local non_empty_var="content"

    assert_empty "$empty_var" "빈 변수 확인"
    assert_not_empty "$non_empty_var" "비어있지 않은 변수 확인"
}

test_numeric_assertions() {
    assert_greater_or_equal 10 5 "10 >= 5 확인"
    assert_greater_or_equal 10 10 "10 >= 10 확인"
}

test_array_assertions() {
    local fruits=("apple" "banana" "orange")
    assert_array_contains "banana" "${fruits[@]}" "배열에 banana 포함 확인"
}

test_skip_functionality() {
    if [[ "${SKIP_SLOW_TESTS:-false}" == "true" ]]; then
        skip_test "SKIP_SLOW_TESTS가 설정됨"
        return
    fi

    assert_equals "1" "1" "이 테스트는 건너뛸 수 있음"
}

test_setup_teardown_mechanism() {
    # 기본 setup이 실행되었는지 확인
    assert_not_empty "$TEST_CASE_TEMP_DIR" "기본 테스트 케이스 임시 디렉토리 설정됨"
    assert_directory_exists "$TEST_CASE_TEMP_DIR" "기본 테스트 케이스 임시 디렉토리 존재"

    # 커스텀 setup이 실행되었는지 확인
    assert_not_empty "$TEST_TEMP_DIR" "커스텀 테스트 디렉토리 설정됨"
    assert_directory_exists "$TEST_TEMP_DIR" "커스텀 테스트 디렉토리 존재"

    # 테스트 스위트 레벨 리소스 확인
    assert_not_empty "$TEST_SUITE_TEMP_DIR" "테스트 스위트 임시 디렉토리 설정됨"
    assert_directory_exists "$TEST_SUITE_TEMP_DIR" "테스트 스위트 임시 디렉토리 존재"
}

test_test_timing() {
    # 테스트 케이스 시작 시간이 기록되었는지 확인
    assert_not_empty "$TEST_CASE_START_TIME" "테스트 케이스 시작 시간 기록됨"

    # 숫자인지 확인
    assert_regex "$TEST_CASE_START_TIME" "^[0-9]+$" "시작 시간이 숫자 형식"
}

# ==================== 메인 실행 ====================

main() {
    begin_test_suite "테스트 프레임워크 검증"
    setup_custom

    run_test "assert_equals 테스트" test_assert_equals
    run_test "assert_not_equals 테스트" test_assert_not_equals
    run_test "assert_contains 테스트" test_assert_contains
    run_test "assert_regex 테스트" test_assert_regex
    run_test "assert_command 테스트" test_assert_command
    run_test "assert_command_fails 테스트" test_assert_command_fails
    run_test "파일 관련 assertion 테스트" test_file_assertions
    run_test "empty assertion 테스트" test_empty_assertions
    run_test "숫자 비교 assertion 테스트" test_numeric_assertions
    run_test "배열 assertion 테스트" test_array_assertions
    run_test "테스트 건너뛰기 기능" test_skip_functionality
    run_test "Setup/Teardown 메커니즘 테스트" test_setup_teardown_mechanism
    run_test "테스트 타이밍 기능" test_test_timing

    end_test_suite "테스트 프레임워크 검증"
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
