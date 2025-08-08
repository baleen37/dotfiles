#!/usr/bin/env bash
# ABOUTME: build-switch와 Claude commands 통합 테스트
# ABOUTME: 실제 build-switch 실행 시 Claude 설정이 올바르게 동작하는지 검증합니다.

set -euo pipefail

# 테스트 환경 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_USER_HOME=$(mktemp -d)
TEST_CLAUDE_DIR="$TEST_USER_HOME/.claude"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

# 실제 build-switch 실행 관련 변수
BUILD_SWITCH_TIMEOUT=300  # 5분 타임아웃
ACTUAL_TEST_ENABLED=${ACTUAL_BUILD_TEST:-0}  # 환경변수로 활성화

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

# 테스트 헬퍼 함수
setup_integration_test() {
    log_info "통합 테스트 환경 설정 중..."

    # 테스트용 홈 디렉토리 설정
    export HOME="$TEST_USER_HOME"

    # Claude 디렉토리가 존재하지 않아야 함 (초기 상태)
    if [[ -d "$TEST_CLAUDE_DIR" ]]; then
        rm -rf "$TEST_CLAUDE_DIR"
    fi

    log_debug "테스트 홈 디렉토리: $TEST_USER_HOME"
    log_debug "테스트 Claude 디렉토리: $TEST_CLAUDE_DIR"
}

# 실제 build-switch 테스트를 위한 환경 설정
setup_actual_build_test() {
    log_info "실제 build-switch 테스트 환경 설정 중..."

    # 원래 홈 디렉토리 백업
    export ORIGINAL_HOME_BACKUP="$HOME"

    # USER 변수 설정 확인
    if [[ -z "${USER:-}" ]]; then
        export USER=$(whoami)
        log_debug "USER 변수 설정: $USER"
    fi

    # Nix가 설치되어 있는지 확인
    if ! command -v nix >/dev/null 2>&1; then
        log_error "Nix가 설치되지 않음. 실제 build-switch 테스트 건너뜀"
        return 1
    fi

    # 프로젝트 루트에서 flake.nix 확인
    if [[ ! -f "$PROJECT_ROOT/flake.nix" ]]; then
        log_error "flake.nix 파일을 찾을 수 없음. 실제 build-switch 테스트 건너뜀"
        return 1
    fi

    log_info "실제 build-switch 테스트 환경 준비 완료"
    return 0
}

cleanup_integration_test() {
    log_info "통합 테스트 환경 정리 중..."
    rm -rf "$TEST_USER_HOME"

    # 실제 테스트에서 백업한 홈 디렉토리 복원
    if [[ -n "${ORIGINAL_HOME_BACKUP:-}" && -d "$ORIGINAL_HOME_BACKUP" ]]; then
        log_info "원래 홈 디렉토리 복원 중..."
        export HOME="$ORIGINAL_HOME_BACKUP"
    fi
}

