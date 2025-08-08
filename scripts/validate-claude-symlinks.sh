#!/usr/bin/env bash
# validate-claude-symlinks.sh - Claude Code 심볼릭 링크 무결성 검증 및 복구
# ABOUTME: build-switch 실행 시 Claude 설정 심볼릭 링크의 무결성을 검증하고 문제 시 자동 복구

set -euo pipefail

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 전역 변수
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SOURCE_DIR="${PROJECT_ROOT}/modules/shared/config/claude"
VALIDATION_LOG="${XDG_STATE_HOME:-$HOME/.local/state}/claude-symlinks/validation_$(date +%s).log"
VERBOSE=${VERBOSE:-false}
DRY_RUN=${DRY_RUN:-false}
AUTO_FIX=${AUTO_FIX:-true}

# 검증 결과 추적
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
FIXED_ISSUES=0

# 로그 함수들
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$VALIDATION_LOG"
    else
        echo -e "${BLUE}[DEBUG]${NC} $1" >> "$VALIDATION_LOG"
    fi
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$VALIDATION_LOG"
}

# 실행 함수 (DRY_RUN 지원)
execute_cmd() {
    local cmd="$1"
    local description="${2:-명령어 실행}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY RUN] $description: $cmd"
        return 0
    else
        log_debug "$description: $cmd"
        eval "$cmd"
    fi
}

# 초기화
initialize_validation() {
    log_info "=== Claude Code 심볼릭 링크 검증 시작 ==="
    log_info "프로젝트 루트: $PROJECT_ROOT"
    log_info "Claude 디렉토리: $CLAUDE_DIR"
    log_info "소스 디렉토리: $SOURCE_DIR"
    log_info "검증 로그: $VALIDATION_LOG"

    # 검증 로그 디렉토리 생성
    mkdir -p "$(dirname "$VALIDATION_LOG")"

    # 검증 시작 로그
    cat >> "$VALIDATION_LOG" << EOF

=====================================
Claude 심볼릭 링크 검증 시작
=====================================
시작 시간: $(date -Iseconds)
프로젝트 루트: $PROJECT_ROOT
Claude 디렉토리: $CLAUDE_DIR
소스 디렉토리: $SOURCE_DIR
자동 수정: $AUTO_FIX
드라이런: $DRY_RUN
상세 로그: $VERBOSE
=====================================

EOF
}

# 기본 디렉토리 구조 검증
validate_directory_structure() {
    log_info "디렉토리 구조 검증 중..."
    local issues_found=false

    # 소스 디렉토리 존재 확인
    ((TOTAL_CHECKS++))
    if [[ -d "$SOURCE_DIR" ]]; then
        log_success "✅ 소스 디렉토리 존재: $SOURCE_DIR"
        ((PASSED_CHECKS++))
    else
        log_error "❌ 소스 디렉토리 없음: $SOURCE_DIR"
        ((FAILED_CHECKS++))
        issues_found=true
    fi

    # Claude 디렉토리 존재 확인
    ((TOTAL_CHECKS++))
    if [[ -d "$CLAUDE_DIR" ]]; then
        log_success "✅ Claude 디렉토리 존재: $CLAUDE_DIR"
        ((PASSED_CHECKS++))
    else
        log_warning "⚠️ Claude 디렉토리 없음: $CLAUDE_DIR"
        if [[ "$AUTO_FIX" == "true" ]]; then
            execute_cmd "mkdir -p '$CLAUDE_DIR'" "Claude 디렉토리 생성"
            log_success "🔧 Claude 디렉토리 생성됨"
            ((FIXED_ISSUES++))
            ((PASSED_CHECKS++))
        else
            ((FAILED_CHECKS++))
            issues_found=true
        fi
    fi

    # 필수 서브디렉토리들 확인
    local required_subdirs=("commands" "agents")
    for subdir in "${required_subdirs[@]}"; do
        ((TOTAL_CHECKS++))
        local source_subdir="$SOURCE_DIR/$subdir"
        local target_subdir="$CLAUDE_DIR/$subdir"

        if [[ -d "$source_subdir" ]]; then
            log_debug "소스 서브디렉토리 확인: $source_subdir"
            ((PASSED_CHECKS++))
        else
            log_error "❌ 소스 서브디렉토리 없음: $source_subdir"
            ((FAILED_CHECKS++))
            issues_found=true
        fi
    done

    if [[ "$issues_found" == "true" ]]; then
        return 1
    else
        return 0
    fi
}

