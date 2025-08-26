#!/usr/bin/env bash
# ABOUTME: 테스트 설정 파일 (확장됨) - 모든 테스트에서 사용하는 설정 중앙 집중화
# ABOUTME: 하드코딩된 값들, 경로, 타임아웃, 임계값 등을 통합 관리

# === 기본 테스트 설정 ===
readonly TEST_CONFIG_VERSION="2.0.0"

# 타임아웃 설정 (초)
readonly TEST_TIMEOUT_SHORT=30
readonly TEST_TIMEOUT_MEDIUM=60
readonly TEST_TIMEOUT_LONG=300
readonly TEST_TIMEOUT_VERY_LONG=600
readonly TEST_TIMEOUT_DEFAULT=$TEST_TIMEOUT_MEDIUM

# 테스트 디렉토리 설정
readonly TEST_DIR_PREFIX="dotfiles_test"
readonly TEST_DIR_BASE="/tmp"
readonly TEST_CLEANUP_ON_SUCCESS=true
readonly TEST_CLEANUP_ON_FAILURE=false

# 재시도 설정
readonly TEST_RETRY_COUNT=3
readonly TEST_RETRY_DELAY=1

# === 성능 임계값 ===

# 빌드 시간 임계값 (밀리초)
readonly PERF_PLATFORM_EVAL_MAX=100
readonly PERF_USER_RESOLUTION_MAX=200
readonly PERF_NIX_EVAL_MAX=1000
readonly PERF_FILE_COPY_MAX=50
readonly PERF_SYMLINK_MAX=10

# 파일 크기 임계값 (바이트)
readonly SIZE_CONFIG_FILE_MAX=10240    # 10KB
readonly SIZE_LOG_FILE_MAX=1048576     # 1MB
readonly SIZE_TEMP_FILE_MAX=524288     # 512KB

# === Claude 관련 설정 ===

# Claude 설정 파일 목록
readonly EXPECTED_CONFIG_FILES=(
    "CLAUDE.md"
    "settings.json"
    "MCP.md"
    "SUBAGENT.md"
    "FLAGS.md"
    "ORCHESTRATOR.md"
)

# Claude 명령어 카테고리 및 파일들
readonly EXPECTED_GIT_COMMANDS=(
    "commit.md"
    "fix-pr.md"
    "upsert-pr.md"
)

readonly EXPECTED_WORKFLOW_COMMANDS=(
    "task.md"
    "analyze.md"
    "implement.md"
    "debug.md"
)

readonly EXPECTED_SYSTEM_COMMANDS=(
    "build.md"
    "test.md"
    "deploy.md"
)

# Claude 에이전트 목록
readonly EXPECTED_AGENTS=(
    "backend-engineer.md"
    "frontend-specialist.md"
    "system-architect.md"
    "test-automator.md"
    "python-ultimate-expert.md"
    "typescript-pro.md"
    "golang-pro.md"
    "debugger.md"
    "code-reviewer.md"
    "devops-engineer.md"
)

# Claude 동적 상태 키들
readonly DYNAMIC_STATE_KEYS=(
    "feedbackSurveyState"
    "sessionState"
    "userModifications"
    "runtimeState"
    "workspaceHistory"
    "customCommands"
)

# === Nix 관련 설정 ===

# 지원되는 시스템들
readonly SUPPORTED_SYSTEMS=(
    "aarch64-darwin"
    "x86_64-darwin"
    "x86_64-linux"
    "aarch64-linux"
)

# Nix 평가 최대 시간 (초)
readonly NIX_EVAL_TIMEOUT=30
readonly NIX_BUILD_TIMEOUT=300

# 필수 Nix 속성들
readonly REQUIRED_NIX_ATTRS=(
    "platform"
    "arch"
    "system"
    "isDarwin"
    "isLinux"
)

# === 플랫폼별 설정 ===

# 플랫폼 감지
detect_test_platform() {
    case "$OSTYPE" in
        darwin*) echo "darwin" ;;
        linux*) echo "linux" ;;
        cygwin*) echo "cygwin" ;;
        msys*) echo "msys" ;;
        *) echo "unknown" ;;
    esac
}

readonly PLATFORM="$(detect_test_platform)"

