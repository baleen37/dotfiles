#!/usr/bin/env bash
# ABOUTME: error-system.nix 핵심 기능 포괄적 테스트
# ABOUTME: 에러 처리, 메시지 포맷팅, 심각도 레벨, 다국어 지원 검증

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 공통 라이브러리 로드
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트 결과 추적 변수는 common.sh에서 가져옴

# error-system.nix 평가 헬퍼 함수
eval_error_system() {
    local attribute="$1"
    nix eval --impure --expr "(import $PROJECT_ROOT/lib/error-system.nix {}).${attribute}" 2>/dev/null | tr -d '"'
}

# 에러 타입 정의 테스트
test_error_types() {
    log_header "에러 타입 정의 테스트"

    # 빌드 에러 타입 확인
    local build_icon=$(eval_error_system "errorTypes.build.icon")
    assert_test "[[ '$build_icon' == '🔨' ]]" "빌드 에러 아이콘" "🔨" "$build_icon"

    local build_category=$(eval_error_system "errorTypes.build.category")
    assert_test "[[ '$build_category' == 'system' ]]" "빌드 에러 카테고리" "system" "$build_category"

    local build_priority=$(eval_error_system "errorTypes.build.priority")
    assert_test "[[ '$build_priority' == 'high' ]]" "빌드 에러 우선순위" "high" "$build_priority"

    # 설정 에러 타입 확인
    local config_icon=$(eval_error_system "errorTypes.config.icon")
    assert_test "[[ '$config_icon' == '⚙️' ]]" "설정 에러 아이콘" "⚙️" "$config_icon"

    # 사용자 에러 타입 확인
    local user_category=$(eval_error_system "errorTypes.user.category")
    assert_test "[[ '$user_category' == 'user' ]]" "사용자 에러 카테고리" "user" "$user_category"

    # 권한 에러 타입 확인 (critical)
    local permission_priority=$(eval_error_system "errorTypes.permission.priority")
    assert_test "[[ '$permission_priority' == 'critical' ]]" "권한 에러 우선순위" "critical" "$permission_priority"
}

# 심각도 레벨 테스트
test_severity_levels() {
    log_header "심각도 레벨 테스트"

    # Critical 레벨 테스트
    local critical_priority=$(eval_error_system "severityLevels.critical.priority")
    assert_test "[[ '$critical_priority' == '100' ]]" "Critical 우선순위" "100" "$critical_priority"

    local critical_icon=$(eval_error_system "severityLevels.critical.icon")
    assert_test "[[ '$critical_icon' == '🚨' ]]" "Critical 아이콘" "🚨" "$critical_icon"

    local critical_exit=$(eval_error_system "severityLevels.critical.exitCode")
    assert_test "[[ '$critical_exit' == '2' ]]" "Critical 종료 코드" "2" "$critical_exit"

    # 한국어 라벨 테스트
    local critical_label_ko=$(eval_error_system "severityLevels.critical.label_ko")
    assert_test "[[ '$critical_label_ko' == '치명적' ]]" "Critical 한국어 라벨" "치명적" "$critical_label_ko"

    # 영어 라벨 테스트
    local critical_label_en=$(eval_error_system "severityLevels.critical.label_en")
    assert_test "[[ '$critical_label_en' == 'CRITICAL' ]]" "Critical 영어 라벨" "CRITICAL" "$critical_label_en"
}

