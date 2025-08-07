#!/usr/bin/env bash
# ABOUTME: Claude commands 관련 모든 테스트를 실행하는 통합 테스트 러너 (개선된 버전)
# ABOUTME: 공통 라이브러리 사용, 향상된 에러 처리

set -euo pipefail

# =======================
# 초기 설정 및 라이브러리 로드
# =======================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 공통 라이브러리 로드
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    # shellcheck source=lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
else
    echo "❌ 공통 라이브러리를 찾을 수 없습니다: $SCRIPT_DIR/lib/common.sh" >&2
    exit 1
fi

# 설정 파일 로드
if [[ -f "$SCRIPT_DIR/config/test-config.sh" ]]; then
    # shellcheck source=config/test-config.sh
    source "$SCRIPT_DIR/config/test-config.sh"
fi

# =======================
# 테스트 러너 설정
# =======================

# 실행할 테스트 종류 플래그
RUN_UNIT=true
RUN_INTEGRATION=true
RUN_E2E=true

# 테스트 결과 추적
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

# =======================
# 도움말
# =======================

show_help() {
    cat << 'EOF'
Claude Commands 테스트 러너 (개선된 버전)

사용법:
  ./run-claude-tests.sh [옵션]

옵션:
  --unit-only         단위 테스트만 실행
  --integration-only  통합 테스트만 실행
  --e2e-only          E2E 테스트만 실행
  --verbose           상세한 출력 표시
  --debug             디버그 정보 포함
  --help, -h          이 도움말 표시

예시:
  ./run-claude-tests.sh              # 모든 테스트 실행
  ./run-claude-tests.sh --unit-only  # 단위 테스트만 실행
  ./run-claude-tests.sh --verbose    # 상세 모드로 실행
EOF
}

# =======================
# 환경 검증 함수들
# =======================