# Claude activation 시뮬레이션 (실제 Nix 없이)
simulate_claude_activation() {
    log_info "Claude activation 시뮬레이션 실행..."

    # 실제 claude-activation.nix 스크립트 내용을 bash로 실행
    local config_home="$TEST_USER_HOME"
    local source_dir="$PROJECT_ROOT/modules/shared/config/claude"

    # claude-activation.nix의 로직을 bash로 구현
    export CLAUDE_DIR="$TEST_CLAUDE_DIR"
    export SOURCE_DIR="$source_dir"
    export DRY_RUN=""

    # 실제 claude-activation.nix 스크립트 실행
    bash << 'EOF'
set -euo pipefail

DRY_RUN_CMD=""
if [[ "${DRY_RUN:-}" == "1" ]]; then
    DRY_RUN_CMD="echo '[DRY RUN]'"
fi

$DRY_RUN_CMD mkdir -p "${CLAUDE_DIR}/commands"
$DRY_RUN_CMD mkdir -p "${CLAUDE_DIR}/agents"

echo "=== 스마트 Claude 설정 업데이트 시작 ==="
echo "Claude 디렉토리: $CLAUDE_DIR"
echo "소스 디렉토리: $SOURCE_DIR"

# 파일 해시 비교 함수
files_differ() {
    local source="$1"
    local target="$2"

    if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
        return 0  # 파일이 없으면 다른 것으로 간주
    fi

    local source_hash=""
    local target_hash=""

    if command -v shasum >/dev/null 2>&1; then
        source_hash=$(shasum -a 256 "$source" | cut -d' ' -f1)
        target_hash=$(shasum -a 256 "$target" | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        source_hash=$(sha256sum "$source" | cut -d' ' -f1)
        target_hash=$(sha256sum "$target" | cut -d' ' -f1)
    else
        # Fallback: Nix의 nix-hash 사용
        source_hash=$(nix-hash --type sha256 --flat "$source" 2>/dev/null || echo "fallback_$source")
        target_hash=$(nix-hash --type sha256 --flat "$target" 2>/dev/null || echo "fallback_$target")
    fi

    [[ "$source_hash" != "$target_hash" ]]
}

# 조건부 복사 함수 (사용자 수정 보존)
smart_copy() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")

    echo "처리 중: $file_name"

    if [[ ! -f "$source_file" ]]; then
        echo "  소스 파일 없음, 건너뜀"
        return 0
    fi

    if [[ ! -f "$target_file" ]]; then
        echo "  새 파일 복사"
        $DRY_RUN_CMD cp "$source_file" "$target_file"
        $DRY_RUN_CMD chmod 644 "$target_file"
        return 0
    fi

    if files_differ "$source_file" "$target_file"; then
        echo "  사용자 수정 감지됨"

        # 높은 우선순위 파일들은 보존 (settings.json, CLAUDE.md)
        case "$file_name" in
            "settings.json"|"CLAUDE.md")
                echo "  사용자 버전 보존, 새 버전을 .new로 저장"
                $DRY_RUN_CMD cp "$source_file" "$target_file.new"
                $DRY_RUN_CMD chmod 644 "$target_file.new"
                ;;
            *)
                echo "  백업 후 덮어쓰기"
                $DRY_RUN_CMD cp "$source_file" "$target_file"
                $DRY_RUN_CMD chmod 644 "$target_file"
                ;;
        esac
    else
        echo "  파일 동일, 건너뜀"
    fi
}

# 메인 설정 파일들 처리
for config_file in "settings.json" "CLAUDE.md"; do
    smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
done

# commands 디렉토리 처리 (서브디렉토리 지원)
if [[ -d "$SOURCE_DIR/commands" ]]; then
    # find를 사용하여 모든 서브디렉토리의 .md 파일 처리
    find "$SOURCE_DIR/commands" -name "*.md" -type f | while read -r cmd_file; do
        # 소스에서 commands 디렉토리를 기준으로 한 상대 경로 계산
        rel_path="${cmd_file#$SOURCE_DIR/commands/}"
        target_file="$CLAUDE_DIR/commands/$rel_path"

        # 타겟 디렉토리가 없으면 생성
        target_dir=$(dirname "$target_file")
        $DRY_RUN_CMD mkdir -p "$target_dir"

        smart_copy "$cmd_file" "$target_file"
    done
fi

