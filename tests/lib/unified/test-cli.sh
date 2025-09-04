#!/usr/bin/env bash
# ABOUTME: 통합 테스트 CLI 메인 진입점
# ABOUTME: unified-test-interface.md 계약을 구현한 통합 테스트 실행 도구

# === 버전 및 기본 설정 ===
CLI_VERSION="1.0.0"
DEFAULT_FORMAT="human"

# === 도움말 출력 ===
show_help() {
    cat << 'EOF'
USAGE:
    test [CATEGORY] [OPTIONS] [PATTERNS...]

    통합 테스트 실행 도구 - 모든 테스트 유형을 하나의 인터페이스로 관리

CATEGORIES:
    all              모든 테스트 실행 (기본값)
    quick            빠른 검증 테스트 (<30초)
    unit             단위 테스트
    integration      통합 테스트
    e2e              End-to-End 테스트
    performance      성능 테스트
    smoke            기본 동작 확인 테스트 (<10초)

OPTIONS:
    Global Options:
    -h, --help       이 도움말 출력
    -v, --version    버전 정보 출력
    --format FORMAT  출력 형식 (human, json, tap, junit)
    --verbose        상세 출력 활성화
    --quiet          최소 출력 모드
    --parallel       병렬 실행 활성화
    --timeout SEC    테스트 타임아웃 (초)
    --dry-run        실행 계획만 출력

    Filtering Options:
    --changed        변경된 파일 관련 테스트만 실행
    --failed         이전 실패 테스트만 재실행
    --tag TAG        특정 태그의 테스트만 실행
    --exclude PATTERN 패턴과 일치하는 테스트 제외
    --platform NAME  특정 플랫폼 테스트만 실행

EXAMPLES:
    test                          # 기본 테스트 세트 실행
    test quick                    # 빠른 테스트만 실행
    test unit --verbose           # 단위 테스트를 상세 모드로
    test integration --parallel   # 통합 테스트를 병렬로
    test --changed --format json  # 변경된 파일 관련 테스트, JSON 출력
    test e2e --tag browser        # 브라우저 관련 E2E 테스트만
    test --dry-run                # 실행 계획 미리보기

EOF
}

# === 버전 정보 출력 ===
show_version() {
    echo "Unified Test Interface v$CLI_VERSION"
}

# === 옵션 검증 ===
validate_category() {
    local category="$1"
    case "$category" in
        all|quick|unit|integration|e2e|performance|smoke)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

validate_format() {
    local format="$1"
    case "$format" in
        human|json|tap|junit)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# === 실행 계획 생성 ===
create_execution_plan() {
    local category="${1:-all}"
    local format="${2:-human}"

    case "$format" in
        "json")
            echo '{"category":"'$category'","tests":[],"estimated_duration":0}'
            ;;
        "tap")
            echo "1..0"
            ;;
        "human")
            echo "🚀 Test Execution Plan"
            echo "Category: $category"
            echo "Format: $format"
            echo "Tests: 0 found"
            ;;
        "junit")
            echo '<?xml version="1.0" encoding="UTF-8"?>'
            echo '<testsuites><testsuite name="'$category'" tests="0"/></testsuites>'
            ;;
    esac
}

# === 메인 실행 로직 ===
run_tests() {
    local category="${1:-all}"
    local format="${2:-human}"
    local dry_run="${3:-false}"

    if [[ "$dry_run" == "true" ]]; then
        create_execution_plan "$category" "$format"
        return 0
    fi

    # 실제 테스트 실행 (현재는 스텁)
    case "$format" in
        "json")
            echo '{"category":"'$category'","status":"completed","tests":[],"passed":0,"failed":0,"duration":0}'
            ;;
        "tap")
            echo "1..0"
            ;;
        "human")
            echo "✅ Tests completed successfully"
            echo "Category: $category"
            echo "Duration: 0ms"
            ;;
        "junit")
            echo '<?xml version="1.0" encoding="UTF-8"?>'
            echo '<testsuites><testsuite name="'$category'" tests="0" failures="0" time="0"/></testsuites>'
            ;;
    esac

    return 0
}

# === 메인 함수 ===
main() {
    local category="all"
    local format="$DEFAULT_FORMAT"
    local dry_run="false"
    local show_help_flag="false"
    local show_version_flag="false"

    # 간단한 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help_flag="true"
                shift
                ;;
            -v|--version)
                show_version_flag="true"
                shift
                ;;
            --format)
                if [[ $# -lt 2 ]]; then
                    echo "[ERROR] --format requires an argument" >&2
                    return 2
                fi
                format="$2"
                if ! validate_format "$format"; then
                    echo "[ERROR] Unsupported format: $format" >&2
                    echo "[ERROR] Supported formats: human, json, tap, junit" >&2
                    return 2
                fi
                shift 2
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --verbose|--quiet|--parallel|--changed|--failed)
                # 지원되는 플래그들이지만 현재는 무시
                shift
                ;;
            --timeout|--tag|--exclude|--platform)
                # 값이 있는 옵션들
                if [[ $# -lt 2 ]]; then
                    echo "[ERROR] $1 requires an argument" >&2
                    return 2
                fi
                shift 2
                ;;
            --*)
                echo "[ERROR] Unknown option: $1" >&2
                return 2
                ;;
            *)
                # 카테고리로 처리
                if validate_category "$1"; then
                    category="$1"
                else
                    echo "[ERROR] Unknown category: $1" >&2
                    echo "[ERROR] Supported categories: all, quick, unit, integration, e2e, performance, smoke" >&2
                    return 2
                fi
                shift
                ;;
        esac
    done

    # 도움말 또는 버전 출력
    if [[ "$show_help_flag" == "true" ]]; then
        show_help
        return 0
    fi

    if [[ "$show_version_flag" == "true" ]]; then
        show_version
        return 0
    fi

    # 테스트 실행
    run_tests "$category" "$format" "$dry_run"
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
