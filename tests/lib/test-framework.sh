#!/usr/bin/env bash
# ABOUTME: 통합 테스트 프레임워크 - 표준화된 assert 함수들과 테스트 실행 관리
# ABOUTME: 모든 테스트에서 공통으로 사용할 수 있는 검증 함수들과 상태 관리

set -euo pipefail

# 공통 라이브러리 로드 (중복 방지)
if [[ -z "${COMMON_LIB_VERSION:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
fi

# 프레임워크 버전
readonly TEST_FRAMEWORK_VERSION="1.0.0"

# 테스트 결과 전역 변수
declare -g TESTS_PASSED=${TESTS_PASSED:-0}
declare -g TESTS_FAILED=${TESTS_FAILED:-0}
declare -g TEST_SUITE_NAME=${TEST_SUITE_NAME:-"Unknown"}
declare -g TEST_START_TIME=""
declare -g TEST_VERBOSE=${TEST_VERBOSE:-false}

# 테스트 컨텍스트 스택
declare -ga TEST_CONTEXT_STACK

# 테스트 시작 시간 기록
test_framework_init() {
    TEST_START_TIME=$(date +%s%N)
    TESTS_PASSED=0
    TESTS_FAILED=0
    log_debug "테스트 프레임워크 초기화 완료 (v$TEST_FRAMEWORK_VERSION)"
}

# 테스트 컨텍스트 관리
push_test_context() {
    local context="$1"
    TEST_CONTEXT_STACK+=("$context")
    if [[ "$TEST_VERBOSE" == "true" ]]; then
        log_debug "컨텍스트 진입: $context"
    fi
}

pop_test_context() {
    if [[ ${#TEST_CONTEXT_STACK[@]} -gt 0 ]]; then
        unset 'TEST_CONTEXT_STACK[${#TEST_CONTEXT_STACK[@]}-1]'
    fi
}

get_current_context() {
    # 배열이 설정되어 있고 비어있지 않은 경우에만 접근
    if [[ -n "${TEST_CONTEXT_STACK:-}" ]] && [[ ${#TEST_CONTEXT_STACK[@]} -gt 0 ]]; then
        echo "${TEST_CONTEXT_STACK[${#TEST_CONTEXT_STACK[@]}-1]}"
    else
        echo "${TEST_SUITE_NAME:-Unknown}"
    fi
}

# === 핵심 Assert 함수들 ===

# 기본 assert 함수 (기존 assert_test를 대체)
assert() {
    local condition="$1"
    local test_name="$2"
    local expected="${3:-}"
    local actual="${4:-}"

    local context=$(get_current_context)
    local full_test_name="[$context] $test_name"

    # 직접 조건을 평가
    if eval "$condition" 2>/dev/null; then
        log_success "$full_test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        if [[ -n "$expected" && -n "$actual" ]]; then
            log_fail "$full_test_name"
            log_error "  예상: $expected"
            log_error "  실제: $actual"
        else
            log_fail "$full_test_name"
            if [[ "$TEST_VERBOSE" == "true" ]]; then
                log_debug "  실패한 조건: $condition"
            fi
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 문자열 비교
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    assert "[[ '$actual' == '$expected' ]]" "$test_name" "$expected" "$actual"
}

# 문자열 불일치
assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    assert "[[ '$actual' != '$expected' ]]" "$test_name" "!= $expected" "$actual"
}

# 정규식 매칭
assert_regex() {
    local string="$1"
    local pattern="$2"
    local test_name="$3"

    assert "[[ '$string' =~ $pattern ]]" "$test_name" "matches $pattern" "$string"
}

# 명령어 성공 확인
assert_command() {
    local command="$1"
    local test_name="$2"

    if eval "$command" >/dev/null 2>&1; then
        log_success "[$(get_current_context)] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_fail "[$(get_current_context)] $test_name"
        log_error "  명령어 실패: $command"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 명령어 실패 확인
assert_command_fails() {
    local command="$1"
    local test_name="$2"

    if ! eval "$command" >/dev/null 2>&1; then
        log_success "[$(get_current_context)] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_fail "[$(get_current_context)] $test_name"
        log_error "  명령어가 성공했어야 실패: $command"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 빈 문자열/변수 확인
assert_empty() {
    local var="$1"
    local test_name="$2"

    assert "[[ -z '$var' ]]" "$test_name" "empty" "$var"
}

# 비어있지 않은 문자열/변수 확인
assert_not_empty() {
    local var="$1"
    local test_name="$2"

    assert "[[ -n '$var' ]]" "$test_name" "not empty" "$var"
}

# 배열에서 원소 포함 확인
assert_array_contains() {
    local element="$1"
    shift
    local array=("$@")
    local last_arg="${array[-1]}"
    unset 'array[-1]'
    local test_name="$last_arg"

    local found=false
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            found=true
            break
        fi
    done

    if $found; then
        log_success "[$(get_current_context)] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_fail "[$(get_current_context)] $test_name"
        log_error "  배열에서 '$element'를 찾을 수 없음"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 테스트 건너뛰기
skip_test() {
    local reason="$1"
    log_warning "[$(get_current_context)] 테스트 건너뜀: $reason"
}

# 파일 존재 확인
assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    assert "[[ -f '$file_path' ]]" "$test_name" "file exists" "$file_path"
}

# 디렉토리 존재 확인
assert_directory_exists() {
    local dir_path="$1"
    local test_name="$2"

    assert "[[ -d '$dir_path' ]]" "$test_name" "directory exists" "$dir_path"
}

# 심볼릭 링크 확인
assert_symlink() {
    local link_path="$1"
    local test_name="$2"

    assert "[[ -L '$link_path' ]]" "$test_name" "is symlink" "$link_path"
}

# 문자열 포함 확인
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    assert "[[ '$haystack' =~ '$needle' ]]" "$test_name" "contains '$needle'" "$haystack"
}

# 파일 존재 확인
assert_file_exists() {
    local file_path="$1"
    local test_name="${2:-파일 존재: $file_path}"

    assert "[[ -f '$file_path' ]]" "$test_name"
}

# 디렉토리 존재 확인
assert_dir_exists() {
    local dir_path="$1"
    local test_name="${2:-디렉토리 존재: $dir_path}"

    assert "[[ -d '$dir_path' ]]" "$test_name"
}

# 파일 부재 확인
assert_file_not_exists() {
    local file_path="$1"
    local test_name="${2:-파일 부재: $file_path}"

    assert "[[ ! -f '$file_path' ]]" "$test_name"
}

# 심볼릭 링크 확인
assert_symlink() {
    local link_path="$1"
    local test_name="${2:-심볼릭 링크: $link_path}"

    assert "[[ -L '$link_path' ]]" "$test_name"
}

# 심볼릭 링크가 아님 확인
assert_not_symlink() {
    local path="$1"
    local test_name="${2:-심볼릭 링크가 아님: $path}"

    assert "[[ ! -L '$path' ]]" "$test_name"
}

# 명령 성공 확인
assert_command_success() {
    local command="$1"
    local test_name="${2:-명령 성공: $command}"

    if eval "$command" >/dev/null 2>&1; then
        log_success "[$TEST_SUITE_NAME] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        local exit_code=$?
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  명령어: $command"
        log_error "  종료 코드: $exit_code"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 명령 실패 확인
assert_command_fails() {
    local command="$1"
    local test_name="${2:-명령 실패: $command}"

    if eval "$command" >/dev/null 2>&1; then
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  명령어가 성공했지만 실패가 예상됨: $command"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        log_success "[$TEST_SUITE_NAME] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
}

# 권한 확인
assert_file_permissions() {
    local file_path="$1"
    local expected_perms="$2"
    local test_name="${3:-파일 권한: $file_path}"

    if [[ ! -f "$file_path" ]]; then
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  파일이 존재하지 않음: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    local actual_perms=$(stat -f "%OLp" "$file_path" 2>/dev/null || stat -c "%a" "$file_path" 2>/dev/null)
    assert_equals "$expected_perms" "$actual_perms" "$test_name"
}

# JSON 값 확인 (jq 사용)
assert_json_value() {
    local file_path="$1"
    local json_path="$2"
    local expected_value="$3"
    local test_name="${4:-JSON 값: $json_path}"

    if ! command -v jq >/dev/null 2>&1; then
        log_warning "[$TEST_SUITE_NAME] jq 없음: JSON 테스트 건너뜀 - $test_name"
        return 0
    fi

    if [[ ! -f "$file_path" ]]; then
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  JSON 파일 없음: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    local actual_value=$(jq -r "$json_path // \"null\"" "$file_path" 2>/dev/null)
    assert_equals "$expected_value" "$actual_value" "$test_name"
}

# 숫자 비교 (크거나 같음)
assert_greater_or_equal() {
    local actual="$1"
    local threshold="$2"
    local test_name="$3"

    assert "[[ '$actual' -ge '$threshold' ]]" "$test_name" ">= $threshold" "$actual"
}

# 숫자 비교 (작거나 같음)
assert_less_or_equal() {
    local actual="$1"
    local threshold="$2"
    local test_name="$3"

    assert "[[ '$actual' -le '$threshold' ]]" "$test_name" "<= $threshold" "$actual"
}

# 성능 측정 헬퍼
measure_execution_time() {
    local command="$1"
    local test_name="${2:-성능 측정}"
    local max_duration_ms="${3:-1000}"

    local start_time=$(date +%s%N)
    eval "$command" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    assert_less_or_equal "$duration_ms" "$max_duration_ms" "$test_name (${duration_ms}ms)"
}

# === 테스트 그룹 관리 ===

# 테스트 스위트 시작
begin_test_suite() {
    local suite_name="$1"
    TEST_SUITE_NAME="$suite_name"
    test_framework_init
    log_header "테스트 스위트: $suite_name"
    push_test_context "$suite_name"
}

# 테스트 스위트 종료
end_test_suite() {
    pop_test_context
    report_test_results
}

# 테스트 실행 함수
run_test() {
    local test_name="$1"
    local test_function="$2"

    log_info "실행 중: $test_name"

    # 테스트 함수 실행
    if "$test_function"; then
        log_success "$test_name 완료"
        return 0
    else
        log_error "$test_name 실패"
        return 1
    fi
}

# 테스트 그룹 시작
start_test_group() {
    local group_name="$1"
    push_test_context "$group_name"
    log_header "$group_name"
}

# 테스트 그룹 종료
end_test_group() {
    pop_test_context
}

# === 테스트 결과 리포팅 ===

# 최종 테스트 결과 출력
report_test_results() {
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local success_rate=0

    if [[ $total_tests -gt 0 ]]; then
        success_rate=$(( (TESTS_PASSED * 100) / total_tests ))
    fi

    # 실행 시간 계산
    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - TEST_START_TIME) / 1000000 ))
    local duration_str="${duration_ms}ms"
    if [[ $duration_ms -gt 1000 ]]; then
        duration_str="$(( duration_ms / 1000 ))s"
    fi

    log_separator
    log_header "테스트 결과 - $TEST_SUITE_NAME"
    log_info "전체 테스트: $total_tests"
    log_info "통과: $TESTS_PASSED"
    log_info "실행 시간: $duration_str"
    log_info "성공률: ${success_rate}%"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "실패: $TESTS_FAILED"
        log_error "일부 테스트가 실패했습니다."
        return 1
    else
        log_success "모든 테스트가 통과했습니다!"
        return 0
    fi
}

# 간단한 결과 출력 (CI용)
report_test_results_simple() {
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - TEST_START_TIME) / 1000000 ))

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "❌ $TEST_SUITE_NAME: $TESTS_PASSED/$total_tests passed (${duration_ms}ms)"
        return 1
    else
        echo "✅ $TEST_SUITE_NAME: $total_tests/$total_tests passed (${duration_ms}ms)"
        return 0
    fi
}

# === 백워드 호환성 ===

# 기존 assert_test 함수 (백워드 호환성)
assert_test() {
    assert "$@"
}

log_debug "테스트 프레임워크 로드 완료 (v$TEST_FRAMEWORK_VERSION)"
