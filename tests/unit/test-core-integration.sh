#!/usr/bin/env bash
# ABOUTME: 테스트 코어 통합 검증 - 새로운 통합 프레임워크가 기존 테스트와 호환되는지 확인
# ABOUTME: test-core.sh의 모든 기능을 검증하고 백워드 호환성 확인

set -euo pipefail

# 새로운 테스트 코어 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-core.sh"

# 테스트 스위트 초기화
test_suite_init "테스트 코어 통합 검증"

# === 기본 기능 테스트 ===

test_basic_functionality() {
    start_test_group "기본 기능 테스트"

    # 라이브러리 로드 확인
    assert "[[ -n '${COMMON_LIB_VERSION:-}' ]]" "common.sh 로드 확인"
    assert "[[ -n '${TEST_FRAMEWORK_VERSION:-}' ]]" "test-framework.sh 로드 확인"
    assert "[[ -n '${MOCK_ENV_VERSION:-}' ]]" "mock-environment.sh 로드 확인"
    assert "[[ -n '${TEST_CORE_VERSION:-}' ]]" "test-core.sh 로드 확인"

    # 색상 코드 확인
    assert "[[ -n '${RED:-}' ]]" "색상 코드 로드"
    assert "[[ -n '${GREEN:-}' ]]" "색상 코드 로드"

    # 로깅 함수 확인
    assert "declare -f log_info >/dev/null" "log_info 함수 존재"
    assert "declare -f log_error >/dev/null" "log_error 함수 존재"
    assert "declare -f log_success >/dev/null" "log_success 함수 존재"

    end_test_group
}

# === 환경 설정 테스트 ===

test_environment_setup() {
    start_test_group "환경 설정 테스트"

    # 표준 테스트 환경 설정
    local test_dir=$(setup_standard_test_environment "core-test")
    assert_dir_exists "$test_dir" "표준 테스트 디렉토리 생성"

    # TEST_DIR 전역 변수 설정 확인
    if [[ -n "${TEST_DIR:-}" ]]; then
        assert "[[ '$test_dir' == '$TEST_DIR' ]]" "TEST_DIR 전역 변수 설정" "$test_dir" "$TEST_DIR"
    else
        log_warning "TEST_DIR 전역 변수가 설정되지 않음"
    fi

    # 기본 구조 확인
    assert_dir_exists "$test_dir" "테스트 디렉토리 존재"

    end_test_group
}

# === Assert 함수 테스트 ===

test_assert_functions() {
    start_test_group "Assert 함수 테스트"

    # 기본 assert 함수들
    assert_equals "hello" "hello" "기본 문자열 비교"
    assert_not_equals "hello" "world" "문자열 불일치"
    assert_contains "hello world" "world" "문자열 포함"

    # TEST_DIR이 설정되지 않았다면 임시로 설정
    if [[ -z "${TEST_DIR:-}" ]]; then
        setup_standard_test_environment "assert-test" >/dev/null
    fi

    # 파일/디렉토리 관련
    touch "$TEST_DIR/test_file"
    assert_file_exists "$TEST_DIR/test_file" "파일 존재 확인"

    mkdir -p "$TEST_DIR/test_directory"
    assert_dir_exists "$TEST_DIR/test_directory" "디렉토리 존재 확인"

    # 명령 관련
    assert_command_success "echo 'test'" "echo 명령 성공"
    assert_command_fails "false" "false 명령 실패 확인"

    end_test_group
}

# === 새로운 Assert 함수 테스트 ===

test_enhanced_assert_functions() {
    start_test_group "향상된 Assert 함수 테스트"

    # 심볼릭 링크 테스트
    ln -sf "$TEST_DIR/test_file" "$TEST_DIR/test_link"
    assert_symlink "$TEST_DIR/test_link" "심볼릭 링크 확인"
    assert_symlink_target "$TEST_DIR/test_link" "$TEST_DIR/test_file" "심볼릭 링크 타겟 확인"

    # JSON 테스트 (jq가 있는 경우만)
    if command -v jq >/dev/null 2>&1; then
        echo '{"test": "value", "number": 42}' > "$TEST_DIR/test.json"
        assert_json_value "$TEST_DIR/test.json" ".test" "value" "JSON 문자열 값"
        assert_json_value "$TEST_DIR/test.json" ".number" "42" "JSON 숫자 값"
        assert_json_has_key "$TEST_DIR/test.json" ".test" "JSON 키 존재"
    fi

    # 정규표현식 매칭
    assert_matches_pattern "test-123-abc" "test-[0-9]+-[a-z]+" "정규표현식 매칭"

    end_test_group
}

