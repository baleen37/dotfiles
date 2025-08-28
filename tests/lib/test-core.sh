#!/usr/bin/env bash
# ABOUTME: 통합 Bash 테스트 코어 - 모든 테스트에서 사용할 단일 진입점
# ABOUTME: common.sh, test-framework.sh, mock-environment.sh를 통합하여 일관된 테스트 환경 제공

set -euo pipefail

# 테스트 코어 버전
readonly TEST_CORE_VERSION="1.0.0"

# === 코어 초기화 (한번만 실행) ===
if [[ -z "${TEST_CORE_LOADED:-}" ]]; then
    readonly TEST_CORE_LOADED=true

    # 기본 경로 설정
    TEST_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$TEST_CORE_DIR/../.." && pwd)"

    # 개별 라이브러리들 로드
    source "$TEST_CORE_DIR/common.sh"
    source "$TEST_CORE_DIR/test-framework.sh"
    source "$TEST_CORE_DIR/mock-environment.sh"

    log_debug "테스트 코어 라이브러리 통합 로드 완료 (v$TEST_CORE_VERSION)"
fi

# === 표준화된 테스트 생명주기 ===

# 테스트 스위트 초기화 (모든 테스트에서 호출해야 함)
test_suite_init() {
    local suite_name="$1"
    local enable_cleanup="${2:-true}"

    # 전역 변수 설정
    TEST_SUITE_NAME="$suite_name"

    # 테스트 프레임워크 초기화
    test_framework_init

    # 신호 핸들러 설정
    if [[ "$enable_cleanup" == "true" ]]; then
        setup_signal_handlers
    fi

    # 헤더 출력
    log_header "테스트 스위트 시작: $suite_name"
    log_debug "프로젝트 루트: $PROJECT_ROOT"

    # 필요한 도구들 확인
    check_required_tools bash nix || {
        log_error "필수 도구가 누락되었습니다"
        exit 1
    }
}

# 테스트 스위트 종료 (모든 테스트 마지막에 호출)
test_suite_finish() {
    local exit_on_failure="${1:-true}"

    # 테스트 결과 출력
    local exit_code=0
    if ! report_test_results; then
        exit_code=1
    fi

    # 정리 작업
    cleanup_test_environment

    if [[ "$exit_on_failure" == "true" && $exit_code -ne 0 ]]; then
        exit $exit_code
    fi

    return $exit_code
}

# === 표준화된 테스트 환경 설정 ===

# 기본 테스트 환경 설정 (대부분 테스트에서 사용)
setup_standard_test_environment() {
    local test_prefix="${1:-test}"

    # 테스트 디렉토리 생성
    local test_dir=$(create_test_directory "$test_prefix")
    register_cleanup_dir "$test_dir"

    # 전역 변수로 설정
    export TEST_DIR="$test_dir"

    log_debug "표준 테스트 환경 설정: $TEST_DIR"
    echo "$TEST_DIR"
}

# Claude 전용 테스트 환경 설정
setup_claude_test_environment() {
    local test_prefix="${1:-claude-test}"

    # 기본 환경 설정
    local test_dir=$(setup_standard_test_environment "$test_prefix")

    # Claude 관련 디렉토리들
    local source_dir="$test_dir/source"
    local claude_dir="$test_dir/.claude"

    # 모의 Claude 환경 생성
    setup_mock_claude_environment "$claude_dir" "$source_dir"

    # 전역 변수 설정
    export CLAUDE_SOURCE_DIR="$source_dir"
    export CLAUDE_TARGET_DIR="$claude_dir"

    log_debug "Claude 테스트 환경 설정 완료"
    log_debug "  소스: $CLAUDE_SOURCE_DIR"
    log_debug "  타겟: $CLAUDE_TARGET_DIR"
}

# Nix 전용 테스트 환경 설정
setup_nix_test_environment() {
    local test_prefix="${1:-nix-test}"
    local project_name="${2:-test-project}"

    # 기본 환경 설정
    local test_dir=$(setup_standard_test_environment "$test_prefix")

    # Nix 환경 구축
    setup_mock_nix_environment "$test_dir" "$project_name"

    log_debug "Nix 테스트 환경 설정 완료"
}

# === 향상된 Assert 함수들 (기존 + 새로운) ===