# 심볼릭 링크 무결성 검증
validate_symlink_integrity() {
    log_info "심볼릭 링크 무결성 검증 중..."
    local issues_found=false

    # 폴더 심볼릭 링크들 검증
    local folder_links=("commands" "agents")
    for folder in "${folder_links[@]}"; do
        ((TOTAL_CHECKS++))
        local target_path="$CLAUDE_DIR/$folder"
        local expected_source="$SOURCE_DIR/$folder"

        if [[ -L "$target_path" ]]; then
            # 심볼릭 링크 존재 - 타겟 검증
            local actual_target=$(readlink "$target_path")
            local resolved_target=$(realpath "$target_path" 2>/dev/null || echo "")
            local expected_resolved=$(realpath "$expected_source" 2>/dev/null || echo "")

            log_debug "폴더 링크 검증: $folder"
            log_debug "  실제 타겟: $actual_target"
            log_debug "  해석된 타겟: $resolved_target"
            log_debug "  기대하는 해석된 경로: $expected_resolved"

            if [[ -d "$resolved_target" && "$resolved_target" == "$expected_resolved" ]]; then
                log_success "✅ 폴더 심볼릭 링크 올바름: $folder -> $actual_target"
                ((PASSED_CHECKS++))
            else
                log_error "❌ 폴더 심볼릭 링크 문제: $folder"
                log_error "   현재 타겟: $actual_target"
                log_error "   기대 타겟: $expected_source"
                ((FAILED_CHECKS++))
                issues_found=true

                # 자동 수정
                if [[ "$AUTO_FIX" == "true" && -d "$expected_source" ]]; then
                    execute_cmd "rm -f '$target_path'" "잘못된 폴더 링크 제거"
                    execute_cmd "ln -sf '$expected_source' '$target_path'" "올바른 폴더 링크 생성"
                    log_success "🔧 폴더 심볼릭 링크 수정됨: $folder"
                    ((FIXED_ISSUES++))
                fi
            fi
        else
            # 심볼릭 링크 없음
            if [[ -d "$target_path" ]]; then
                log_warning "⚠️ 일반 디렉토리가 존재함 (심볼릭 링크 아님): $folder"
                ((FAILED_CHECKS++))
                issues_found=true

                if [[ "$AUTO_FIX" == "true" ]]; then
                    execute_cmd "rm -rf '$target_path'" "일반 디렉토리 제거"
                    execute_cmd "ln -sf '$expected_source' '$target_path'" "폴더 심볼릭 링크 생성"
                    log_success "🔧 일반 디렉토리를 심볼릭 링크로 변경: $folder"
                    ((FIXED_ISSUES++))
                fi
            else
                log_warning "⚠️ 폴더 심볼릭 링크 없음: $folder"
                ((FAILED_CHECKS++))
                issues_found=true

                if [[ "$AUTO_FIX" == "true" && -d "$expected_source" ]]; then
                    execute_cmd "ln -sf '$expected_source' '$target_path'" "폴더 심볼릭 링크 생성"
                    log_success "🔧 폴더 심볼릭 링크 생성됨: $folder"
                    ((FIXED_ISSUES++))
                fi
            fi
        fi
    done

    if [[ "$issues_found" == "true" ]]; then
        return 1
    else
        return 0
    fi
}