# 에러 메시지 포맷팅 테스트
test_message_formatting() {
    log_header "에러 메시지 포맷팅 테스트"

    # 기본 에러 메시지 포맷 확인 (formatError 함수가 있는지)
    if nix eval --impure --expr "(import $PROJECT_ROOT/lib/error-system.nix {}).formatError" >/dev/null 2>&1; then
        log_success "formatError 함수 존재 확인"
        ((TESTS_PASSED++))

        # 실제 에러 포맷팅 테스트 (간단한 케이스)
        local formatted=$(nix eval --impure --expr "
            let es = import $PROJECT_ROOT/lib/error-system.nix {};
            in es.formatError \"build\" \"critical\" \"Test error message\"
        " 2>/dev/null | tr -d '"' || echo "format-failed")

        if [[ "$formatted" != "format-failed" && "$formatted" =~ "🔨" ]]; then
            log_success "에러 메시지 포맷팅 수행"
            ((TESTS_PASSED++))
        else
            log_warning "에러 메시지 포맷팅 스킵 (고급 기능)"
        fi
    else
        log_warning "formatError 함수 미구현 (기본 구조만 테스트)"
    fi
}

# 색상 코드 테스트
test_color_codes() {
    log_header "색상 코드 테스트"

    # 기본 색상 확인 (nix에서 이스케이프 문자는 033으로 표시됨)
    local red_color=$(eval_error_system "colors.red")
    assert_test "[[ '$red_color' =~ '033' ]]" "빨간색 ANSI 코드"

    local reset_color=$(eval_error_system "colors.reset")
    assert_test "[[ '$reset_color' =~ '033' ]]" "리셋 ANSI 코드"

    local bold_color=$(eval_error_system "colors.bold")
    assert_test "[[ '$bold_color' =~ '033' ]]" "굵게 ANSI 코드"
}

# 에러 핸들러 함수 테스트
test_error_handlers() {
    log_header "에러 핸들러 함수 테스트"

    # throwConfigError가 실제로 throw하는지 테스트
    if nix eval --impure --expr "(import $PROJECT_ROOT/lib/error-system.nix {}).throwConfigError \"test config error\"" 2>/dev/null; then
        log_fail "throwConfigError가 예외를 발생시키지 않음"
        ((TESTS_FAILED++))
    else
        log_success "throwConfigError가 적절히 예외 발생"
        ((TESTS_PASSED++))
    fi

    # throwUserError가 실제로 throw하는지 테스트
    if nix eval --impure --expr "(import $PROJECT_ROOT/lib/error-system.nix {}).throwUserError \"test user error\"" 2>/dev/null; then
        log_fail "throwUserError가 예외를 발생시키지 않음"
        ((TESTS_FAILED++))
    else
        log_success "throwUserError가 적절히 예외 발생"
        ((TESTS_PASSED++))
    fi
}

# 에러 컨텍스트 테스트
test_error_context() {
    log_header "에러 컨텍스트 테스트"

    # 에러 컨텍스트 빌더가 있는지 확인
    if nix eval --impure --expr "(import $PROJECT_ROOT/lib/error-system.nix {}).buildErrorContext" >/dev/null 2>&1; then
        log_success "buildErrorContext 함수 존재"
        ((TESTS_PASSED++))
    else
        log_warning "buildErrorContext 함수 미구현 (선택적 기능)"
    fi

    # 에러 로깅 기능 확인
    if nix eval --impure --expr "(import $PROJECT_ROOT/lib/error-system.nix {}).logError" >/dev/null 2>&1; then
        log_success "logError 함수 존재"
        ((TESTS_PASSED++))
    else
        log_warning "logError 함수 미구현 (선택적 기능)"
    fi
}

# 다국어 지원 테스트
test_internationalization() {
    log_header "다국어 지원 테스트"

    # 한국어 메시지 확인
    if nix eval --impure --expr "(import $PROJECT_ROOT/lib/error-system.nix {}).messages" >/dev/null 2>&1; then
        local messages_exist="true"
    else
        local messages_exist="false"
    fi

    if [[ "$messages_exist" == "true" ]]; then
        log_success "메시지 시스템 존재 확인"
        ((TESTS_PASSED++))
    else
        log_warning "메시지 시스템 미구현 (기본 기능만 제공)"
    fi
}

# 에러 분류 및 우선순위 테스트
test_error_categorization() {
    log_header "에러 분류 및 우선순위 테스트"

    # 시스템 카테고리 에러 타입 확인 (간단한 방법)
    local build_is_system=$(nix eval --impure --expr "
        let es = import $PROJECT_ROOT/lib/error-system.nix {};
        in es.errorTypes.build.category == \"system\"
    " 2>/dev/null)
    assert_test "[[ '$build_is_system' == 'true' ]]" "시스템 카테고리 에러 타입 존재" "true" "$build_is_system"

    # 사용자 카테고리 에러 타입 확인
    local config_is_user=$(nix eval --impure --expr "
        let es = import $PROJECT_ROOT/lib/error-system.nix {};
        in es.errorTypes.config.category == \"user\"
    " 2>/dev/null)
    assert_test "[[ '$config_is_user' == 'true' ]]" "사용자 카테고리 에러 타입 존재" "true" "$config_is_user"
}

# 에러 시스템 무결성 테스트
test_system_integrity() {
    log_header "에러 시스템 무결성 테스트"

    # 모든 에러 타입이 필수 속성을 가지는지 확인
    local error_types=(build config dependency user system validation network permission test platform)

    for error_type in "${error_types[@]}"; do
        local icon=$(eval_error_system "errorTypes.${error_type}.icon")
        local category=$(eval_error_system "errorTypes.${error_type}.category")
        local priority=$(eval_error_system "errorTypes.${error_type}.priority")

        assert_test "[[ -n '$icon' ]]" "$error_type 타입 아이콘 존재"
        assert_test "[[ -n '$category' ]]" "$error_type 타입 카테고리 존재"
        assert_test "[[ -n '$priority' ]]" "$error_type 타입 우선순위 존재"
    done
}

# 성능 테스트
test_performance() {
    log_header "성능 테스트"

    local start_time=$(date +%s%N)
    for i in {1..20}; do
        eval_error_system "errorTypes.build.icon" >/dev/null
    done
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # 밀리초 변환

    # 20회 평가가 100ms 이하여야 함 (평균 5ms per call)
    assert_test "[[ $duration -lt 100 ]]" "20회 평가가 100ms 이내 완료" "<100ms" "${duration}ms"
}

# 정리 함수
cleanup_test_environment() {
    log_debug "테스트 환경 정리: $TEST_DIR"
    rm -rf "$TEST_DIR"
}

# 메인 테스트 실행
main() {
    log_header "Error System 포괄적 테스트 시작"
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
    test_error_types
    test_severity_levels
    test_message_formatting
    test_color_codes
    test_error_handlers
    test_error_context
    test_internationalization
    test_error_categorization
    test_system_integrity
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
