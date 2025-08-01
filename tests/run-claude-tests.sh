#!/usr/bin/env bash
# ABOUTME: Claude commands 관련 모든 테스트를 실행하는 통합 테스트 러너
# ABOUTME: 단위 테스트, 통합 테스트, E2E 테스트를 순서대로 실행하고 결과를 종합합니다.

set -euo pipefail

# 스크립트 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 테스트 결과 추적
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TEST_RESULTS=()

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}[TEST SUITE]${NC} $1"
}

log_separator() {
    echo -e "${CYAN}============================================${NC}"
}

# 도움말 표시
show_help() {
    cat << 'EOF'
Claude Commands 테스트 러너

사용법:
  ./run-claude-tests.sh [옵션]

옵션:
  --unit-only     단위 테스트만 실행
  --integration-only  통합 테스트만 실행
  --e2e-only      E2E 테스트만 실행
  --verbose       상세한 출력 표시
  --help, -h      이 도움말 표시

예시:
  ./run-claude-tests.sh              # 모든 테스트 실행
  ./run-claude-tests.sh --unit-only  # 단위 테스트만 실행
  ./run-claude-tests.sh --verbose    # 상세 모드로 모든 테스트 실행

테스트 종류:
  1. 단위 테스트 (Unit Tests)
     - claude-activation.nix 로직 테스트
     - 파일 복사 및 해시 비교 기능 검증

  2. 통합 테스트 (Integration Tests)
     - build-switch와 Claude commands 통합 테스트
     - 실제 환경과 유사한 조건에서 테스트

  3. E2E 테스트 (End-to-End Tests)
     - 전체 사용자 워크플로우 시뮬레이션
     - 첫 설정부터 업데이트까지 전 과정 검증
EOF
}

# 테스트 결과 추가
add_test_result() {
    local test_name="$1"
    local status="$2" # "PASS" or "FAIL"
    local details="$3"

    TEST_RESULTS+=("$status|$test_name|$details")
    ((TOTAL_TESTS++))

    if [[ "$status" == "PASS" ]]; then
        ((TOTAL_PASSED++))
    else
        ((TOTAL_FAILED++))
    fi
}

# 단위 테스트 실행
run_unit_tests() {
    log_header "단위 테스트 실행 중..."
    log_separator

    local unit_test_script="$SCRIPT_DIR/unit/test-claude-activation.sh"

    if [[ ! -f "$unit_test_script" ]]; then
        log_error "단위 테스트 스크립트를 찾을 수 없습니다: $unit_test_script"
        add_test_result "Unit Tests" "FAIL" "테스트 스크립트 누락"
        return 1
    fi

    log_info "Claude activation 단위 테스트 실행..."

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        if bash "$unit_test_script"; then
            add_test_result "Unit Tests" "PASS" "모든 단위 테스트 통과"
            log_info "✅ 단위 테스트 성공"
        else
            add_test_result "Unit Tests" "FAIL" "일부 단위 테스트 실패"
            log_error "❌ 단위 테스트 실패"
            return 1
        fi
    else
        if bash "$unit_test_script" >/dev/null 2>&1; then
            add_test_result "Unit Tests" "PASS" "모든 단위 테스트 통과"
            log_info "✅ 단위 테스트 성공"
        else
            add_test_result "Unit Tests" "FAIL" "일부 단위 테스트 실패"
            log_error "❌ 단위 테스트 실패"
            log_info "상세한 오류를 보려면 --verbose 옵션을 사용하세요"
            return 1
        fi
    fi

    echo
}

# 통합 테스트 실행
run_integration_tests() {
    log_header "통합 테스트 실행 중..."
    log_separator

    local integration_test_script="$SCRIPT_DIR/integration/test-build-switch-claude-integration.sh"

    if [[ ! -f "$integration_test_script" ]]; then
        log_error "통합 테스트 스크립트를 찾을 수 없습니다: $integration_test_script"
        add_test_result "Integration Tests" "FAIL" "테스트 스크립트 누락"
        return 1
    fi

    log_info "Build-switch Claude 통합 테스트 실행..."

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        if bash "$integration_test_script"; then
            add_test_result "Integration Tests" "PASS" "모든 통합 테스트 통과"
            log_info "✅ 통합 테스트 성공"
        else
            add_test_result "Integration Tests" "FAIL" "일부 통합 테스트 실패"
            log_error "❌ 통합 테스트 실패"
            return 1
        fi
    else
        if bash "$integration_test_script" >/dev/null 2>&1; then
            add_test_result "Integration Tests" "PASS" "모든 통합 테스트 통과"
            log_info "✅ 통합 테스트 성공"
        else
            add_test_result "Integration Tests" "FAIL" "일부 통합 테스트 실패"
            log_error "❌ 통합 테스트 실패"
            log_info "상세한 오류를 보려면 --verbose 옵션을 사용하세요"
            return 1
        fi
    fi

    echo
}

