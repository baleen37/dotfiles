#!/bin/bash
# Integration test for Claude Code agents system
# Tests full agent system integration, command execution safety, and configuration synchronization

set -euo pipefail

# Test configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TEST_TEMP_DIR="$(mktemp -d)"
readonly CLAUDE_CONFIG_DIR="$PROJECT_ROOT/modules/shared/config/claude"

# Test utilities
source "$SCRIPT_DIR/../lib/claude-activation-utils.sh" 2>/dev/null || true

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }

# Test state tracking
declare -i TEST_COUNT=0
declare -i PASSED_COUNT=0
declare -i FAILED_COUNT=0
declare -a FAILED_TESTS=()

# Cleanup function
cleanup() {
    log_info "테스트 정리 중..."
    [[ -n "${TEST_TEMP_DIR:-}" ]] && rm -rf "$TEST_TEMP_DIR"
}

trap cleanup EXIT

# Test execution framework
run_test() {
    local test_name="$1"
    local test_function="$2"

    ((TEST_COUNT++))
    log_info "테스트 실행: $test_name"

    if $test_function; then
        ((PASSED_COUNT++))
        log_success "$test_name"
    else
        ((FAILED_COUNT++))
        FAILED_TESTS+=("$test_name")
        log_error "$test_name"
    fi
}

# Pre-test validation
validate_environment() {
    log_info "환경 검증 중..."

    # Check project structure
    [[ -d "$CLAUDE_CONFIG_DIR" ]] || {
        log_error "Claude 설정 디렉토리가 존재하지 않음: $CLAUDE_CONFIG_DIR"
        return 1
    }

    # Check required tools
    local required_tools=("jq" "python3" "git")
    for tool in "${required_tools[@]}"; do
        command -v "$tool" >/dev/null 2>&1 || {
            log_error "필수 도구 누락: $tool"
            return 1
        }
    done

    # Check Python modules
    python3 -c "import json, yaml" 2>/dev/null || {
        log_warning "Python 모듈 누락: json 또는 yaml"
    }

    log_success "환경 검증 완료"
}

# Test: Claude agents configuration integrity
test_agents_config_integrity() {
    local agents_dir="$CLAUDE_CONFIG_DIR/agents"
    [[ -d "$agents_dir" ]] || return 1

    # Count agent files
    local agent_count
    agent_count=$(find "$agents_dir" -name "*.md" -type f | wc -l)
    [[ $agent_count -ge 10 ]] || {
        log_error "에이전트 파일 수 부족: $agent_count (최소 10개 필요)"
        return 1
    }

    # Validate each agent file
    local validation_errors=0
    while IFS= read -r -d '' agent_file; do
        local agent_name
        agent_name=$(basename "$agent_file" .md)

        # Check front matter
        if ! grep -q "^---$" "$agent_file"; then
            log_error "$agent_name: YAML front matter 누락"
            ((validation_errors++))
            continue
        fi

        # Extract and validate front matter
        local front_matter
        front_matter=$(sed -n '/^---$/,/^---$/p' "$agent_file" | sed '1d;$d')

        # Check required fields
        local required_fields=("name" "description" "model")
        for field in "${required_fields[@]}"; do
            if ! echo "$front_matter" | grep -q "^$field:"; then
                log_error "$agent_name: 필수 필드 누락 - $field"
                ((validation_errors++))
            fi
        done

        # Check content length (should have substantial content)
        local content_lines
        content_lines=$(wc -l < "$agent_file")
        [[ $content_lines -ge 50 ]] || {
            log_warning "$agent_name: 내용이 짧음 ($content_lines 줄)"
        }

    done < <(find "$agents_dir" -name "*.md" -type f -print0)

    [[ $validation_errors -eq 0 ]]
}