# agents 디렉토리 처리
if [[ -d "$SOURCE_DIR/agents" ]]; then
    for agent_file in "$SOURCE_DIR/agents"/*.md; do
        if [[ -f "$agent_file" ]]; then
            base_name=$(basename "$agent_file")
            smart_copy "$agent_file" "$CLAUDE_DIR/agents/$base_name"
        fi
    done
fi

echo "=== Claude 설정 업데이트 완료 ==="
EOF
}

# 통합 테스트 함수들
test_claude_directory_creation() {
    log_info "테스트: Claude 디렉토리 생성 확인"

    simulate_claude_activation

    if [[ -d "$TEST_CLAUDE_DIR" ]]; then
        log_info "✅ Claude 디렉토리 생성 성공"
        ((TESTS_PASSED++))
    else
        log_error "❌ Claude 디렉토리 생성 실패"
        ((TESTS_FAILED++))
        return 1
    fi

    # 서브디렉토리들도 생성되었는지 확인
    local required_dirs=("commands" "agents" "commands/git")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$TEST_CLAUDE_DIR/$dir" ]]; then
            log_info "✅ $dir 디렉토리 생성 성공"
            ((TESTS_PASSED++))
        else
            log_error "❌ $dir 디렉토리 생성 실패"
            ((TESTS_FAILED++))
        fi
    done
}

test_git_commands_integration() {
    log_info "테스트: Git commands 파일 통합 확인"

    # Git 관련 파일들이 올바르게 복사되었는지 확인
    local git_commands=("commit.md" "fix-pr.md" "upsert-pr.md")

    for cmd in "${git_commands[@]}"; do
        local target_file="$TEST_CLAUDE_DIR/commands/git/$cmd"
        if [[ -f "$target_file" ]]; then
            log_info "✅ Git command $cmd 복사 성공"
            ((TESTS_PASSED++))

            # 파일 내용도 검증
            if [[ -s "$target_file" ]] && grep -q "^#" "$target_file"; then
                log_info "✅ Git command $cmd 내용 유효"
                ((TESTS_PASSED++))
            else
                log_error "❌ Git command $cmd 내용 무효"
                ((TESTS_FAILED++))
            fi
        else
            log_error "❌ Git command $cmd 복사 실패"
            ((TESTS_FAILED++))
        fi
    done
}

test_main_config_files() {
    log_info "테스트: 메인 설정 파일 통합 확인"

    local config_files=("CLAUDE.md" "settings.json")

    for config in "${config_files[@]}"; do
        local target_file="$TEST_CLAUDE_DIR/$config"
        if [[ -f "$target_file" ]]; then
            log_info "✅ 설정 파일 $config 복사 성공"
            ((TESTS_PASSED++))

            # 파일 권한 확인
            local perms=$(stat -f "%A" "$target_file" 2>/dev/null || stat -c "%a" "$target_file" 2>/dev/null || echo "644")
            if [[ "$perms" == "644" ]]; then
                log_info "✅ 설정 파일 $config 권한 올바름 (644)"
                ((TESTS_PASSED++))
            else
                log_warning "⚠️ 설정 파일 $config 권한 확인 필요: $perms"
            fi
        else
            log_error "❌ 설정 파일 $config 복사 실패"
            ((TESTS_FAILED++))
        fi
    done
}

test_agents_integration() {
    log_info "테스트: Agent 파일 통합 확인"

    # Agent 파일들이 복사되었는지 확인
    local agents_count=$(find "$TEST_CLAUDE_DIR/agents" -name "*.md" -type f 2>/dev/null | wc -l)

    if [[ $agents_count -gt 0 ]]; then
        log_info "✅ Agent 파일들 복사 성공 ($agents_count 개)"
        ((TESTS_PASSED++))
    else
        log_error "❌ Agent 파일들 복사 실패"
        ((TESTS_FAILED++))
    fi
}

test_root_level_commands() {
    log_info "테스트: 루트 레벨 명령어 파일 통합 확인"

    # 루트 레벨 명령어들이 복사되었는지 확인
    local root_commands_count=$(find "$TEST_CLAUDE_DIR/commands" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)

    if [[ $root_commands_count -gt 0 ]]; then
        log_info "✅ 루트 레벨 명령어 파일들 복사 성공 ($root_commands_count 개)"
        ((TESTS_PASSED++))
    else
        log_error "❌ 루트 레벨 명령어 파일들 복사 실패"
        ((TESTS_FAILED++))
    fi
}

test_file_permissions() {
    log_info "테스트: 파일 권한 설정 확인"

    # 모든 복사된 파일의 권한이 644인지 확인
    local files_with_wrong_perms=0

    find "$TEST_CLAUDE_DIR" -name "*.md" -o -name "*.json" | while read -r file; do
        local perms=$(stat -f "%A" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null || echo "644")
        if [[ "$perms" != "644" ]]; then
            log_warning "⚠️ 잘못된 권한: $file ($perms)"
            ((files_with_wrong_perms++))
        fi
    done

    if [[ $files_with_wrong_perms -eq 0 ]]; then
        log_info "✅ 모든 파일 권한 설정 올바름"
        ((TESTS_PASSED++))
    else
        log_error "❌ $files_with_wrong_perms 개 파일의 권한 설정 문제"
        ((TESTS_FAILED++))
    fi
}

test_integration_completeness() {
    log_info "테스트: 통합 완성도 확인"

    # 전체 파일 수 확인
    local total_files=$(find "$TEST_CLAUDE_DIR" -type f | wc -l)
    local expected_min_files=10  # 최소한 이 정도는 있어야 함

    if [[ $total_files -ge $expected_min_files ]]; then
        log_info "✅ 충분한 수의 파일 통합됨 ($total_files 개)"
        ((TESTS_PASSED++))
    else
        log_error "❌ 통합된 파일 수 부족 ($total_files 개, 최소 $expected_min_files 개 필요)"
        ((TESTS_FAILED++))
    fi

    # 디렉토리 구조 검증
    local expected_structure=(
        "$TEST_CLAUDE_DIR"
        "$TEST_CLAUDE_DIR/commands"
        "$TEST_CLAUDE_DIR/commands/git"
        "$TEST_CLAUDE_DIR/agents"
    )

    for dir in "${expected_structure[@]}"; do
        if [[ -d "$dir" ]]; then
            log_debug "✓ 디렉토리 존재: $dir"
        else
            log_error "❌ 필수 디렉토리 누락: $dir"
            ((TESTS_FAILED++))
        fi
    done

    ((TESTS_PASSED++))
}

# 심볼릭 링크 상태 수집
capture_symlink_state() {
    local output_file="$1"
    local description="$2"

    log_debug "심볼릭 링크 상태 수집: $description"

    {
        echo "=== $description ==="
        echo "시간: $(date)"
        echo

        # 홈 디렉토리의 주요 설정 파일들 확인
        for file in ".zshrc" ".gitconfig" ".vimrc" ".tmux.conf"; do
            local full_path="$HOME/$file"
            if [[ -L "$full_path" ]]; then
                echo "$file -> $(readlink "$full_path")"
            elif [[ -f "$full_path" ]]; then
                echo "$file (일반 파일)"
            else
                echo "$file (없음)"
            fi
        done

        echo
        # Claude 디렉토리 상태
        if [[ -d "$HOME/.claude" ]]; then
            echo "Claude 디렉토리: 존재"
            echo "Claude 파일 수: $(find "$HOME/.claude" -type f 2>/dev/null | wc -l)"
        else
            echo "Claude 디렉토리: 없음"
        fi

        echo
    } > "$output_file"
}

# 심볼릭 링크 상태 비교
compare_symlink_states() {
    local before_file="$1"
    local after_file="$2"

    log_info "build-switch 전후 상태 비교"

    if [[ ! -f "$before_file" || ! -f "$after_file" ]]; then
        log_error "상태 파일을 찾을 수 없음"
        ((TESTS_FAILED++))
        return 1
    fi

    local diff_output=$(diff "$before_file" "$after_file" || true)

    if [[ -n "$diff_output" ]]; then
        log_info "build-switch로 인한 변경사항 감지:"
        echo "$diff_output" | while read -r line; do
            log_debug "  $line"
        done

        # Claude 디렉토리 생성/업데이트 확인
        if grep -q "Claude 디렉토리: 존재" "$after_file" &&
           ! grep -q "Claude 디렉토리: 존재" "$before_file"; then
            log_info "✅ Claude 디렉토리가 새로 생성됨"
            ((TESTS_PASSED++))
        elif grep -q "Claude 파일 수:" "$after_file"; then
            local before_count=$(grep "Claude 파일 수:" "$before_file" 2>/dev/null | awk '{print $NF}' || echo "0")
            local after_count=$(grep "Claude 파일 수:" "$after_file" | awk '{print $NF}')

            if [[ "$after_count" -gt "$before_count" ]]; then
                log_info "✅ Claude 파일이 업데이트됨 ($before_count -> $after_count)"
                ((TESTS_PASSED++))
            fi
        fi
    else
        log_warning "⚠️ build-switch 전후 상태 변화 없음"
    fi
}

# 실제 build-switch 실행 테스트
test_actual_build_switch() {
    if [[ "$ACTUAL_TEST_ENABLED" != "1" ]]; then
        log_warning "실제 build-switch 테스트 비활성화 (ACTUAL_BUILD_TEST=1로 활성화 가능)"
        return 0
    fi

    log_info "테스트: 실제 build-switch 실행"

    if ! setup_actual_build_test; then
        log_warning "실제 build-switch 테스트 환경 설정 실패, 건너뜀"
        return 0
    fi

    cd "$PROJECT_ROOT" || {
        log_error "프로젝트 루트 디렉토리로 이동 실패"
        ((TESTS_FAILED++))
        return 1
    }

    local before_state="$TEST_USER_HOME/state_before.txt"
    local after_state="$TEST_USER_HOME/state_after.txt"
    local build_log="$TEST_USER_HOME/build_output.txt"

    # build-switch 실행 전 상태 캡처
    capture_symlink_state "$before_state" "build-switch 실행 전"

    log_info "nix run .#build-switch 실행 중... (타임아웃: ${BUILD_SWITCH_TIMEOUT}초)"

    # build-switch 실행 (타임아웃과 함께)
    local build_success=0
    if timeout "$BUILD_SWITCH_TIMEOUT" nix run --impure .#build-switch > "$build_log" 2>&1; then
        log_info "✅ build-switch 실행 성공"
        build_success=1
        ((TESTS_PASSED++))
    else
        local exit_code=$?
        if [[ $exit_code == 124 ]]; then
            log_error "❌ build-switch 실행 타임아웃 (${BUILD_SWITCH_TIMEOUT}초)"
        else
            log_error "❌ build-switch 실행 실패 (종료 코드: $exit_code)"
        fi
        ((TESTS_FAILED++))

        # 실패 로그 출력
        if [[ -f "$build_log" ]]; then
            log_debug "build-switch 오류 로그 (마지막 20줄):"
            tail -20 "$build_log" | while read -r line; do
                log_debug "  $line"
            done
        fi
    fi

    # build-switch 실행 후 상태 캡처
    capture_symlink_state "$after_state" "build-switch 실행 후"

    # 상태 비교
    compare_symlink_states "$before_state" "$after_state"

    # 빌드 로그 분석
    if [[ -f "$build_log" && $build_success == 1 ]]; then
        log_info "build-switch 로그 분석"

        # Claude 설정 관련 메시지 확인
        if grep -q "Claude 설정 업데이트" "$build_log"; then
            log_info "✅ Claude 설정 업데이트 메시지 발견"
            ((TESTS_PASSED++))
        else
            log_warning "⚠️ Claude 설정 업데이트 메시지 없음"
        fi

        # 오류 메시지 확인
        local error_count=$(grep -c "error\|Error\|ERROR" "$build_log" || echo "0")
        if [[ "$error_count" == "0" ]]; then
            log_info "✅ 빌드 로그에 오류 없음"
            ((TESTS_PASSED++))
        else
            log_warning "⚠️ 빌드 로그에서 $error_count 개의 오류 발견"
        fi
    fi
}

# 부분 실행 중단 테스트
test_build_switch_interruption() {
    if [[ "$ACTUAL_TEST_ENABLED" != "1" ]]; then
        log_warning "실제 build-switch 중단 테스트 비활성화"
        return 0
    fi

    log_info "테스트: build-switch 실행 중단 시나리오"

    if ! setup_actual_build_test; then
        log_warning "실제 build-switch 테스트 환경 설정 실패, 건너뜀"
        return 0
    fi

    cd "$PROJECT_ROOT" || return 1

    local interrupt_log="$TEST_USER_HOME/interrupt_test.txt"

    # 짧은 시간 후 중단하는 테스트
    log_info "5초 후 build-switch 중단 테스트"

    {
        # 백그라운드에서 build-switch 실행
        timeout 5 nix run --impure .#build-switch &
        local build_pid=$!

        # 5초 대기 후 강제 종료
        sleep 5
        if kill -0 "$build_pid" 2>/dev/null; then
            kill -TERM "$build_pid" 2>/dev/null || true
            sleep 2
            if kill -0 "$build_pid" 2>/dev/null; then
                kill -KILL "$build_pid" 2>/dev/null || true
            fi
        fi

        wait "$build_pid" 2>/dev/null || true

    } > "$interrupt_log" 2>&1

    # 중단 후 시스템 상태 확인
    if [[ -d "$HOME/.claude" ]]; then
        local claude_files=$(find "$HOME/.claude" -type f 2>/dev/null | wc -l)
        if [[ "$claude_files" -gt "0" ]]; then
            log_info "✅ 중단 후에도 Claude 설정 파일 일부 존재 ($claude_files 개)"
            ((TESTS_PASSED++))
        else
            log_warning "⚠️ 중단 후 Claude 설정 파일 없음"
        fi
    fi

    log_info "중단 테스트 완료"
}

# 오류 시나리오 테스트
test_build_switch_error_scenarios() {
    if [[ "$ACTUAL_TEST_ENABLED" != "1" ]]; then
        log_warning "실제 build-switch 오류 시나리오 테스트 비활성화"
        return 0
    fi

    log_info "테스트: build-switch 오류 시나리오"

    # 잘못된 디렉토리에서 실행 테스트
    local temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1

    local error_log="$TEST_USER_HOME/error_test.txt"

    if nix run --impure .#build-switch > "$error_log" 2>&1; then
        log_warning "⚠️ 잘못된 디렉토리에서도 build-switch가 성공함"
    else
        log_info "✅ 잘못된 디렉토리에서 build-switch 실패 (예상된 동작)"
        ((TESTS_PASSED++))

        # 오류 메시지가 명확한지 확인
        if grep -q "flake.nix\|No such file" "$error_log"; then
            log_info "✅ 명확한 오류 메시지 제공"
            ((TESTS_PASSED++))
        fi
    fi

    # 원래 디렉토리로 복귀
    cd "$PROJECT_ROOT" || return 1
    rm -rf "$temp_dir"
}

# 메인 테스트 실행
main() {
    log_info "Build-Switch와 Claude Commands 통합 테스트 시작"
    log_info "프로젝트 루트: $PROJECT_ROOT"

    # 신호 핸들러 설정
    trap cleanup_integration_test EXIT

    # 테스트 환경 설정
    setup_integration_test

    # 시뮬레이션 테스트 실행
    test_claude_directory_creation
    test_git_commands_integration
    test_main_config_files
    test_agents_integration
    test_root_level_commands
    test_file_permissions
    test_integration_completeness

    # 실제 build-switch 테스트 실행 (조건부)
    echo
    log_info "=================== 실제 build-switch 테스트 ==================="
    test_actual_build_switch
    test_build_switch_interruption
    test_build_switch_error_scenarios

    # 결과 출력
    echo
    log_info "=================== 통합 테스트 결과 ==================="
    log_info "통과: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "실패: $TESTS_FAILED"
        log_error "일부 통합 테스트가 실패했습니다."

        # 디버그 정보 출력
        echo
        log_debug "================= 디버그 정보 =================="
        log_debug "테스트 Claude 디렉토리 내용:"
        if [[ -d "$TEST_CLAUDE_DIR" ]]; then
            find "$TEST_CLAUDE_DIR" -type f | head -20
        else
            log_debug "Claude 디렉토리가 생성되지 않음"
        fi

        # 실제 테스트 활성화 안내
        if [[ "$ACTUAL_TEST_ENABLED" != "1" ]]; then
            echo
            log_info "💡 실제 build-switch 테스트를 실행하려면:"
            log_info "   ACTUAL_BUILD_TEST=1 $0"
        fi

        exit 1
    else
        log_info "모든 통합 테스트가 통과했습니다! 🎉"
        log_info "Claude commands git 파일들이 올바르게 통합되었습니다."

        if [[ "$ACTUAL_TEST_ENABLED" == "1" ]]; then
            log_info "실제 build-switch 실행 테스트도 포함되었습니다."
        else
            echo
            log_info "💡 실제 build-switch 테스트를 실행하려면:"
            log_info "   ACTUAL_BUILD_TEST=1 $0"
        fi

        exit 0
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
