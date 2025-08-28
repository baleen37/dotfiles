#!/usr/bin/env bash
# ABOUTME: 테스트 생명주기 관리 - setup/teardown 패턴 표준화
# ABOUTME: Bats 스타일 생명주기 관리와 공통 설정 패턴

set -euo pipefail

# 생명주기 관리 버전
readonly TEST_LIFECYCLE_VERSION="1.0.0"

# === Bats 스타일 생명주기 함수들 ===

# 각 테스트 실행 전 호출 (Bats setup() 스타일)
test_setup() {
    log_debug "테스트 설정 시작: $(get_current_context)"

    # 기본 설정들
    export TEST_SETUP_TIME=$(date +%s%N)

    # 하위 클래스에서 오버라이드 가능
    if declare -f setup_test_case >/dev/null; then
        setup_test_case
    fi
}

# 각 테스트 실행 후 호출 (Bats teardown() 스타일)
test_teardown() {
    log_debug "테스트 정리 시작: $(get_current_context)"

    # 하위 클래스에서 오버라이드 가능
    if declare -f teardown_test_case >/dev/null; then
        teardown_test_case
    fi

    # 기본 정리 작업
    unset TEST_SETUP_TIME
}

# 전체 파일 실행 전 한 번만 호출 (Bats setup_file() 스타일)
test_setup_file() {
    log_debug "파일 레벨 설정 시작: $TEST_SUITE_NAME"

    # 전역 설정들
    export TEST_FILE_START_TIME=$(date +%s%N)

    # 하위 클래스에서 오버라이드 가능
    if declare -f setup_file_once >/dev/null; then
        setup_file_once
    fi
}

# 전체 파일 실행 후 한 번만 호출 (Bats teardown_file() 스타일)
test_teardown_file() {
    log_debug "파일 레벨 정리 시작: $TEST_SUITE_NAME"

    # 하위 클래스에서 오버라이드 가능
    if declare -f teardown_file_once >/dev/null; then
        teardown_file_once
    fi

    # 전역 정리
    unset TEST_FILE_START_TIME
}

# === 향상된 테스트 실행기 ===

# 개별 테스트 함수 실행 (생명주기 포함)
run_test_with_lifecycle() {
    local test_function="$1"
    local test_context="${2:-$test_function}"

    push_test_context "$test_context"

    # Setup
    test_setup

    # 실제 테스트 실행
    local test_result=0
    if ! "$test_function"; then
        test_result=1
    fi

    # Teardown (항상 실행)
    test_teardown || true

    pop_test_context
    return $test_result
}

# 테스트 그룹 실행 (여러 테스트 함수들)
run_test_group_with_lifecycle() {
    local group_name="$1"
    shift
    local test_functions=("$@")

    start_test_group "$group_name"

    local group_failures=0
    for test_func in "${test_functions[@]}"; do
        if ! run_test_with_lifecycle "$test_func"; then
            ((group_failures++))
        fi
    done

    end_test_group
    return $((group_failures > 0 ? 1 : 0))
}

# === 공통 설정 패턴들 ===

# 임시 디렉토리 자동 관리
with_temp_directory() {
    local test_function="$1"
    local prefix="${2:-test}"

    # 임시 디렉토리 생성
    local temp_dir=$(create_test_directory "$prefix")
    register_cleanup_dir "$temp_dir"

    # 환경 변수 설정
    export TEST_TEMP_DIR="$temp_dir"

    # 테스트 실행
    local result=0
    if ! "$test_function"; then
        result=1
    fi

    # 환경 변수 정리
    unset TEST_TEMP_DIR

    return $result
}

# 모의 환경 자동 관리
with_mock_environment() {
    local test_function="$1"
    local env_type="${2:-claude}"
    local cleanup="${3:-true}"

    case "$env_type" in
        "claude")
            setup_claude_test_environment "lifecycle-claude"
            ;;
        "nix")
            setup_nix_test_environment "lifecycle-nix"
            ;;
        *)
            setup_standard_test_environment "lifecycle-std"
            ;;
    esac

    # 테스트 실행
    local result=0
    if ! "$test_function"; then
        result=1
    fi

    return $result
}

# === 조건부 실행 패턴들 ===

# Skip 패턴 (Bats skip 스타일)
skip_test() {
    local reason="$1"
    log_skip "테스트 건너뜀: $reason"
    return 0
}

# 조건부 Skip
skip_if() {
    local condition="$1"
    local reason="$2"

    if eval "$condition"; then
        skip_test "$reason"
        return 0
    fi
    return 1
}

# 플랫폼별 Skip
skip_unless_darwin() {
    skip_if "[[ \$(detect_platform) != 'darwin' ]]" "Darwin 전용 테스트"
}

skip_unless_linux() {
    skip_if "[[ \$(detect_platform) != 'linux' ]]" "Linux 전용 테스트"
}

skip_unless_ci() {
    skip_if "! is_ci_environment" "CI 환경 전용 테스트"
}

# 도구 의존성 Skip
skip_unless_command() {
    local command="$1"
    skip_if "! command -v '$command' >/dev/null 2>&1" "$command 도구 필요"
}

# === 테스트 데이터 관리 ===

# 테스트 픽스처 로드
load_test_fixture() {
    local fixture_name="$1"
    local fixtures_dir="$SCRIPT_DIR/../fixtures"
    local fixture_file="$fixtures_dir/$fixture_name"

    if [[ -f "$fixture_file" ]]; then
        log_debug "픽스처 로드: $fixture_name"
        source "$fixture_file"
    else
        log_warning "픽스처 파일 없음: $fixture_file"
        return 1
    fi
}

# 테스트 데이터 생성
create_test_data() {
    local data_type="$1"
    local output_file="$2"

    case "$data_type" in
        "json")
            echo '{"test": true, "value": 42}' > "$output_file"
            ;;
        "yaml")
            cat > "$output_file" << 'EOF'
test: true
value: 42
items:
  - name: test1
  - name: test2
EOF
            ;;
        "nix")
            cat > "$output_file" << 'EOF'
{
  testValue = 42;
  testString = "hello world";
  testList = [ 1 2 3 ];
}
EOF
            ;;
    esac

    log_debug "테스트 데이터 생성: $output_file ($data_type)"
}

# === 성능 측정 패턴 ===

# 성능 기반 테스트
performance_test() {
    local test_function="$1"
    local max_duration_ms="${2:-1000}"
    local test_name="${3:-성능 테스트}"

    local start_time=$(date +%s%N)
    "$test_function"
    local end_time=$(date +%s%N)

    local duration_ms=$(( (end_time - start_time) / 1000000 ))
    assert_less_or_equal "$duration_ms" "$max_duration_ms" "$test_name (${duration_ms}ms)"
}

# 메모리 사용량 테스트 (macOS)
memory_test() {
    local test_function="$1"
    local max_memory_mb="${2:-100}"
    local test_name="${3:-메모리 테스트}"

    if ! command -v ps >/dev/null 2>&1; then
        skip_test "ps 명령어 없음"
        return 0
    fi

    # 메모리 측정은 단순화 (실제 구현은 플랫폼별로 다름)
    "$test_function"
    log_debug "$test_name 완료 (메모리 측정은 구현 필요)"
}

# === 병렬 테스트 지원 ===

# 병렬 실행 안전한 환경 생성
create_parallel_safe_environment() {
    local test_id="${1:-$$}"
    local base_dir="${2:-${TEST_DIR:-/tmp}}"

    setup_isolated_test_environment "$test_id" "$base_dir"
}

log_debug "테스트 생명주기 관리 로드 완료 (v$TEST_LIFECYCLE_VERSION)"
