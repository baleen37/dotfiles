#!/usr/bin/env bash
# ABOUTME: 테스트 공통 라이브러리 - 확장된 공통 기능들 (리팩토링됨)
# ABOUTME: 색상, 로깅, 환경 설정, 신호 처리 등 모든 테스트에서 공유하는 핵심 기능

set -euo pipefail

# 라이브러리 버전
readonly COMMON_LIB_VERSION="2.0.0"

# === 색상 코드 (표준화) ===
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# 확장된 색상 코드
readonly LIGHT_RED='\033[1;31m'
readonly LIGHT_GREEN='\033[1;32m'
readonly LIGHT_BLUE='\033[1;34m'
readonly ORANGE='\033[0;33m'

# === 로깅 시스템 (확장됨) ===

# 로그 레벨 정의
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARNING=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4
readonly LOG_LEVEL_VERBOSE=5

# 현재 로그 레벨 (기본값: INFO)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# 로그 타임스탬프 설정
LOG_TIMESTAMP=${LOG_TIMESTAMP:-false}

# 타임스탬프 생성
get_timestamp() {
    if [[ "$LOG_TIMESTAMP" == "true" ]]; then
        date '+%H:%M:%S'
    fi
}

# 기본 로깅 함수들 (개선됨)
log_info() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
        local timestamp=$(get_timestamp)
        echo -e "${timestamp:+[$timestamp] }${GREEN}[INFO]${NC} $1" >&2
    fi
}

log_error() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_ERROR ]]; then
        local timestamp=$(get_timestamp)
        echo -e "${timestamp:+[$timestamp] }${RED}[ERROR]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_WARNING ]]; then
        local timestamp=$(get_timestamp)
        echo -e "${timestamp:+[$timestamp] }${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]] || [[ $LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then
        local timestamp=$(get_timestamp)
        echo -e "${timestamp:+[$timestamp] }${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

log_verbose() {
    if [[ "${VERBOSE:-false}" == "true" ]] || [[ $LOG_LEVEL -ge $LOG_LEVEL_VERBOSE ]]; then
        local timestamp=$(get_timestamp)
        echo -e "${timestamp:+[$timestamp] }${GRAY}[VERBOSE]${NC} $1" >&2
    fi
}

# 확장된 로깅 함수들
log_header() {
    echo -e "${PURPLE}${BOLD}[TEST SUITE]${NC} $1" >&2
}

log_subheader() {
    echo -e "${CYAN}[GROUP]${NC} $1" >&2
}

log_separator() {
    echo -e "${CYAN}============================================${NC}" >&2
}

log_thin_separator() {
    echo -e "${GRAY}--------------------------------------------${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅${NC} $1" >&2
}

log_fail() {
    echo -e "${RED}❌${NC} $1" >&2
}

log_skip() {
    echo -e "${YELLOW}⏭️ ${NC} $1" >&2
}

log_progress() {
    echo -e "${BLUE}⏳${NC} $1" >&2
}

log_step() {
    local step_num="$1"
    local total_steps="$2"
    local description="$3"
    echo -e "${WHITE}[${step_num}/${total_steps}]${NC} $description" >&2
}

# 트리 구조 로깅 (들여쓰기 지원)
log_tree() {
    local level="$1"
    local message="$2"
    local indent=""

    for ((i=0; i<level; i++)); do
        indent+="  "
    done

    echo -e "$indent${GRAY}├─${NC} $message" >&2
}

log_tree_last() {
    local level="$1"
    local message="$2"
    local indent=""

    for ((i=0; i<level; i++)); do
        indent+="  "
    done

    echo -e "$indent${GRAY}└─${NC} $message" >&2
}

# === 환경 및 시스템 유틸리티 (확장됨) ===

# 플랫폼 감지 (개선됨)
detect_platform() {
    case "$(uname -s)" in
        Darwin*)  echo "darwin" ;;
        Linux*)   echo "linux" ;;
        CYGWIN*)  echo "cygwin" ;;
        MINGW*)   echo "mingw" ;;
        *)        echo "unknown" ;;
    esac
}

# 아키텍처 감지
detect_architecture() {
    case "$(uname -m)" in
        x86_64)     echo "x86_64" ;;
        arm64)      echo "aarch64" ;;
        aarch64)    echo "aarch64" ;;
        i386)       echo "i386" ;;
        *)          echo "$(uname -m)" ;;
    esac
}

# 시스템 정보 출력
show_system_info() {
    log_info "시스템 정보:"
    log_tree 1 "플랫폼: $(detect_platform)"
    log_tree 1 "아키텍처: $(detect_architecture)"
    log_tree 1 "커널: $(uname -r)"
    log_tree_last 1 "셸: $0"
}