# E2E 테스트 실행
run_e2e_tests() {
    log_header "E2E 테스트 실행 중..."
    log_separator

    local e2e_test_script="$SCRIPT_DIR/e2e/test-claude-commands-end-to-end.sh"

    if [[ ! -f "$e2e_test_script" ]]; then
        log_error "E2E 테스트 스크립트를 찾을 수 없습니다: $e2e_test_script"
        add_test_result "E2E Tests" "FAIL" "테스트 스크립트 누락"
        return 1
    fi

    log_info "Claude commands E2E 테스트 실행..."
    log_warning "E2E 테스트는 시간이 걸릴 수 있습니다..."

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        if bash "$e2e_test_script"; then
            add_test_result "E2E Tests" "PASS" "모든 E2E 테스트 통과"
            log_info "✅ E2E 테스트 성공"
        else
            add_test_result "E2E Tests" "FAIL" "일부 E2E 테스트 실패"
            log_error "❌ E2E 테스트 실패"
            return 1
        fi
    else
        if bash "$e2e_test_script" >/dev/null 2>&1; then
            add_test_result "E2E Tests" "PASS" "모든 E2E 테스트 통과"
            log_info "✅ E2E 테스트 성공"
        else
            add_test_result "E2E Tests" "FAIL" "일부 E2E 테스트 실패"
            log_error "❌ E2E 테스트 실패"
            log_info "상세한 오류를 보려면 --verbose 옵션을 사용하세요"
            return 1
        fi
    fi

    echo
}

# 테스트 환경 검증
validate_test_environment() {
    log_info "테스트 환경 검증 중..."

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

    # 테스트 스크립트 실행 권한 확인 및 일괄 설정
    local test_scripts=(
        "$SCRIPT_DIR/unit/test-claude-activation.sh"
        "$SCRIPT_DIR/integration/test-build-switch-claude-integration.sh"
        "$SCRIPT_DIR/e2e/test-claude-commands-end-to-end.sh"
    )

    local scripts_to_fix=()
    for script in "${test_scripts[@]}"; do
        if [[ -f "$script" ]] && [[ ! -x "$script" ]]; then
            scripts_to_fix+=("$script")
        fi
    done

    if [[ ${#scripts_to_fix[@]} -gt 0 ]]; then
        log_warning "실행 권한 없는 스크립트들에 권한 추가 중..."
        chmod +x "${scripts_to_fix[@]}"
        log_info "권한 추가 완료: ${#scripts_to_fix[@]}개 파일"
    fi

    # Claude 설정 파일 확인
    local claude_config_dir="$PROJECT_ROOT/modules/shared/config/claude"
    if [[ ! -d "$claude_config_dir/commands/git" ]]; then
        log_error "Claude git commands 디렉토리 누락: $claude_config_dir/commands/git"
        return 1
    fi

    local git_commands=("commit.md" "fix-pr.md" "upsert-pr.md")
    for cmd in "${git_commands[@]}"; do
        if [[ ! -f "$claude_config_dir/commands/git/$cmd" ]]; then
            log_error "Git command 파일 누락: $cmd"
            return 1
        fi
    done

    log_info "✅ 테스트 환경 검증 완료"
    return 0
}

# 최종 결과 출력
print_final_results() {
    log_separator
    log_header "최종 테스트 결과"
    log_separator

    echo -e "${CYAN}전체 결과 요약:${NC}"
    echo -e "  총 테스트 스위트: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "  통과: ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "  실패: ${RED}$TOTAL_FAILED${NC}"

    if [[ ${#TEST_RESULTS[@]} -gt 0 ]]; then
        echo
        echo -e "${CYAN}상세 결과:${NC}"
        for result in "${TEST_RESULTS[@]}"; do
            IFS='|' read -r status name details <<< "$result"
            if [[ "$status" == "PASS" ]]; then
                echo -e "  ${GREEN}✅ $name${NC}: $details"
            else
                echo -e "  ${RED}❌ $name${NC}: $details"
            fi
        done
    fi

    echo
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        log_info "🎉 모든 테스트가 성공했습니다!"
        log_info "Claude commands git 파일 이동 기능이 완전히 작동합니다."
        echo
        log_info "검증된 기능:"
        log_info "  ✅ 서브디렉토리 지원 파일 복사"
        log_info "  ✅ 사용자 수정사항 보존"
        log_info "  ✅ build-switch 통합"
        log_info "  ✅ 전체 워크플로우"
        return 0
    else
        log_error "일부 테스트가 실패했습니다."
        log_info "실패한 테스트를 확인하고 문제를 해결해주세요."
        return 1
    fi
}

# 메인 함수
main() {
    local run_unit=true
    local run_integration=true
    local run_e2e=true

    # 인수 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                run_unit=true
                run_integration=false
                run_e2e=false
                shift
                ;;
            --integration-only)
                run_unit=false
                run_integration=true
                run_e2e=false
                shift
                ;;
            --e2e-only)
                run_unit=false
                run_integration=false
                run_e2e=true
                shift
                ;;
            --verbose)
                export VERBOSE=true
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

    log_header "Claude Commands 테스트 러너 시작"
    log_info "프로젝트 루트: $PROJECT_ROOT"
    log_info "테스트 디렉토리: $SCRIPT_DIR"

    # 테스트 환경 검증
    if ! validate_test_environment; then
        log_error "테스트 환경 검증 실패"
        exit 1
    fi

    echo
    local has_failures=false

    # 선택된 테스트 실행
    if [[ "$run_unit" == "true" ]]; then
        if ! run_unit_tests; then
            has_failures=true
        fi
    fi

    if [[ "$run_integration" == "true" ]]; then
        if ! run_integration_tests; then
            has_failures=true
        fi
    fi

    if [[ "$run_e2e" == "true" ]]; then
        if ! run_e2e_tests; then
            has_failures=true
        fi
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