# Nix 평가 결과 테스트
assert_nix_eval() {
    local nix_expr="$1"
    local expected="$2"
    local test_name="$3"

    local actual
    if actual=$(nix eval --impure --expr "$nix_expr" 2>/dev/null | tr -d '"'); then
        assert_equals "$expected" "$actual" "$test_name"
    else
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  Nix 평가 실패: $nix_expr"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 파일 평가를 통한 Nix 테스트
assert_nix_file_eval() {
    local nix_file="$1"
    local attribute="$2"
    local expected="$3"
    local test_name="$4"

    assert_nix_eval "(import $nix_file).$attribute" "$expected" "$test_name"
}

# 심볼릭 링크 타겟 확인
assert_symlink_target() {
    local link_path="$1"
    local expected_target="$2"
    local test_name="$3"

    if [[ ! -L "$link_path" ]]; then
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  심볼릭 링크가 아님: $link_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    local actual_target=$(readlink "$link_path")
    assert_equals "$expected_target" "$actual_target" "$test_name"
}

# JSON 키 존재 확인
assert_json_has_key() {
    local file_path="$1"
    local json_path="$2"
    local test_name="$3"

    if ! command -v jq >/dev/null 2>&1; then
        log_warning "[$TEST_SUITE_NAME] jq 없음: JSON 테스트 건너뜀 - $test_name"
        return 0
    fi

    if jq -e "$json_path" "$file_path" >/dev/null 2>&1; then
        log_success "[$TEST_SUITE_NAME] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  JSON 키 없음: $json_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 정규표현식 매칭
assert_matches_pattern() {
    local text="$1"
    local pattern="$2"
    local test_name="$3"

    if [[ $text =~ $pattern ]]; then
        log_success "[$TEST_SUITE_NAME] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_fail "[$TEST_SUITE_NAME] $test_name"
        log_error "  패턴 불일치: $pattern"
        log_error "  실제 텍스트: $text"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# === 고급 테스트 패턴 ===

# 조건부 테스트 (플랫폼별, CI별 등)
conditional_test() {
    local condition="$1"
    local test_func="$2"
    local skip_reason="$3"

    if eval "$condition"; then
        "$test_func"
    else
        log_skip "테스트 건너뜀: $skip_reason"
    fi
}

# Darwin 전용 테스트
darwin_only_test() {
    local test_func="$1"
    conditional_test "[[ \$(detect_platform) == 'darwin' ]]" "$test_func" "Darwin 전용 테스트"
}

# Linux 전용 테스트
linux_only_test() {
    local test_func="$1"
    conditional_test "[[ \$(detect_platform) == 'linux' ]]" "$test_func" "Linux 전용 테스트"
}

# CI 환경 전용 테스트
ci_only_test() {
    local test_func="$1"
    conditional_test "is_ci_environment" "$test_func" "CI 환경 전용 테스트"
}

# === 유틸리티 함수들 ===

# 테스트 메타데이터 출력
show_test_info() {
    log_info "테스트 환경 정보:"
    log_tree 1 "플랫폼: $(detect_platform)"
    log_tree 1 "아키텍처: $(detect_architecture)"
    log_tree 1 "CI 환경: $(is_ci_environment && echo 'Yes' || echo 'No')"
    log_tree_last 1 "테스트 코어 버전: $TEST_CORE_VERSION"
}

# 빠른 검증 (smoke test용)
quick_validate() {
    local item_type="$1"
    local path="$2"

    case "$item_type" in
        "file") [[ -f "$path" ]] ;;
        "dir") [[ -d "$path" ]] ;;
        "symlink") [[ -L "$path" ]] ;;
        "executable") [[ -x "$path" ]] ;;
        *) return 1 ;;
    esac
}

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

# === 백워드 호환성 보장 ===

# 기존 함수들을 그대로 유지 (모든 기존 테스트가 동작하도록)
# common.sh, test-framework.sh, mock-environment.sh의 모든 함수들이 여전히 사용 가능

log_debug "테스트 코어 초기화 완료 (v$TEST_CORE_VERSION)"
log_debug "통합 가능: common.sh (v$COMMON_LIB_VERSION), test-framework.sh (v$TEST_FRAMEWORK_VERSION), mock-environment.sh (v$MOCK_ENV_VERSION)"