# === Claude 환경 테스트 ===

test_claude_environment() {
    start_test_group "Claude 환경 테스트"

    # Claude 테스트 환경 설정 (별도 디렉토리)
    local original_test_dir="$TEST_DIR"

    setup_claude_test_environment "claude-env-test"

    # 환경 변수 확인
    assert "[[ -n '${CLAUDE_SOURCE_DIR:-}' ]]" "CLAUDE_SOURCE_DIR 설정"
    assert "[[ -n '${CLAUDE_TARGET_DIR:-}' ]]" "CLAUDE_TARGET_DIR 설정"

    # Claude 구조 확인
    assert_dir_exists "$CLAUDE_SOURCE_DIR" "Claude 소스 디렉토리"
    assert_dir_exists "$CLAUDE_TARGET_DIR" "Claude 타겟 디렉토리"
    assert_file_exists "$CLAUDE_SOURCE_DIR/settings.json" "settings.json 생성"
    assert_file_exists "$CLAUDE_SOURCE_DIR/CLAUDE.md" "CLAUDE.md 생성"
    assert_dir_exists "$CLAUDE_SOURCE_DIR/commands" "commands 디렉토리"
    assert_dir_exists "$CLAUDE_SOURCE_DIR/agents" "agents 디렉토리"

    # 복원
    TEST_DIR="$original_test_dir"

    end_test_group
}

# === 백워드 호환성 테스트 ===

test_backward_compatibility() {
    start_test_group "백워드 호환성 테스트"

    # 기존 assert_test 함수가 여전히 동작하는지 확인
    assert_test "[[ 'hello' == 'hello' ]]" "기존 assert_test 함수"

    # 기존 로깅 함수들 동작 확인
    log_info "백워드 호환성 테스트 - info 레벨"
    log_debug "백워드 호환성 테스트 - debug 레벨"

    # 기존 환경 관리 함수들
    assert "declare -f cleanup_test_environment >/dev/null" "cleanup_test_environment 함수"
    assert "declare -f setup_signal_handlers >/dev/null" "setup_signal_handlers 함수"

    # 기존 모의 환경 함수들
    assert "declare -f setup_mock_claude_environment >/dev/null" "setup_mock_claude_environment 함수"

    end_test_group
}

# === 유틸리티 함수 테스트 ===

test_utility_functions() {
    start_test_group "유틸리티 함수 테스트"

    # 플랫폼 감지
    local platform=$(detect_platform)
    assert "[[ '$platform' =~ ^(darwin|linux|cygwin|mingw|unknown)$ ]]" "플랫폼 감지" "" "$platform"

    # 아키텍처 감지
    local arch=$(detect_architecture)
    assert "[[ -n '$arch' ]]" "아키텍처 감지" "" "$arch"

    # 빠른 검증
    assert "quick_validate 'file' '$TEST_DIR/test_file'" "빠른 파일 검증"
    assert "quick_validate 'dir' '$TEST_DIR'" "빠른 디렉토리 검증"

    end_test_group
}

# === 성능 테스트 ===

test_performance_features() {
    start_test_group "성능 관련 기능"

    # 실행 시간 측정
    measure_execution_time "sleep 0.1" "짧은 명령 실행 시간" 200

    # 진행률 표시 (시각적 확인용)
    for i in {1..5}; do
        show_progress $i 5 "진행률 테스트"
        sleep 0.1
    done

    end_test_group
}

# === 테스트 실행 ===

# 모든 테스트 실행
test_basic_functionality
test_environment_setup
test_assert_functions
test_enhanced_assert_functions
test_claude_environment
test_backward_compatibility
test_utility_functions
test_performance_features

# 테스트 메타데이터 출력
show_test_info

# 테스트 스위트 완료
test_suite_finish