# 플랫폼별 도구들
case "$PLATFORM" in
    "darwin")
        readonly STAT_CMD="stat -f"
        readonly STAT_PERM_FLAG="%OLp"
        readonly STAT_SIZE_FLAG="%z"
        readonly PACKAGE_MANAGER="brew"
        readonly DEFAULT_SHELL="/bin/zsh"
        readonly HOME_PREFIX="/Users"
        ;;
    "linux")
        readonly STAT_CMD="stat -c"
        readonly STAT_PERM_FLAG="%a"
        readonly STAT_SIZE_FLAG="%s"
        readonly PACKAGE_MANAGER="nix"
        readonly DEFAULT_SHELL="/run/current-system/sw/bin/zsh"
        readonly HOME_PREFIX="/home"
        ;;
    *)
        readonly STAT_CMD="stat"
        readonly STAT_PERM_FLAG=""
        readonly STAT_SIZE_FLAG=""
        readonly PACKAGE_MANAGER="unknown"
        readonly DEFAULT_SHELL="/bin/bash"
        readonly HOME_PREFIX="/home"
        ;;
esac

# === 도구 및 유틸리티 설정 ===

# 해시 검증 도구 우선순위
readonly HASH_TOOLS=("shasum" "sha256sum" "md5sum")

# 필수 도구들 (카테고리별)
readonly CORE_TOOLS=("bash" "find" "grep" "sed" "awk")
readonly NIX_TOOLS=("nix" "nix-instantiate" "nix-build")
readonly DEVELOPMENT_TOOLS=("git" "jq" "curl")
readonly OPTIONAL_TOOLS=("parallel" "timeout" "pv")

# === CI/CD 설정 ===

# CI 환경 감지 설정
readonly CI_INDICATORS=(
    "CI"
    "GITHUB_ACTIONS"
    "GITLAB_CI"
    "JENKINS_URL"
    "BUILDKITE"
    "TRAVIS"
    "CIRCLECI"
)

# CI 환경 체크
is_ci_environment() {
    for indicator in "${CI_INDICATORS[@]}"; do
        if [[ "${!indicator:-false}" == "true" ]] || [[ -n "${!indicator:-}" ]]; then
            return 0
        fi
    done
    return 1
}

# CI별 설정
if is_ci_environment; then
    readonly TEST_OUTPUT_VERBOSE=false
    readonly TEST_CLEANUP_AGGRESSIVE=true
    readonly TEST_PARALLEL_DEFAULT=true
    readonly TEST_FAIL_FAST=true
else
    readonly TEST_OUTPUT_VERBOSE=true
    readonly TEST_CLEANUP_AGGRESSIVE=false
    readonly TEST_PARALLEL_DEFAULT=false
    readonly TEST_FAIL_FAST=false
fi

# === 테스트 데이터 설정 ===

# 모의 데이터
readonly MOCK_USER_NAMES=("testuser" "alice" "bob" "developer")
readonly MOCK_VERSIONS=("1.0.0" "2.1.0" "3.0.0-beta")
readonly MOCK_THEMES=("dark" "light" "auto" "high-contrast")

# 테스트 파일 내용 템플릿들
readonly MOCK_SETTINGS_JSON='{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true,
  "debugMode": false,
  "workspaceSettings": {
    "defaultDirectory": "~/dev",
    "preferredShell": "zsh"
  }
}'

readonly MOCK_CLAUDE_MD='# Mock Claude Configuration
This is a test configuration file for testing purposes.

## Test Features
- Configuration validation
- State preservation
- Error handling

Created for testing at: $(date)
'

# === 경로 및 패턴 설정 ===

# 중요한 디렉토리 패턴
readonly IMPORTANT_DIRS=(
    "lib"
    "modules"
    "tests"
    "scripts"
    "apps"
)

# 무시할 파일 패턴
readonly IGNORE_PATTERNS=(
    "*.tmp"
    "*.bak"
    "*.log"
    ".DS_Store"
    "node_modules"
    "__pycache__"
)

# 클린업 대상 패턴
readonly CLEANUP_PATTERNS=(
    "${TEST_DIR_PREFIX}_*"
    "test_env_*"
    "mock_*"
    "*.test.tmp"
)

# === 검증 설정 ===

# 파일 권한 검증
readonly EXPECTED_FILE_PERMS="644"
readonly EXPECTED_DIR_PERMS="755"
readonly EXPECTED_SCRIPT_PERMS="755"