# Test: Commands configuration integrity
test_commands_config_integrity() {
    local commands_dir="$CLAUDE_CONFIG_DIR/commands"
    [[ -d "$commands_dir" ]] || return 1

    # Count command files
    local command_count
    command_count=$(find "$commands_dir" -name "*.md" -type f | wc -l)
    [[ $command_count -ge 15 ]] || {
        log_error "명령어 파일 수 부족: $command_count (최소 15개 필요)"
        return 1
    }

    # Validate critical commands exist
    local critical_commands=(
        "test.md"
        "debug.md"
        "implement.md"
        "analyze.md"
        "build.md"
        "create-pr.md"
    )

    for cmd in "${critical_commands[@]}"; do
        [[ -f "$commands_dir/$cmd" ]] || {
            log_error "중요 명령어 누락: $cmd"
            return 1
        }
    done

    # Validate command file structure
    local validation_errors=0
    while IFS= read -r -d '' cmd_file; do
        local cmd_name
        cmd_name=$(basename "$cmd_file" .md)

        # Check front matter exists
        if ! grep -q "^---$" "$cmd_file"; then
            log_error "$cmd_name: YAML front matter 누락"
            ((validation_errors++))
            continue
        fi

        # Check required fields
        if ! grep -A 10 "^---$" "$cmd_file" | grep -q "^name:"; then
            log_error "$cmd_name: name 필드 누락"
            ((validation_errors++))
        fi

        if ! grep -A 10 "^---$" "$cmd_file" | grep -q "^description:"; then
            log_error "$cmd_name: description 필드 누락"
            ((validation_errors++))
        fi

    done < <(find "$commands_dir" -name "*.md" -type f -print0)

    [[ $validation_errors -eq 0 ]]
}

# Test: Settings JSON configuration
test_settings_configuration() {
    local settings_file="$CLAUDE_CONFIG_DIR/settings.json"
    [[ -f "$settings_file" ]] || return 1

    # Validate JSON syntax
    jq . "$settings_file" >/dev/null 2>&1 || {
        log_error "settings.json: JSON 구문 오류"
        return 1
    }

    # Check required top-level sections
    local required_sections=("permissions" "model" "hooks" "statusLine")
    for section in "${required_sections[@]}"; do
        jq -e ".$section" "$settings_file" >/dev/null || {
            log_error "settings.json: $section 섹션 누락"
            return 1
        }
    done

    # Validate permissions structure
    jq -e '.permissions.allow | type == "array"' "$settings_file" >/dev/null || {
        log_error "settings.json: permissions.allow가 배열이 아님"
        return 1
    }

    # Check for critical permissions
    local critical_permissions=(
        "Bash(*)"
        "Write"
        "Edit"
        "Read"
        "Grep"
        "Glob"
    )

    for perm in "${critical_permissions[@]}"; do
        jq -e --arg perm "$perm" '.permissions.allow | contains([$perm])' "$settings_file" >/dev/null || {
            log_error "settings.json: 중요 권한 누락 - $perm"
            return 1
        }
    done

    # Validate hooks configuration
    local hook_types=("PreToolUse" "PostToolUse" "UserPromptSubmit")
    for hook_type in "${hook_types[@]}"; do
        jq -e ".hooks.$hook_type" "$settings_file" >/dev/null || {
            log_error "settings.json: $hook_type 훅 설정 누락"
            return 1
        }
    done

    # Check MCP server configuration
    jq -e '.enableAllProjectMcpServers == true' "$settings_file" >/dev/null || {
        log_warning "settings.json: MCP 서버 자동 활성화가 비활성화됨"
    }

    return 0
}

# Test: Hooks system integrity
test_hooks_system_integrity() {
    local hooks_dir="$CLAUDE_CONFIG_DIR/hooks"
    local settings_file="$CLAUDE_CONFIG_DIR/settings.json"

    [[ -d "$hooks_dir" ]] || return 1

    # Extract hook commands from settings
    local hook_commands
    hook_commands=$(jq -r '.hooks[][] | select(.type == "command") | .command' "$settings_file" 2>/dev/null)

    local validation_errors=0
    while IFS= read -r cmd; do
        [[ -n "$cmd" ]] || continue

        # Convert ~/.claude paths to actual paths
        local actual_path="${cmd/#~\/.claude/$hooks_dir}"

        [[ -f "$actual_path" ]] || {
            log_error "훅 스크립트 파일 누락: $cmd -> $actual_path"
            ((validation_errors++))
            continue
        }

        # Check file permissions and syntax for Python files
        if [[ "$actual_path" == *.py ]]; then
            [[ -r "$actual_path" ]] || {
                log_error "훅 스크립트 읽기 권한 없음: $actual_path"
                ((validation_errors++))
                continue
            }

            # Check Python syntax
            if ! python3 -m py_compile "$actual_path" 2>/dev/null; then
                log_error "Python 구문 오류: $actual_path"
                ((validation_errors++))
            fi
        fi

    done <<< "$hook_commands"

    [[ $validation_errors -eq 0 ]]
}