# CI 환경 감지 (확장됨)
is_ci_environment() {
    [[ "${CI:-false}" == "true" ]] || \
    [[ "${GITHUB_ACTIONS:-false}" == "true" ]] || \
    [[ "${GITLAB_CI:-false}" == "true" ]] || \
    [[ "${JENKINS_URL:-}" != "" ]] || \
    [[ "${BUILDKITE:-false}" == "true" ]]
}

# 필수 도구 확인 (개선됨)
check_required_tools() {
    local tools=("$@")
    local missing_tools=()
    local available_tools=()

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            available_tools+=("$tool")
        else
            missing_tools+=("$tool")
        fi
    done

    # 결과 출력
    if [[ ${#available_tools[@]} -gt 0 ]]; then
        log_debug "사용 가능한 도구들: ${available_tools[*]}"
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "필수 도구들이 누락되었습니다: ${missing_tools[*]}"

        # 설치 가이드 제공
        for tool in "${missing_tools[@]}"; do
            case "$tool" in
                "jq")
                    log_info "  jq 설치: apt-get install jq 또는 brew install jq"
                    ;;
                "nix")
                    log_info "  nix 설치: curl -L https://nixos.org/nix/install | sh"
                    ;;
            esac
        done

        return 1
    fi

    return 0
}

# 도구 버전 확인
check_tool_version() {
    local tool="$1"
    local min_version="${2:-}"

    if ! command -v "$tool" >/dev/null 2>&1; then
        return 1
    fi

    local version_output
    case "$tool" in
        "bash")
            version_output=$(bash --version | head -n1)
            ;;
        "nix")
            version_output=$(nix --version 2>/dev/null || echo "nix version unknown")
            ;;
        "jq")
            version_output=$(jq --version 2>/dev/null || echo "jq version unknown")
            ;;
        *)
            version_output=$($tool --version 2>/dev/null | head -n1 || echo "$tool version unknown")
            ;;
    esac

    log_debug "$tool 버전: $version_output"
    return 0
}

# === 테스트 환경 관리 (확장됨) ===

# 테스트 환경 정리 (개선됨)
cleanup_test_environment() {
    local cleanup_dirs=("${TEST_CLEANUP_DIRS[@]:-}")
    local cleanup_files=("${TEST_CLEANUP_FILES[@]:-}")

    # 디렉토리 정리
    for dir in "${cleanup_dirs[@]}"; do
        if [[ -n "$dir" && -d "$dir" ]]; then
            log_debug "테스트 디렉토리 정리: $dir"
            chmod -R u+w "$dir" 2>/dev/null || true
            rm -rf "$dir"
        fi
    done

    # 파일 정리
    for file in "${cleanup_files[@]}"; do
        if [[ -n "$file" && -f "$file" ]]; then
            log_debug "테스트 파일 정리: $file"
            rm -f "$file"
        fi
    done

    # 전역 변수 정리
    unset TEST_CLEANUP_DIRS TEST_CLEANUP_FILES

    # 기존 TEST_DIR 정리 (백워드 호환성)
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
        log_debug "레거시 테스트 환경 정리: $TEST_DIR"
        chmod -R u+w "$TEST_DIR" 2>/dev/null || true
        rm -rf "$TEST_DIR"
        unset TEST_DIR
    fi
}

# 정리할 항목 등록
register_cleanup_dir() {
    local dir="$1"
    TEST_CLEANUP_DIRS+=("$dir")
}

register_cleanup_file() {
    local file="$1"
    TEST_CLEANUP_FILES+=("$file")
}

# 신호 핸들러 설정 (개선됨)
setup_signal_handlers() {
    trap cleanup_test_environment EXIT
    trap 'echo -e "\n${YELLOW}인터럽트 감지됨. 정리 중...${NC}" >&2; cleanup_test_environment; exit 130' INT
    trap 'echo -e "\n${RED}종료 신호 감지됨. 정리 중...${NC}" >&2; cleanup_test_environment; exit 143' TERM
}

# === 성능 및 진행률 유틸리티 ===

# 진행률 표시
show_progress() {
    local current="$1"
    local total="$2"
    local description="${3:-진행 중}"
    local width=50

    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    printf "\r${BLUE}[%s]${NC} %d%% %s" "$bar" "$percentage" "$description" >&2

    if [[ $current -eq $total ]]; then
        echo >&2  # 완료시 새 줄
    fi
}