# JSON 검증 키
readonly REQUIRED_JSON_KEYS=(
    "version"
    "theme"
    "autoSave"
)

# 심볼릭 링크 검증 설정
readonly SYMLINK_MAX_DEPTH=3
readonly SYMLINK_TIMEOUT=5

# === 로깅 및 출력 설정 ===

# 로그 레벨 매핑
readonly LOG_LEVELS=(
    "ERROR"
    "WARNING"
    "INFO"
    "DEBUG"
    "VERBOSE"
)

# 출력 형식
readonly OUTPUT_FORMATS=(
    "standard"
    "json"
    "junit"
    "tap"
)

# === 네트워킹 및 외부 리소스 ===

# 타임아웃 설정
readonly NETWORK_TIMEOUT=10
readonly DOWNLOAD_TIMEOUT=30

# 재시도 설정
readonly NETWORK_RETRY_COUNT=3
readonly NETWORK_RETRY_DELAY=2

# === 개발 및 디버깅 설정 ===

# 디버그 모드 설정
readonly DEBUG_CATEGORIES=(
    "nix"
    "claude"
    "performance"
    "network"
    "filesystem"
)

# 프로파일링 설정
readonly PROFILE_ENABLED=${PROFILE_ENABLED:-false}
readonly PROFILE_OUTPUT_DIR="${TEST_DIR_BASE}/profiles"

# === 유틸리티 함수들 ===

# 설정 값 가져오기
get_config_value() {
    local key="$1"
    local default="${2:-}"
    echo "${!key:-$default}"
}

# 플랫폼별 값 가져오기
get_platform_value() {
    local base_key="$1"
    local platform_key="${base_key}_${PLATFORM^^}"
    get_config_value "$platform_key" "$(get_config_value "$base_key")"
}

# 타임아웃 값 결정
get_timeout_for_test() {
    local test_type="$1"
    
    case "$test_type" in
        "unit") echo "$TEST_TIMEOUT_SHORT" ;;
        "integration") echo "$TEST_TIMEOUT_MEDIUM" ;;
        "e2e") echo "$TEST_TIMEOUT_LONG" ;;
        "performance") echo "$TEST_TIMEOUT_VERY_LONG" ;;
        *) echo "$TEST_TIMEOUT_DEFAULT" ;;
    esac
}

# 병렬 작업 수 결정
get_parallel_jobs() {
    local cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")
    local max_jobs=$((cpu_count > 8 ? 8 : cpu_count))
    echo "${PARALLEL_JOBS:-$max_jobs}"
}

# === 설정 검증 ===

# 설정 유효성 검증
validate_test_config() {
    local errors=0
    
    # 필수 디렉토리 존재 확인
    if [[ ! -d "$TEST_DIR_BASE" ]]; then
        echo "ERROR: TEST_DIR_BASE directory not found: $TEST_DIR_BASE" >&2
        ((errors++))
    fi
    
    # 플랫폼 검증
    if [[ "$PLATFORM" == "unknown" ]]; then
        echo "WARNING: Unknown platform detected: $OSTYPE" >&2
    fi
    
    # 버전 호환성 검증
    if [[ -n "${BASH_VERSION:-}" ]]; then
        local bash_major=${BASH_VERSION%%.*}
        if [[ $bash_major -lt 4 ]]; then
            echo "WARNING: Old Bash version detected: $BASH_VERSION" >&2
        fi
    fi
    
    return $errors
}

# === 초기화 ===

# 설정 초기화
init_test_config() {
    # 프로파일 디렉토리 생성
    if [[ "$PROFILE_ENABLED" == "true" ]]; then
        mkdir -p "$PROFILE_OUTPUT_DIR"
    fi
    
    # 환경 변수 설정
    export TEST_CONFIG_LOADED=true
    export TEST_CONFIG_VERSION
    export PLATFORM
    
    # 설정 검증
    validate_test_config
}

# 자동 초기화 (소싱될 때 실행)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_test_config
fi

# 설정 로드 완료 메시지
if [[ "${DEBUG:-false}" == "true" ]]; then
    echo "[DEBUG] 테스트 설정 로드 완료 (v$TEST_CONFIG_VERSION)" >&2
    echo "[DEBUG] 플랫폼: $PLATFORM" >&2
    echo "[DEBUG] CI 환경: $(is_ci_environment && echo "예" || echo "아니오")" >&2
fi