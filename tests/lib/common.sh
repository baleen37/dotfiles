#!/usr/bin/env bash
# ABOUTME: 테스트 공통 라이브러리 - 기본적인 공통 함수들만 제공
# ABOUTME: 코드 중복 제거를 위한 최소한의 공통 기능

set -euo pipefail

# 색상 코드
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 로깅 함수들
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

log_header() {
    echo -e "${PURPLE}[TEST SUITE]${NC} $1" >&2
}

log_separator() {
    echo -e "${CYAN}============================================${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅${NC} $1" >&2
}

log_fail() {
    echo -e "${RED}❌${NC} $1" >&2
}

# 필수 도구 확인
check_required_tools() {
    local tools=("$@")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "필수 도구들이 누락되었습니다: ${missing_tools[*]}"
        return 1
    fi

    return 0
}

# 테스트 환경 정리
cleanup_test_environment() {
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
        log_debug "테스트 환경 정리: $TEST_DIR"
        rm -rf "$TEST_DIR"
        unset TEST_DIR
    fi
}

# 신호 핸들러 설정
setup_signal_handlers() {
    trap cleanup_test_environment EXIT INT TERM
}

# Claude activation 관련 공통 함수
create_settings_copy() {
    local source_file="$1"
    local target_file="$2"

    if [[ ! -f "$source_file" ]]; then
        log_debug "소스 파일 없음: $source_file"
        return 0
    fi

    # 기존 파일 백업 (동적 상태 보존용)
    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
        log_debug "기존 settings.json 백업 중..."
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

    # 백업에서 동적 상태 병합
    if [[ -f "$target_file.backup" ]]; then
        log_debug "동적 상태 병합 시도 중..."

        # jq가 있으면 JSON 병합
        if command -v jq >/dev/null 2>&1; then
            if jq -e '.feedbackSurveyState' "$target_file.backup" >/dev/null 2>&1; then
                local feedback_state=$(jq -c '.feedbackSurveyState' "$target_file.backup")
                jq --argjson feedback_state "$feedback_state" '.feedbackSurveyState = $feedback_state' "$target_file" > "$target_file.tmp"
                mv "$target_file.tmp" "$target_file"
                log_debug "✓ feedbackSurveyState 병합 완료"
            fi
        else
            log_debug "⚠ jq 없음: 동적 상태 병합 건너뜀"
        fi

        rm -f "$target_file.backup"
    fi
}

# 테스트 결과 추적 변수들
TESTS_PASSED=${TESTS_PASSED:-0}
TESTS_FAILED=${TESTS_FAILED:-0}

# 테스트 헬퍼 함수
assert_test() {
    local condition="$1"
    local test_name="$2"
    local expected="${3:-}"
    local actual="${4:-}"

    if eval "$condition"; then
        log_success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        if [[ -n "$expected" && -n "$actual" ]]; then
            log_fail "$test_name"
            log_error "  예상: $expected"
            log_error "  실제: $actual"
        else
            log_fail "$test_name"
        fi
        ((TESTS_FAILED++))
        return 1
    fi
}

# 표준화된 모의 환경 설정
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

log_debug "테스트 공통 라이브러리 로드 완료"