# 스피너 애니메이션
show_spinner() {
    local pid="$1"
    local message="${2:-처리 중...}"
    local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0

    echo -n "$message " >&2
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s ${spinner:$i:1}" "$message" >&2
        i=$(( (i+1) % ${#spinner} ))
        sleep 0.1
    done
    printf "\r%s ✓\n" "$message" >&2
}

# 실행 시간 측정
measure_time() {
    local start_time=$(date +%s%N)
    "$@"
    local exit_code=$?
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    log_debug "실행 시간: ${duration}ms"
    return $exit_code
}

# === Claude 관련 공통 함수들 (기존 + 확장) ===

# 개선된 설정 복사 함수
create_settings_copy() {
    local source_file="$1"
    local target_file="$2"
    local preserve_dynamic="${3:-true}"

    if [[ ! -f "$source_file" ]]; then
        log_debug "소스 파일 없음: $source_file"
        return 0
    fi

    # 백업 및 동적 상태 추출
    if [[ "$preserve_dynamic" == "true" && -f "$target_file" && ! -L "$target_file" ]]; then
        log_debug "기존 settings.json 백업 및 동적 상태 보존 준비..."
        cp "$target_file" "$target_file.backup"
    fi

    # 기존 심볼릭 링크 제거
    if [[ -L "$target_file" ]]; then
        log_debug "기존 심볼릭 링크 제거"
        rm -f "$target_file"
    fi

    # 새로운 설정을 복사
    cp "$source_file" "$target_file"
    chmod 644 "$target_file"
    log_debug "파일 복사 완료: $target_file (644 권한)"

    # 동적 상태 병합 (개선됨)
    if [[ "$preserve_dynamic" == "true" && -f "$target_file.backup" ]]; then
        merge_dynamic_state "$target_file" "$target_file.backup"
        rm -f "$target_file.backup"
    fi
}

# 동적 상태 병합 함수 (새로 추가)
merge_dynamic_state() {
    local target_file="$1"
    local backup_file="$2"
    local preserve_keys=("feedbackSurveyState" "sessionState" "userModifications" "runtimeState")

    if ! command -v jq >/dev/null 2>&1; then
        log_debug "jq 없음: 동적 상태 병합 건너뜀"
        return 0
    fi

    log_debug "동적 상태 병합 시작..."

    for key in "${preserve_keys[@]}"; do
        if jq -e ".$key" "$backup_file" >/dev/null 2>&1; then
            local value=$(jq -c ".$key" "$backup_file")
            jq --argjson value "$value" ".${key} = \$value" "$target_file" > "$target_file.tmp"
            mv "$target_file.tmp" "$target_file"
            log_debug "✓ $key 병합 완료"
        fi
    done

    log_debug "동적 상태 병합 완료"
}

# 표준화된 모의 환경 설정 (기존 함수 유지 - 백워드 호환성)
setup_mock_claude_environment() {
    local test_claude_dir="$1"
    local test_source_dir="$2"

    log_debug "모의 Claude 환경 생성: $test_claude_dir -> $test_source_dir"

    # 소스 디렉토리 생성
    mkdir -p "$test_source_dir/commands" "$test_source_dir/agents"

    # 기본 설정 파일들 생성
    cat > "$test_source_dir/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true,
  "debugMode": false
}
EOF

    cat > "$test_source_dir/CLAUDE.md" << 'EOF'
# Test Claude Configuration
This is a test configuration file.
EOF

    # 테스트용 명령어 및 에이전트 파일들
    echo "# Test command" > "$test_source_dir/commands/test-cmd.md"
    echo "# Test agent" > "$test_source_dir/agents/test-agent.md"

    # Claude 디렉토리 생성
    mkdir -p "$test_claude_dir"

    log_success "모의 Claude 환경 생성 완료"
}

# === 백워드 호환성 ===

# 테스트 결과 추적 변수들 (기존)
TESTS_PASSED=${TESTS_PASSED:-0}
TESTS_FAILED=${TESTS_FAILED:-0}

# 기존 assert_test 함수 (백워드 호환성)
assert_test() {
    local condition="$1"
    local test_name="$2"
    local expected="${3:-}"
    local actual="${4:-}"

    if eval "$condition"; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1)) || true
        return 0
    else
        if [[ -n "$expected" && -n "$actual" ]]; then
            log_fail "$test_name"
            log_error "  예상: $expected"
            log_error "  실제: $actual"
        else
            log_fail "$test_name"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1)) || true
        return 1
    fi
}

# === 초기화 ===

# 전역 배열 초기화
declare -ga TEST_CLEANUP_DIRS=()
declare -ga TEST_CLEANUP_FILES=()

log_debug "공통 라이브러리 로드 완료 (v$COMMON_LIB_VERSION)"