validate_test_environment() {
    log_info "테스트 환경 검증 시작..."

    # 필수 도구 확인
    if ! check_required_tools "bash" "find" "mkdir" "chmod"; then
        return 1
    fi

    # 필수 디렉토리 확인
    local required_dirs=(
        "$SCRIPT_DIR/unit"
        "$SCRIPT_DIR/integration"
        "$SCRIPT_DIR/e2e"
        "$PROJECT_ROOT/modules/shared/config/claude"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "필수 디렉토리 누락: $dir"
            return 1
        fi
    done

    # 테스트 스크립트 실행 권한 확인
    local test_scripts=()
    mapfile -t test_scripts < <(find "$SCRIPT_DIR" -name "test-*.sh" -type f)

    local scripts_fixed=0
    for script in "${test_scripts[@]}"; do
        if [[ ! -x "$script" ]]; then
            chmod +x "$script"
            ((scripts_fixed++))
            log_debug "실행 권한 추가: $(basename "$script")"
        fi
    done

    if [[ $scripts_fixed -gt 0 ]]; then
        log_info "테스트 스크립트 실행 권한 수정: ${scripts_fixed}개"
    fi

    log_success "테스트 환경 검증 완료"
    return 0
}

# =======================
# 테스트 실행 함수들
# =======================

run_unit_tests() {
    log_header "단위 테스트 실행"

    local unit_test_script="$SCRIPT_DIR/unit/test-claude-activation.sh"

    if [[ ! -f "$unit_test_script" ]]; then
        log_error "단위 테스트 스크립트 누락: $unit_test_script"
        return 1
    fi

    log_info "Claude activation 단위 테스트 실행..."

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        if bash "$unit_test_script"; then
            log_success "단위 테스트 성공"
            ((TOTAL_PASSED++))
        else
            log_fail "단위 테스트 실패"
            ((TOTAL_FAILED++))
            return 1
        fi
    else
        if bash "$unit_test_script" >/dev/null 2>&1; then
            log_success "단위 테스트 성공"
            ((TOTAL_PASSED++))
        else
            log_fail "단위 테스트 실패"
            ((TOTAL_FAILED++))
            log_info "상세한 오류를 보려면 --verbose 옵션을 사용하세요"
            return 1
        fi
    fi
}

run_integration_tests() {
    log_header "통합 테스트 실행"

    local integration_test_script="$SCRIPT_DIR/integration/test-build-switch-claude-integration.sh"

    if [[ ! -f "$integration_test_script" ]]; then
        log_error "통합 테스트 스크립트 누락: $integration_test_script"
        return 1
    fi

    log_info "Build-switch Claude 통합 테스트 실행..."

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        if bash "$integration_test_script"; then
            log_success "통합 테스트 성공"
            ((TOTAL_PASSED++))
        else
            log_fail "통합 테스트 실패"
            ((TOTAL_FAILED++))
            return 1
        fi
    else
        if bash "$integration_test_script" >/dev/null 2>&1; then
            log_success "통합 테스트 성공"
            ((TOTAL_PASSED++))
        else
            log_fail "통합 테스트 실패"
            ((TOTAL_FAILED++))
            log_info "상세한 오류를 보려면 --verbose 옵션을 사용하세요"
            return 1
        fi
    fi
}

run_e2e_tests() {
    log_header "E2E 테스트 실행"

    local e2e_test_script="$SCRIPT_DIR/e2e/test-claude-commands-end-to-end.sh"

    if [[ ! -f "$e2e_test_script" ]]; then
        log_error "E2E 테스트 스크립트 누락: $e2e_test_script"
        return 1
    fi

    log_info "Claude commands E2E 테스트 실행..."
    log_warning "E2E 테스트는 시간이 오래 걸릴 수 있습니다..."

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        if bash "$e2e_test_script"; then
            log_success "E2E 테스트 성공"
            ((TOTAL_PASSED++))
        else
            log_fail "E2E 테스트 실패"
            ((TOTAL_FAILED++))
            return 1
        fi
    else
        if bash "$e2e_test_script" >/dev/null 2>&1; then
            log_success "E2E 테스트 성공"
            ((TOTAL_PASSED++))
        else
            log_fail "E2E 테스트 실패"
            ((TOTAL_FAILED++))
            log_info "상세한 오류를 보려면 --verbose 옵션을 사용하세요"
            return 1
        fi
    fi
}

# =======================
# 최종 결과 출력
# =======================

print_final_results() {
    log_separator
    log_header "최종 테스트 결과"
    log_separator

    echo -e "${CYAN}전체 결과 요약:${NC}"
    echo -e "  총 테스트 스위트: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "  통과: ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "  실패: ${RED}$TOTAL_FAILED${NC}"

    echo
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        log_success "모든 테스트가 성공했습니다! 🎉"
        log_info "Claude commands git 파일 이동 기능이 완전히 작동합니다."
        return 0
    else
        log_error "일부 테스트가 실패했습니다."
        return 1
    fi
}

# =======================
# 메인 함수
# =======================

main() {
    # 인수 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                RUN_UNIT=true
                RUN_INTEGRATION=false
                RUN_E2E=false
                shift
                ;;
            --integration-only)
                RUN_UNIT=false
                RUN_INTEGRATION=true
                RUN_E2E=false
                shift
                ;;
            --e2e-only)
                RUN_UNIT=false
                RUN_INTEGRATION=false
                RUN_E2E=true
                shift
                ;;
            --verbose)
                export VERBOSE=true
                shift
                ;;
            --debug)
                export DEBUG=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 시작 메시지
    log_header "Claude Commands 테스트 러너 (개선된 버전)"
    log_info "프로젝트 루트: $PROJECT_ROOT"
    log_info "테스트 디렉토리: $SCRIPT_DIR"

    # 환경 검증
    if ! validate_test_environment; then
        log_error "테스트 환경 검증 실패"
        exit 1
    fi

    echo

    # 테스트 실행
    local has_failures=false

    if [[ "$RUN_UNIT" == "true" ]]; then
        ((TOTAL_TESTS++))
        if ! run_unit_tests; then
            has_failures=true
        fi
        echo
    fi

    if [[ "$RUN_INTEGRATION" == "true" ]]; then
        ((TOTAL_TESTS++))
        if ! run_integration_tests; then
            has_failures=true
        fi
        echo
    fi

    if [[ "$RUN_E2E" == "true" ]]; then
        ((TOTAL_TESTS++))
        if ! run_e2e_tests; then
            has_failures=true
        fi
        echo
    fi

    # 최종 결과 출력
    if ! print_final_results; then
        exit 1
    fi

    if [[ "$has_failures" == "true" ]]; then
        exit 1
    fi

    exit 0
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