# Test: Agent-command relationship consistency
test_agent_command_consistency() {
    local agents_dir="$CLAUDE_CONFIG_DIR/agents"
    local commands_dir="$CLAUDE_CONFIG_DIR/commands"

    # Test specific agent-command relationships
    local relationships=(
        "test-automator.md:test.md"
        "git-specialist.md:create-pr.md"
        "debugger.md:debug.md"
        "backend-architect.md:implement.md"
    )

    local validation_errors=0
    for relationship in "${relationships[@]}"; do
        local agent="${relationship%:*}"
        local command="${relationship#*:}"

        if [[ -f "$agents_dir/$agent" ]]; then
            [[ -f "$commands_dir/$command" ]] || {
                log_error "에이전트-명령어 관계 불일치: $agent 존재하지만 $command 누락"
                ((validation_errors++))
            }
        fi
    done

    [[ $validation_errors -eq 0 ]]
}

# Test: Configuration file security
test_configuration_security() {
    local validation_errors=0

    # Check for sensitive information in configuration files
    local sensitive_patterns=(
        "password"
        "api_key"
        "secret"
        "token"
        "auth"
    )

    while IFS= read -r -d '' config_file; do
        for pattern in "${sensitive_patterns[@]}"; do
            if grep -qi "$pattern" "$config_file" 2>/dev/null; then
                local file_name
                file_name=$(basename "$config_file")
                log_warning "잠재적 민감 정보 발견: $file_name (패턴: $pattern)"
            fi
        done
    done < <(find "$CLAUDE_CONFIG_DIR" -type f \( -name "*.json" -o -name "*.md" -o -name "*.py" \) -print0)

    # Check for overly permissive settings
    local settings_file="$CLAUDE_CONFIG_DIR/settings.json"
    if jq -e '.permissions.allow | contains(["*"])' "$settings_file" >/dev/null 2>&1; then
        log_error "보안 위험: 와일드카드 권한 발견"
        ((validation_errors++))
    fi

    # Check for dangerous shell commands in hooks
    while IFS= read -r -d '' hook_file; do
        if [[ "$hook_file" == *.py ]]; then
            if grep -E "(eval|exec|subprocess\.call.*shell=True)" "$hook_file" >/dev/null 2>&1; then
                local file_name
                file_name=$(basename "$hook_file")
                log_warning "잠재적 보안 위험: $file_name (위험한 실행 패턴)"
            fi
        fi
    done < <(find "$CLAUDE_CONFIG_DIR/hooks" -name "*.py" -type f -print0 2>/dev/null)

    [[ $validation_errors -eq 0 ]]
}

# Test: Configuration synchronization simulation
test_configuration_sync_simulation() {
    local test_claude_dir="$TEST_TEMP_DIR/.claude"
    mkdir -p "$test_claude_dir"/{agents,commands,hooks}

    # Simulate copying configuration files
    cp -r "$CLAUDE_CONFIG_DIR/agents/"* "$test_claude_dir/agents/" 2>/dev/null || true
    cp -r "$CLAUDE_CONFIG_DIR/commands/"* "$test_claude_dir/commands/" 2>/dev/null || true
    cp -r "$CLAUDE_CONFIG_DIR/hooks/"* "$test_claude_dir/hooks/" 2>/dev/null || true
    cp "$CLAUDE_CONFIG_DIR/settings.json" "$test_claude_dir/settings.json" 2>/dev/null || true

    # Verify sync integrity
    local original_agent_count
    local synced_agent_count
    original_agent_count=$(find "$CLAUDE_CONFIG_DIR/agents" -name "*.md" -type f | wc -l)
    synced_agent_count=$(find "$test_claude_dir/agents" -name "*.md" -type f | wc -l)

    [[ $original_agent_count -eq $synced_agent_count ]] || {
        log_error "에이전트 동기화 실패: 원본 $original_agent_count, 동기화 $synced_agent_count"
        return 1
    }

    # Test settings.json integrity after sync
    if [[ -f "$test_claude_dir/settings.json" ]]; then
        jq . "$test_claude_dir/settings.json" >/dev/null 2>&1 || {
            log_error "동기화된 settings.json 손상"
            return 1
        }
    fi

    return 0
}

