#!/usr/bin/env bash
# ABOUTME: 통합 테스트 인터페이스 설정 파일
# ABOUTME: 새로운 통합 테스트 CLI의 모든 설정을 중앙 집중 관리

# === 통합 테스트 인터페이스 설정 ===
readonly TEST_INTERFACE_VERSION="1.0.0"

# 통합 인터페이스 활성화 여부
readonly UNIFIED_TEST_INTERFACE_ENABLED=${UNIFIED_TEST_INTERFACE_ENABLED:-true}

# === CLI 설정 ===
readonly DEFAULT_OUTPUT_FORMAT="human"  # human, json, tap, junit
readonly DEFAULT_PARALLEL_WORKERS="auto"  # auto, 1-16
readonly DEFAULT_STRATEGY="balanced"  # fast, balanced, comprehensive

# 지원되는 출력 형식
readonly SUPPORTED_FORMATS=("human" "json" "tap" "junit")

# 지원되는 테스트 카테고리
readonly SUPPORTED_CATEGORIES=("all" "quick" "unit" "integration" "e2e" "performance" "smoke")

# === 스마트 선택 설정 ===
readonly SMART_SELECTION_ENABLED=true
readonly SMART_SELECTION_CACHE_TTL=3600  # 1시간
readonly SMART_SELECTION_MAX_FILES=1000

# 변경사항 감지 설정
readonly CHANGE_DETECTION_METHOD="git"  # git, filesystem
readonly CHANGE_DETECTION_DEPTH=10  # Git 커밋 히스토리 깊이

# === 성능 설정 ===
# 카테고리별 최대 실행 시간 (초)
readonly CATEGORY_TIMEOUT_QUICK=30
readonly CATEGORY_TIMEOUT_UNIT=60
readonly CATEGORY_TIMEOUT_INTEGRATION=180
readonly CATEGORY_TIMEOUT_E2E=300
readonly CATEGORY_TIMEOUT_PERFORMANCE=600
readonly CATEGORY_TIMEOUT_SMOKE=10

# 성능 모니터링 설정
readonly PERFORMANCE_MONITORING_ENABLED=true
readonly PERFORMANCE_DATA_RETENTION_DAYS=30
readonly PERFORMANCE_REGRESSION_THRESHOLD=1.5  # 50% 성능 저하 시 경고

# === 캐시 설정 ===
readonly TEST_CACHE_DIR="${TEST_DIR_BASE}/.test-cache"
readonly TEST_RESULTS_DIR="${TEST_DIR_BASE}/.test-results"
readonly CACHE_CLEANUP_ON_EXIT=true

# 캐시 유형별 설정
readonly DISCOVERY_CACHE_TTL=900  # 15분
readonly MAPPING_CACHE_TTL=1800   # 30분
readonly RESULT_CACHE_TTL=86400   # 24시간

# === 백워드 호환성 설정 ===
readonly BACKWARD_COMPATIBILITY_ENABLED=true
readonly SHOW_DEPRECATION_WARNINGS=true
readonly LEGACY_COMMAND_SUPPORT=true

# 기존 명령어 매핑
readonly -A LEGACY_COMMAND_MAP=(
    ["test-quick"]="test quick"
    ["test-core"]="test unit"
    ["test-bats"]="test integration --tag bats"
    ["test-perf"]="test performance"
    ["smoke"]="test smoke"
    ["test-workflow"]="test e2e"
)

# === 출력 및 로깅 설정 ===
readonly VERBOSE_OUTPUT=${VERBOSE_OUTPUT:-false}
readonly DEBUG_MODE=${DEBUG_TESTS:-false}
readonly LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR

# 색상 출력 설정
readonly COLORIZED_OUTPUT=${COLORIZED_OUTPUT:-true}
readonly EMOJI_OUTPUT=${EMOJI_OUTPUT:-true}

# === 오류 처리 설정 ===
readonly CONTINUE_ON_FAILURE=true
readonly MAX_RETRY_COUNT=2
readonly RETRY_DELAY=1

# 오류 시 동작
readonly ERROR_ACTION_MISSING_FILE="warn"     # warn, error, skip
readonly ERROR_ACTION_TIMEOUT="fail"          # fail, skip, continue
readonly ERROR_ACTION_PERMISSION="error"      # error, skip

# === 플랫폼별 설정 ===
# 현재 플랫폼 감지 (기존 시스템 활용)
if [[ -f "${PROJECT_ROOT}/lib/platform-system.nix" ]]; then
    readonly CURRENT_PLATFORM=$(nix eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).platform' 2>/dev/null | tr -d '"' || echo "unknown")
    readonly CURRENT_ARCH=$(nix eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).arch' 2>/dev/null | tr -d '"' || echo "unknown")
else
    readonly CURRENT_PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
    readonly CURRENT_ARCH=$(uname -m)
fi

# 플랫폼별 최적화
case "${CURRENT_PLATFORM}" in
    "darwin")
        readonly PLATFORM_PARALLEL_WORKERS=8
        readonly PLATFORM_MEMORY_LIMIT="2G"
        ;;
    "nixos"|"linux")
        readonly PLATFORM_PARALLEL_WORKERS=4
        readonly PLATFORM_MEMORY_LIMIT="1G"
        ;;
    *)
        readonly PLATFORM_PARALLEL_WORKERS=2
        readonly PLATFORM_MEMORY_LIMIT="512M"
        ;;
esac

# === 유틸리티 함수 ===

# 설정 검증 함수
validate_test_interface_config() {
    local errors=0

    # 필수 디렉토리 검사
    if [[ ! -d "${TEST_CACHE_DIR}" ]]; then
        mkdir -p "${TEST_CACHE_DIR}" || {
            echo "ERROR: Cannot create cache directory: ${TEST_CACHE_DIR}" >&2
            ((errors++))
        }
    fi

    if [[ ! -d "${TEST_RESULTS_DIR}" ]]; then
        mkdir -p "${TEST_RESULTS_DIR}" || {
            echo "ERROR: Cannot create results directory: ${TEST_RESULTS_DIR}" >&2
            ((errors++))
        }
    fi

    # Git 저장소 확인 (변경사항 감지용)
    if [[ "${CHANGE_DETECTION_METHOD}" == "git" ]] && ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "WARN: Git repository not found, disabling change detection" >&2
        SMART_SELECTION_ENABLED=false
    fi

    # Nix 환경 확인
    if ! command -v nix >/dev/null 2>&1; then
        echo "WARN: Nix not found in PATH, some features may be limited" >&2
    fi

    return $errors
}

# 설정 정보 출력
print_test_interface_config() {
    echo "=== Test Interface Configuration ==="
    echo "Version: ${TEST_INTERFACE_VERSION}"
    echo "Platform: ${CURRENT_PLATFORM} (${CURRENT_ARCH})"
    echo "Workers: ${PLATFORM_PARALLEL_WORKERS}"
    echo "Smart Selection: ${SMART_SELECTION_ENABLED}"
    echo "Backward Compatibility: ${BACKWARD_COMPATIBILITY_ENABLED}"
    echo "Performance Monitoring: ${PERFORMANCE_MONITORING_ENABLED}"
    echo "Cache Directory: ${TEST_CACHE_DIR}"
    echo "Results Directory: ${TEST_RESULTS_DIR}"
    echo "===================================="
}

# 기존 test-config.sh 와의 호환성 보장
if [[ -f "${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")}/test-config.sh" ]]; then
    source "${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")}/test-config.sh"
fi