# 파일 심볼릭 링크 검증
validate_file_symlinks() {
    log_info "파일 심볼릭 링크 검증 중..."
    local issues_found=false

    # 루트 레벨 설정 파일들 검증
    for source_file in "$SOURCE_DIR"/*.md "$SOURCE_DIR"/*.json; do
        if [[ -f "$source_file" ]]; then
            ((TOTAL_CHECKS++))
            local file_name=$(basename "$source_file")
            local target_file="$CLAUDE_DIR/$file_name"

            if [[ -L "$target_file" ]]; then
                # 심볼릭 링크 존재 - 타겟 검증
                local actual_target=$(readlink "$target_file")
                local resolved_target=$(realpath "$target_file" 2>/dev/null || echo "")
                local expected_resolved=$(realpath "$source_file" 2>/dev/null || echo "")

                log_debug "파일 링크 검증: $file_name"
                log_debug "  실제 타겟: $actual_target"
                log_debug "  해석된 타겟: $resolved_target"
                log_debug "  기대하는 해석된 경로: $expected_resolved"

                if [[ -f "$resolved_target" && "$resolved_target" == "$expected_resolved" ]]; then
                    log_success "✅ 파일 심볼릭 링크 올바름: $file_name"
                    ((PASSED_CHECKS++))
                else
                    log_error "❌ 파일 심볼릭 링크 문제: $file_name"
                    log_error "   현재 타겟: $actual_target"
                    log_error "   기대 타겟: $source_file"
                    ((FAILED_CHECKS++))
                    issues_found=true

                    # 자동 수정
                    if [[ "$AUTO_FIX" == "true" ]]; then
                        execute_cmd "rm -f '$target_file'" "잘못된 파일 링크 제거"
                        execute_cmd "ln -sf '$source_file' '$target_file'" "올바른 파일 링크 생성"
                        log_success "🔧 파일 심볼릭 링크 수정됨: $file_name"
                        ((FIXED_ISSUES++))
                    fi
                fi
            else
                # 심볼릭 링크 없음
                if [[ -f "$target_file" ]]; then
                    # 일반 파일 존재
                    log_debug "일반 파일 존재: $file_name (심볼릭 링크 아님)"

                    # settings.json과 CLAUDE.md는 사용자가 수정할 수 있으므로 경고만
                    case "$file_name" in
                        "settings.json"|"CLAUDE.md")
                            log_info "ℹ️ 사용자 설정 파일 존재: $file_name (수정 가능)"
                            ((PASSED_CHECKS++))
                            ;;
                        *)
                            log_warning "⚠️ 일반 파일이 존재함 (심볼릭 링크 아님): $file_name"
                            ((FAILED_CHECKS++))
                            issues_found=true
                            ;;
                    esac
                else
                    # 파일 없음
                    log_warning "⚠️ 파일 심볼릭 링크 없음: $file_name"
                    ((FAILED_CHECKS++))
                    issues_found=true

                    if [[ "$AUTO_FIX" == "true" ]]; then
                        execute_cmd "ln -sf '$source_file' '$target_file'" "파일 심볼릭 링크 생성"
                        log_success "🔧 파일 심볼릭 링크 생성됨: $file_name"
                        ((FIXED_ISSUES++))
                    fi
                fi
            fi
        fi
    done

    if [[ "$issues_found" == "true" ]]; then
        return 1
    else
        return 0
    fi
}

# 끊어진 심볼릭 링크 탐지
detect_broken_symlinks() {
    log_info "끊어진 심볼릭 링크 탐지 중..."
    local broken_links=()

    # Claude 디렉토리에서 모든 심볼릭 링크 검사
    while IFS= read -r -d '' link_file; do
        ((TOTAL_CHECKS++))
        local link_name=$(basename "$link_file")

        if [[ ! -e "$link_file" ]]; then
            log_error "❌ 끊어진 심볼릭 링크 발견: $link_name -> $(readlink "$link_file")"
            broken_links+=("$link_file")
            ((FAILED_CHECKS++))

            # 자동 복구
            if [[ "$AUTO_FIX" == "true" ]]; then
                execute_cmd "rm -f '$link_file'" "끊어진 링크 제거"
                log_success "🔧 끊어진 심볼릭 링크 제거됨: $link_name"
                ((FIXED_ISSUES++))
            fi
        else
            log_debug "심볼릭 링크 정상: $link_name"
            ((PASSED_CHECKS++))
        fi
    done < <(find "$CLAUDE_DIR" -type l -print0 2>/dev/null)

    if [[ ${#broken_links[@]} -gt 0 ]]; then
        log_warning "총 ${#broken_links[@]}개의 끊어진 심볼릭 링크 발견됨"
        return 1
    else
        log_success "끊어진 심볼릭 링크 없음"
        return 0
    fi
}

# 플랫폼별 호환성 검증
validate_platform_compatibility() {
    log_info "플랫폼별 호환성 검증 중..."
    local platform=$(uname)

    ((TOTAL_CHECKS++))
    case "$platform" in
        "Darwin")
            log_info "macOS 환경 감지됨"

            # macOS의 readlink 동작 확인
            if command -v readlink >/dev/null 2>&1; then
                local test_link="/tmp/claude_test_link_$$"
                execute_cmd "ln -sf '$HOME' '$test_link'" "테스트 링크 생성"

                local resolved_path=$(readlink "$test_link" 2>/dev/null || echo "")
                execute_cmd "rm -f '$test_link'" "테스트 링크 제거"

                if [[ -n "$resolved_path" ]]; then
                    log_success "✅ macOS readlink 동작 정상"
                    ((PASSED_CHECKS++))
                else
                    log_error "❌ macOS readlink 동작 문제"
                    ((FAILED_CHECKS++))
                    return 1
                fi
            else
                log_error "❌ readlink 명령어 없음 (macOS에서 필수)"
                ((FAILED_CHECKS++))
                return 1
            fi
            ;;
        "Linux")
            log_info "Linux 환경 감지됨"

            # Linux의 readlink 동작 확인 (GNU coreutils)
            if command -v readlink >/dev/null 2>&1; then
                if readlink --version 2>/dev/null | grep -q "GNU"; then
                    log_success "✅ GNU readlink 사용 가능"
                    ((PASSED_CHECKS++))
                else
                    log_warning "⚠️ GNU가 아닌 readlink 감지됨 (동작은 정상일 수 있음)"
                    ((PASSED_CHECKS++))
                fi
            else
                log_error "❌ readlink 명령어 없음 (Linux에서 필수)"
                ((FAILED_CHECKS++))
                return 1
            fi
            ;;
        *)
            log_warning "⚠️ 알 수 없는 플랫폼: $platform (테스트는 계속)"
            ((PASSED_CHECKS++))
            ;;
    esac

    return 0
}

# 권한 검증
validate_permissions() {
    log_info "파일 권한 검증 중..."
    local permission_issues=0

    # Claude 디렉토리의 모든 파일 권한 확인
    while IFS= read -r -d '' file_path; do
        ((TOTAL_CHECKS++))
        local file_name=$(basename "$file_path")
        local perms=$(stat -f "%A" "$file_path" 2>/dev/null || stat -c "%a" "$file_path" 2>/dev/null || echo "unknown")

        # .md와 .json 파일은 644 권한이어야 함
        if [[ "$file_name" =~ \.(md|json)$ ]]; then
            if [[ "$perms" == "644" ]]; then
                log_debug "권한 정상: $file_name ($perms)"
                ((PASSED_CHECKS++))
            else
                log_warning "⚠️ 권한 문제: $file_name ($perms, 기대값: 644)"
                ((FAILED_CHECKS++))
                ((permission_issues++))

                if [[ "$AUTO_FIX" == "true" ]]; then
                    execute_cmd "chmod 644 '$file_path'" "권한 수정"
                    log_success "🔧 권한 수정됨: $file_name -> 644"
                    ((FIXED_ISSUES++))
                fi
            fi
        else
            log_debug "권한 확인: $file_name ($perms)"
            ((PASSED_CHECKS++))
        fi
    done < <(find "$CLAUDE_DIR" -type f -print0 2>/dev/null)

    if [[ $permission_issues -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# 종합 보고서 생성
generate_validation_report() {
    log_info "=== 검증 결과 종합 보고서 ==="

    local success_rate=0
    if [[ $TOTAL_CHECKS -gt 0 ]]; then
        success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi

    # 콘솔 출력
    echo -e "\n${BLUE}=================== 검증 결과 ===================${NC}"
    echo -e "총 검사 항목: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "통과: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "실패: ${RED}$FAILED_CHECKS${NC}"
    echo -e "자동 수정: ${YELLOW}$FIXED_ISSUES${NC}"
    echo -e "성공률: ${GREEN}${success_rate}%${NC}"
    echo -e "${BLUE}================================================${NC}\n"

    # 로그 파일에 상세 보고서 기록
    cat >> "$VALIDATION_LOG" << EOF

=====================================
검증 결과 종합 보고서
=====================================
완료 시간: $(date -Iseconds)
총 검사 항목: $TOTAL_CHECKS
통과: $PASSED_CHECKS
실패: $FAILED_CHECKS
자동 수정: $FIXED_ISSUES
성공률: ${success_rate}%

환경 정보:
- 플랫폼: $(uname)
- 홈 디렉토리: $HOME
- 프로젝트 루트: $PROJECT_ROOT
- Claude 디렉토리: $CLAUDE_DIR
- 소스 디렉토리: $SOURCE_DIR

설정 정보:
- 자동 수정: $AUTO_FIX
- 드라이런: $DRY_RUN
- 상세 로그: $VERBOSE
=====================================

EOF

    # 결과에 따른 권장 사항 출력
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        if [[ "$AUTO_FIX" == "true" && $FIXED_ISSUES -gt 0 ]]; then
            log_success "🔧 총 $FIXED_ISSUES개 문제가 자동으로 수정되었습니다."
            if [[ $FAILED_CHECKS -gt $FIXED_ISSUES ]]; then
                log_warning "⚠️ 여전히 $((FAILED_CHECKS - FIXED_ISSUES))개 문제가 남아있습니다."
                log_warning "상세한 정보는 로그 파일을 확인하세요: $VALIDATION_LOG"
            fi
        else
            log_error "❌ $FAILED_CHECKS개 문제가 발견되었습니다."
            log_info "자동 수정을 원한다면: AUTO_FIX=true $0"
            log_info "상세한 정보는 로그 파일을 확인하세요: $VALIDATION_LOG"
        fi
    else
        log_success "🎉 모든 검증이 통과했습니다! Claude Code 심볼릭 링크가 정상적으로 설정되었습니다."
    fi

    log_info "검증 로그 파일: $VALIDATION_LOG"
}

# 사용법 출력
show_usage() {
    cat << EOF
사용법: $0 [옵션]

Claude Code 심볼릭 링크 무결성 검증 및 자동 복구 도구

옵션:
  -v, --verbose     상세한 로그 출력
  -d, --dry-run     실제 수정 없이 검사만 수행
  -n, --no-fix      자동 수정 비활성화
  -h, --help        이 도움말 출력

환경 변수:
  VERBOSE=true      상세한 로그 출력 활성화
  DRY_RUN=true      드라이런 모드 활성화
  AUTO_FIX=false    자동 수정 비활성화

예시:
  $0                          # 기본 검증 및 자동 수정
  $0 --verbose                # 상세 로그와 함께 실행
  $0 --dry-run                # 실제 변경 없이 검사만
  $0 --no-fix                 # 자동 수정 없이 검사만
  VERBOSE=true $0             # 환경변수로 상세 로그 활성화
  AUTO_FIX=false $0 --verbose # 자동 수정 없이 상세 검사

EOF
}

# 명령행 인자 처리
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -n|--no-fix)
                AUTO_FIX=false
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# 메인 함수
main() {
    # 명령행 인자 처리
    parse_arguments "$@"

    # 초기화
    initialize_validation

    # 검증 단계들 실행
    local validation_steps=(
        "validate_directory_structure"
        "validate_platform_compatibility"
        "validate_symlink_integrity"
        "validate_file_symlinks"
        "detect_broken_symlinks"
        "validate_permissions"
    )

    local failed_steps=0

    for step in "${validation_steps[@]}"; do
        if ! "$step"; then
            ((failed_steps++))
        fi
        echo  # 단계별 구분을 위한 빈 줄
    done

    # 종합 보고서 생성
    generate_validation_report

    # 종료 코드 결정
    if [[ $failed_steps -gt 0 ]]; then
        if [[ "$AUTO_FIX" == "true" && $FIXED_ISSUES -gt 0 ]]; then
            # 자동 수정으로 일부 또는 전부 해결됨
            if [[ $FAILED_CHECKS -le $FIXED_ISSUES ]]; then
                exit 0  # 모든 문제가 해결됨
            else
                exit 1  # 일부 문제가 남음
            fi
        else
            exit 1  # 문제가 있고 수정되지 않음
        fi
    else
        exit 0  # 모든 검증 통과
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