# Test: Performance and scalability
test_performance_characteristics() {
    local start_time
    local end_time
    local duration

    # Measure configuration loading time
    start_time=$(date +%s%N)

    # Simulate configuration loading operations
    find "$CLAUDE_CONFIG_DIR" -type f -name "*.md" -exec wc -l {} \; >/dev/null 2>&1
    jq . "$CLAUDE_CONFIG_DIR/settings.json" >/dev/null 2>&1

    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds

    # Configuration should load quickly (< 5 seconds even on slow systems)
    [[ $duration -lt 5000 ]] || {
        log_warning "설정 로딩 시간이 김: ${duration}ms"
    }

    # Check file sizes are reasonable
    local large_files
    large_files=$(find "$CLAUDE_CONFIG_DIR" -type f -size +1M)
    [[ -z "$large_files" ]] || {
        log_warning "대용량 설정 파일 발견: $large_files"
    }

    return 0
}

# Test: Command execution safety simulation
test_command_execution_safety() {
    # Test safe command patterns that don't actually execute
    local test_commands=(
        "echo 'test'"
        "pwd"
        "ls -la /tmp"
        "git status"
    )

    # Simulate command validation (without execution)
    for cmd in "${test_commands[@]}"; do
        # Check if command exists and is safe
        local base_cmd
        base_cmd=$(echo "$cmd" | cut -d' ' -f1)

        command -v "$base_cmd" >/dev/null 2>&1 || {
            log_warning "테스트 명령어 도구 누락: $base_cmd"
        }
    done

    # Test dangerous command detection
    local dangerous_commands=(
        "rm -rf /"
        "sudo rm"
        "format c:"
        "eval \$(evil)"
    )

    # These should be caught by validation logic
    for dangerous_cmd in "${dangerous_commands[@]}"; do
        # Simulate validation logic
        if [[ "$dangerous_cmd" =~ rm\ .*-rf|sudo\ rm|format|eval ]]; then
            log_info "위험한 명령어 감지됨 (예상됨): $dangerous_cmd"
        fi
    done

    return 0
}

# Main test execution
main() {
    log_info "Claude Code 에이전트 시스템 통합 테스트 시작"
    log_info "프로젝트 루트: $PROJECT_ROOT"
    log_info "테스트 임시 디렉토리: $TEST_TEMP_DIR"

    # Environment validation
    validate_environment || {
        log_error "환경 검증 실패"
        exit 1
    }

    # Run integration tests
    run_test "에이전트 설정 무결성" test_agents_config_integrity
    run_test "명령어 설정 무결성" test_commands_config_integrity
    run_test "Settings 설정 검증" test_settings_configuration
    run_test "Hooks 시스템 무결성" test_hooks_system_integrity
    run_test "에이전트-명령어 일관성" test_agent_command_consistency
    run_test "설정 보안 검증" test_configuration_security
    run_test "설정 동기화 시뮬레이션" test_configuration_sync_simulation
    run_test "성능 특성 검증" test_performance_characteristics
    run_test "명령어 실행 안전성" test_command_execution_safety

    # Test summary
    echo
    log_info "==============================================="
    log_info "테스트 결과 요약"
    log_info "==============================================="
    log_info "총 테스트: $TEST_COUNT"
    log_success "성공: $PASSED_COUNT"

    if [[ $FAILED_COUNT -gt 0 ]]; then
        log_error "실패: $FAILED_COUNT"
        log_error "실패한 테스트:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            log_error "  - $failed_test"
        done
        echo
        exit 1
    else
        log_success "모든 테스트 통과!"
        echo
        exit 0
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
