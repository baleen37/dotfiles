#!/usr/bin/env bash
# ABOUTME: 테스트 공통 라이브러리 - 기본적인 공통 함수들만 제공
# ABOUTME: 코드 중복 제거를 위한 최소한의 공통 기능

set -euo pipefail

# 색상 코드
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 로깅 함수들
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

log_header() {
    echo -e "${PURPLE}[TEST SUITE]${NC} $1" >&2
}

log_separator() {
    echo -e "${CYAN}============================================${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅${NC} $1" >&2
}

log_fail() {
    echo -e "${RED}❌${NC} $1" >&2
}

# 필수 도구 확인
check_required_tools() {
    local tools=("$@")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "필수 도구들이 누락되었습니다: ${missing_tools[*]}"
        return 1
    fi

    return 0
}

# 테스트 환경 정리
cleanup_test_environment() {
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
        log_debug "테스트 환경 정리: $TEST_DIR"
        rm -rf "$TEST_DIR"
        unset TEST_DIR
    fi
}

# 신호 핸들러 설정
setup_signal_handlers() {
    trap cleanup_test_environment EXIT INT TERM
}

# ==================== Assertion 함수들 ====================

# 테스트 카운터
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# 값이 같은지 확인
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-값 비교}"

    if [[ "$expected" == "$actual" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  예상: '$expected'"
        log_error "  실제: '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 값이 다른지 확인
assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-값이 다른지 확인}"

    if [[ "$unexpected" != "$actual" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  예상하지 않은 값: '$unexpected'"
        log_error "  실제 값: '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 문자열 포함 확인
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-문자열 포함 확인}"

    if [[ "$haystack" == *"$needle"* ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  '$needle'이(가) '$haystack'에 포함되지 않음"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 정규식 매칭 확인
assert_regex() {
    local string="$1"
    local pattern="$2"
    local message="${3:-정규식 매칭}"

    if [[ "$string" =~ $pattern ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  '$string'이(가) 패턴 '$pattern'과 매칭되지 않음"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 명령어 실행 성공 확인
assert_command() {
    local command="$1"
    local message="${2:-명령어 실행}"

    if eval "$command" >/dev/null 2>&1; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        local exit_code=$?
        log_fail "✗ $message"
        log_error "  명령어: $command"
        log_error "  종료 코드: $exit_code"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 명령어 실행 실패 확인
assert_command_fails() {
    local command="$1"
    local message="${2:-명령어 실패 예상}"

    if ! eval "$command" >/dev/null 2>&1; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  명령어가 예상과 달리 성공함: $command"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 파일 존재 확인
assert_file_exists() {
    local file="$1"
    local message="${2:-파일 존재 확인}"

    if [[ -f "$file" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  파일이 존재하지 않음: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 디렉토리 존재 확인
assert_directory_exists() {
    local dir="$1"
    local message="${2:-디렉토리 존재 확인}"

    if [[ -d "$dir" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  디렉토리가 존재하지 않음: $dir"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 심볼릭 링크 확인
assert_symlink() {
    local link="$1"
    local message="${2:-심볼릭 링크 확인}"

    if [[ -L "$link" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  심볼릭 링크가 아님: $link"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 빈 값 확인
assert_empty() {
    local value="$1"
    local message="${2:-빈 값 확인}"

    if [[ -z "$value" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  값이 비어있지 않음: '$value'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 비어있지 않은 값 확인
assert_not_empty() {
    local value="$1"
    local message="${2:-비어있지 않은 값 확인}"

    if [[ -n "$value" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  값이 비어있음"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 숫자 비교 - 크거나 같음
assert_greater_or_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-크거나 같음 확인}"

    if [[ "$actual" -ge "$expected" ]]; then
        log_success "✓ $message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "✗ $message"
        log_error "  $actual >= $expected 실패"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 배열 요소 확인
assert_array_contains() {
    local needle="$1"
    shift
    local array=("$@")
    local message="${array[-1]}"
    unset 'array[-1]'

    for element in "${array[@]}"; do
        if [[ "$element" == "$needle" ]]; then
            log_success "✓ $message"
            ((TESTS_PASSED++))
            return 0
        fi
    done

    log_fail "✗ $message"
    log_error "  '$needle'이(가) 배열에 없음"
    ((TESTS_FAILED++))
    return 1
}

# ==================== 테스트 실행 헬퍼 ====================

# 테스트 스위트 시작
begin_test_suite() {
    local suite_name="$1"
    log_separator
    log_header "테스트 스위트: $suite_name"
    log_separator
    SUITE_START_TIME=$(date +%s)

    # 테스트 스위트 레벨 setup 실행
    setup_test_suite
}

# 테스트 케이스 실행 (개선된 버전)
run_test() {
    local test_name="$1"
    local test_function="$2"
    local test_result=0

    log_info "실행 중: $test_name"

    # 테스트 실행 전 환경 설정
    {
        setup_test_case
        setup_test_hooks
    } 2>/dev/null || {
        log_error "테스트 setup 실패: $test_name"
        return 1
    }

    # 테스트 실행
    if $test_function; then
        log_success "통과: $test_name"
        test_result=0
    else
        log_fail "실패: $test_name"
        test_result=1
    fi

    # 테스트 후 정리 (실패해도 정리는 실행)
    {
        teardown_test_hooks
        teardown_test_case
    } 2>/dev/null || {
        log_warning "테스트 teardown에서 경고 발생: $test_name"
    }

    return $test_result
}

# 테스트 스위트 종료
end_test_suite() {
    local suite_name="${1:-테스트}"
    local end_time=$(date +%s)
    local duration=$((end_time - SUITE_START_TIME))

    # 테스트 스위트 레벨 teardown 실행
    teardown_test_suite 2>/dev/null || {
        log_warning "테스트 스위트 teardown에서 경고 발생"
    }

    log_separator
    log_header "테스트 결과 요약"
    log_info "통과: $TESTS_PASSED"
    [[ $TESTS_FAILED -gt 0 ]] && log_error "실패: $TESTS_FAILED"
    [[ $TESTS_SKIPPED -gt 0 ]] && log_warning "건너뜀: $TESTS_SKIPPED"
    log_info "총: $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED)) (소요 시간: ${duration}초)"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "모든 테스트 통과! 🎉"
        return 0
    else
        log_error "일부 테스트 실패"
        return 1
    fi
}

# 테스트 건너뛰기
skip_test() {
    local reason="$1"
    log_warning "건너뜀: $reason"
    ((TESTS_SKIPPED++))
}

# ==================== Setup/Teardown 함수 (표준화된 메커니즘) ====================

# 테스트 스위트 레벨 Setup/Teardown
setup_test_suite() {
    log_debug "테스트 스위트 setup 실행"
    # 테스트 스위트 전체에서 사용할 리소스 초기화
    export TEST_SUITE_TEMP_DIR=$(mktemp -d -t "test-suite-XXXXXX")
    log_debug "테스트 스위트 임시 디렉토리: $TEST_SUITE_TEMP_DIR"
}

teardown_test_suite() {
    log_debug "테스트 스위트 teardown 실행"
    # 테스트 스위트 레벨 정리
    if [[ -n "${TEST_SUITE_TEMP_DIR:-}" ]] && [[ -d "$TEST_SUITE_TEMP_DIR" ]]; then
        rm -rf "$TEST_SUITE_TEMP_DIR"
        unset TEST_SUITE_TEMP_DIR
        log_debug "테스트 스위트 임시 디렉토리 제거 완료"
    fi
}

# 테스트 케이스별 setup (각 테스트 파일에서 오버라이드 가능)
setup_test_case() {
    log_debug "기본 테스트 케이스 setup 실행"

    # 테스트 격리를 위한 고유 식별자 생성
    local test_id="${TEST_PARALLEL_ID:-test_$$_$(date +%s%N)}"
    export TEST_CASE_ID="$test_id"

    # 격리된 임시 디렉토리 생성
    export TEST_CASE_TEMP_DIR=$(mktemp -d -t "test-case-${test_id}-XXXXXX")
    export TEST_CASE_START_TIME=$(date +%s)

    # 테스트 격리를 위한 환경 변수 설정
    if [[ "${TEST_ISOLATION:-true}" == "true" ]]; then
        export HOME="$TEST_CASE_TEMP_DIR/home"
        export XDG_CONFIG_HOME="$TEST_CASE_TEMP_DIR/config"
        export XDG_DATA_HOME="$TEST_CASE_TEMP_DIR/data"
        export XDG_CACHE_HOME="$TEST_CASE_TEMP_DIR/cache"

        # 격리된 홈 디렉토리 구조 생성
        mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"

        log_debug "테스트 격리 환경 설정 완료: $test_id"
    fi

    log_debug "테스트 케이스 임시 디렉토리: $TEST_CASE_TEMP_DIR"
}

# 테스트 케이스별 teardown (각 테스트 파일에서 오버라이드 가능)
teardown_test_case() {
    local end_time=$(date +%s)
    local duration=$((end_time - ${TEST_CASE_START_TIME:-$end_time}))
    log_debug "기본 테스트 케이스 teardown 실행 (소요시간: ${duration}초)"

    # 기본 테스트 케이스 정리
    if [[ -n "${TEST_CASE_TEMP_DIR:-}" ]] && [[ -d "$TEST_CASE_TEMP_DIR" ]]; then
        rm -rf "$TEST_CASE_TEMP_DIR"
        unset TEST_CASE_TEMP_DIR
        log_debug "테스트 케이스 임시 디렉토리 제거 완료"
    fi
    unset TEST_CASE_START_TIME
}

# 커스텀 Setup/Teardown 훅 지원
setup_test_hooks() {
    # 사용자 정의 setup 훅 실행
    if declare -f "setup_custom" > /dev/null; then
        log_debug "사용자 정의 setup 훅 실행"
        setup_custom
    fi
}

teardown_test_hooks() {
    # 사용자 정의 teardown 훅 실행
    if declare -f "teardown_custom" > /dev/null; then
        log_debug "사용자 정의 teardown 훅 실행"
        teardown_custom
    fi
}

# ==================== 테스트 실행 모드 지원 ====================

# 테스트 실행 모드 설정
TEST_MODE="${TEST_MODE:-normal}"  # normal, parallel, strict, verbose
TEST_ISOLATION="${TEST_ISOLATION:-true}"  # 테스트 격리 여부
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"  # 테스트 타임아웃 (초)
TEST_OUTPUT_FORMAT="${TEST_OUTPUT_FORMAT:-standard}"  # standard, tap, json, junit

# ==================== 병렬 테스트 실행 지원 ====================

# 병렬 테스트 실행 함수
run_tests_parallel() {
    local test_functions=("$@")
    local max_parallel=${MAX_PARALLEL_TESTS:-4}  # 최대 병렬 프로세스 수
    local running_jobs=()
    local job_names=()
    local job_results=()

    log_info "병렬 테스트 실행 시작 (최대 $max_parallel 개 동시 실행)"

    for i in "${!test_functions[@]}"; do
        local test_info="${test_functions[$i]}"
        local test_name=$(echo "$test_info" | cut -d: -f1)
        local test_function=$(echo "$test_info" | cut -d: -f2)

        # 실행 중인 작업이 최대치에 도달하면 대기
        while [[ ${#running_jobs[@]} -ge $max_parallel ]]; do
            check_and_collect_parallel_jobs
            sleep 0.1
        done

        # 병렬로 테스트 실행
        start_parallel_test "$test_name" "$test_function"
    done

    # 모든 작업 완료 대기
    while [[ ${#running_jobs[@]} -gt 0 ]]; do
        check_and_collect_parallel_jobs
        sleep 0.1
    done

    log_info "모든 병렬 테스트 완료"
}

# 병렬 테스트 시작
start_parallel_test() {
    local test_name="$1"
    local test_function="$2"
    local test_id="test_$$_$(date +%s)_${#running_jobs[@]}"
    local temp_result_file="/tmp/${test_id}_result"
    local temp_output_file="/tmp/${test_id}_output"

    log_info "병렬 시작: $test_name"

    # 백그라운드에서 테스트 실행
    (
        # 격리된 환경에서 테스트 실행
        export TEST_PARALLEL_ID="$test_id"
        export TEST_ISOLATION="true"

        # 테스트 실행
        {
            setup_test_case
            setup_test_hooks

            if $test_function; then
                echo "PASS" > "$temp_result_file"
                log_success "병렬 통과: $test_name" >> "$temp_output_file"
            else
                echo "FAIL" > "$temp_result_file"
                log_fail "병렬 실패: $test_name" >> "$temp_output_file"
            fi

            teardown_test_hooks
            teardown_test_case
        } 2>&1 | tee -a "$temp_output_file"

    ) &

    local job_pid=$!
    running_jobs+=($job_pid)
    job_names+=("$test_name")
    job_results+=("$temp_result_file:$temp_output_file")
}

# 완료된 병렬 작업 수집
check_and_collect_parallel_jobs() {
    local new_running_jobs=()
    local new_job_names=()
    local new_job_results=()

    for i in "${!running_jobs[@]}"; do
        local pid="${running_jobs[$i]}"
        local name="${job_names[$i]}"
        local result_info="${job_results[$i]}"

        if ! kill -0 "$pid" 2>/dev/null; then
            # 작업 완료됨
            wait "$pid"
            local exit_code=$?

            # 결과 처리
            local result_file=$(echo "$result_info" | cut -d: -f1)
            local output_file=$(echo "$result_info" | cut -d: -f2)

            if [[ -f "$result_file" ]]; then
                local result=$(cat "$result_file")
                if [[ "$result" == "PASS" ]]; then
                    ((TESTS_PASSED++))
                else
                    ((TESTS_FAILED++))
                fi
            else
                log_error "병렬 테스트 결과 파일 누락: $name"
                ((TESTS_FAILED++))
            fi

            # 출력 표시
            if [[ -f "$output_file" ]]; then
                cat "$output_file"
            fi

            # 임시 파일 정리
            rm -f "$result_file" "$output_file"
        else
            # 아직 실행 중
            new_running_jobs+=($pid)
            new_job_names+=("$name")
            new_job_results+=("$result_info")
        fi
    done

    running_jobs=("${new_running_jobs[@]}")
    job_names=("${new_job_names[@]}")
    job_results=("${new_job_results[@]}")
}

# 테스트 타임아웃 설정
setup_test_timeout() {
    if [[ "$TEST_TIMEOUT" -gt 0 ]]; then
        (
            sleep "$TEST_TIMEOUT"
            log_error "테스트 타임아웃 ($TEST_TIMEOUT 초)"
            pkill -P $$
        ) &
        TIMEOUT_PID=$!
    fi
}

cleanup_test_timeout() {
    if [[ -n "${TIMEOUT_PID:-}" ]]; then
        kill "$TIMEOUT_PID" 2>/dev/null || true
        unset TIMEOUT_PID
    fi
}

# 테스트 환경 검증
validate_test_environment() {
    local validation_errors=()

    # 필수 환경 변수 확인
    if [[ -z "${USER:-}" ]]; then
        validation_errors+=("USER 환경변수가 설정되지 않음")
    fi

    # 임시 디렉토리 권한 확인
    if ! touch "/tmp/test-write-check-$$" 2>/dev/null; then
        validation_errors+=("임시 디렉토리 쓰기 권한 없음")
    else
        rm -f "/tmp/test-write-check-$$"
    fi

    # 에러가 있으면 보고
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        log_error "테스트 환경 검증 실패:"
        for error in "${validation_errors[@]}"; do
            log_error "  - $error"
        done
        return 1
    fi

    log_debug "테스트 환경 검증 완료"
    return 0
}

# 테스트 메타데이터 추적
declare -A TEST_METADATA

record_test_metadata() {
    local test_name="$1"
    local key="$2"
    local value="$3"
    TEST_METADATA["${test_name}:${key}"]="$value"
}

get_test_metadata() {
    local test_name="$1"
    local key="$2"
    echo "${TEST_METADATA["${test_name}:${key}"]:-}"
}

# ==================== TAP (Test Anything Protocol) 지원 ====================

# TAP 카운터
TAP_TEST_COUNT=0
TAP_PLAN_EMITTED=false

# TAP 출력 함수들
tap_plan() {
    local total_tests="$1"
    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        echo "1..$total_tests"
        TAP_PLAN_EMITTED=true
    fi
}

tap_ok() {
    local test_number="$1"
    local description="$2"
    local directive="${3:-}"  # SKIP, TODO 등

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        local output="ok $test_number - $description"
        if [[ -n "$directive" ]]; then
            output="$output # $directive"
        fi
        echo "$output"
    fi
}

tap_not_ok() {
    local test_number="$1"
    local description="$2"
    local directive="${3:-}"

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        local output="not ok $test_number - $description"
        if [[ -n "$directive" ]]; then
            output="$output # $directive"
        fi
        echo "$output"
    fi
}

tap_diagnostic() {
    local message="$1"
    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        echo "# $message"
    fi
}

tap_bail_out() {
    local reason="$1"
    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        echo "Bail out! $reason"
    fi
}

# TAP 버전의 assertion 함수들
assert_equals_tap() {
    local expected="$1"
    local actual="$2"
    local message="${3:-값 비교}"
    local test_number="${4:-$((++TAP_TEST_COUNT))}"

    if [[ "$expected" == "$actual" ]]; then
        tap_ok "$test_number" "$message"
        ((TESTS_PASSED++))
        return 0
    else
        tap_not_ok "$test_number" "$message"
        tap_diagnostic "Expected: '$expected'"
        tap_diagnostic "Actual: '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists_tap() {
    local file="$1"
    local message="${2:-파일 존재 확인}"
    local test_number="${3:-$((++TAP_TEST_COUNT))}"

    if [[ -f "$file" ]]; then
        tap_ok "$test_number" "$message"
        ((TESTS_PASSED++))
        return 0
    else
        tap_not_ok "$test_number" "$message"
        tap_diagnostic "File does not exist: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_command_tap() {
    local command="$1"
    local message="${2:-명령어 실행}"
    local test_number="${3:-$((++TAP_TEST_COUNT))}"

    if eval "$command" >/dev/null 2>&1; then
        tap_ok "$test_number" "$message"
        ((TESTS_PASSED++))
        return 0
    else
        local exit_code=$?
        tap_not_ok "$test_number" "$message"
        tap_diagnostic "Command: $command"
        tap_diagnostic "Exit code: $exit_code"
        ((TESTS_FAILED++))
        return 1
    fi
}

# TAP 호환 테스트 실행 함수
run_test_tap() {
    local test_name="$1"
    local test_function="$2"
    local test_number="${3:-$((++TAP_TEST_COUNT))}"

    # 테스트 실행 전 환경 설정
    {
        setup_test_case
        setup_test_hooks
    } 2>/dev/null || {
        tap_not_ok "$test_number" "$test_name"
        tap_diagnostic "Setup failed for test: $test_name"
        ((TESTS_FAILED++))
        return 1
    }

    # 테스트 실행
    if $test_function; then
        tap_ok "$test_number" "$test_name"
        ((TESTS_PASSED++))
    else
        tap_not_ok "$test_number" "$test_name"
        ((TESTS_FAILED++))
    fi

    # 테스트 후 정리
    {
        teardown_test_hooks
        teardown_test_case
    } 2>/dev/null || {
        tap_diagnostic "Warning: Teardown issue for test: $test_name"
    }

    return $?
}

# TAP 호환 테스트 스위트 함수들
begin_test_suite_tap() {
    local suite_name="$1"
    local test_count="${2:-0}"

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        tap_diagnostic "Test suite: $suite_name"
        if [[ $test_count -gt 0 ]]; then
            tap_plan "$test_count"
        fi
    else
        begin_test_suite "$suite_name"
    fi

    SUITE_START_TIME=$(date +%s)
    setup_test_suite
}

end_test_suite_tap() {
    local suite_name="${1:-테스트}"
    local end_time=$(date +%s)
    local duration=$((end_time - SUITE_START_TIME))

    # 테스트 스위트 레벨 teardown 실행
    teardown_test_suite 2>/dev/null || {
        tap_diagnostic "Warning: Test suite teardown issue"
    }

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        # TAP 계획이 아직 출력되지 않았다면 출력
        if [[ "$TAP_PLAN_EMITTED" == "false" ]]; then
            tap_plan "$TAP_TEST_COUNT"
        fi

        tap_diagnostic "Suite: $suite_name completed in ${duration}s"
        tap_diagnostic "Passed: $TESTS_PASSED, Failed: $TESTS_FAILED, Skipped: $TESTS_SKIPPED"

        if [[ $TESTS_FAILED -eq 0 ]]; then
            tap_diagnostic "All tests passed!"
        else
            tap_diagnostic "Some tests failed"
        fi
    else
        end_test_suite "$suite_name"
    fi

    return $([[ $TESTS_FAILED -eq 0 ]] && echo 0 || echo 1)
}

# 자동 출력 형식 감지 및 실행 함수
auto_run_test() {
    local test_name="$1"
    local test_function="$2"
    local test_number="${3:-}"

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        if [[ -z "$test_number" ]]; then
            test_number=$((++TAP_TEST_COUNT))
        fi
        run_test_tap "$test_name" "$test_function" "$test_number"
    else
        run_test "$test_name" "$test_function"
    fi
}

auto_begin_test_suite() {
    local suite_name="$1"
    local test_count="${2:-0}"

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        begin_test_suite_tap "$suite_name" "$test_count"
    else
        begin_test_suite "$suite_name"
    fi
}

auto_end_test_suite() {
    local suite_name="${1:-테스트}"

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        end_test_suite_tap "$suite_name"
    else
        end_test_suite "$suite_name"
    fi
}

# 테스트 건너뛰기 (TAP 지원)
skip_test_tap() {
    local reason="$1"
    local test_name="${2:-Skipped test}"
    local test_number="${3:-$((++TAP_TEST_COUNT))}"

    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
        tap_ok "$test_number" "$test_name" "SKIP $reason"
    else
        skip_test "$reason"
    fi
    ((TESTS_SKIPPED++))
}

# ==================== JUnit XML 지원 ====================

# JUnit XML 출력 (CI/CD 통합용)
generate_junit_xml() {
    local output_file="${1:-test-results.xml}"
    local suite_name="${2:-TestSuite}"

    if [[ "$TEST_OUTPUT_FORMAT" == "junit" || "$TEST_OUTPUT_FORMAT" == "xml" ]]; then
        local total_tests=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
        local suite_time="${SUITE_DURATION:-0}"

        cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="$suite_name" tests="$total_tests" failures="$TESTS_FAILED" skipped="$TESTS_SKIPPED" time="$suite_time">
EOF

        # 개별 테스트 결과는 별도 추가 로직 필요 (현재는 기본 구조만)

        cat >> "$output_file" << EOF
</testsuite>
EOF

        log_info "JUnit XML 결과 생성: $output_file"
    fi
}

log_debug "테스트 공통 라이브러리 로드 완료"
