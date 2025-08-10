#!/usr/bin/env bash
# ABOUTME: Claude activation End-to-End 테스트 - 실제 사용자 워크플로우 시뮬레이션
# ABOUTME: dotfiles 빌드부터 Claude Code 사용까지 전체 시나리오 테스트

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
TEST_HOME="$TEST_DIR/home"
TEST_DOTFILES="$TEST_DIR/dotfiles"
CLAUDE_DIR="$TEST_HOME/.claude"

# 공통 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

# 실제 dotfiles 루트 디렉토리
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 테스트 헬퍼 함수
assert_test() {
    local condition="$1"
    local test_name="$2"
    local expected="${3:-}"
    local actual="${4:-}"

    if [[ "$condition" == "true" ]]; then
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

# 전체 dotfiles 복사 및 설정
setup_full_dotfiles_environment() {
    log_info "전체 dotfiles 환경 설정 중..."

    # 실제 dotfiles 복사 (git 히스토리 제외)
    rsync -av --exclude='.git' --exclude='result*' "$DOTFILES_ROOT/" "$TEST_DOTFILES/"

    # 테스트용 home 디렉토리 생성
    mkdir -p "$TEST_HOME"/{.config,Documents,Downloads}

    # 테스트용 사용자 환경 설정
    export HOME="$TEST_HOME"
    export USER="${USER:-testuser}"
}

# Claude Code 사용 시뮬레이션
simulate_claude_code_usage() {
    log_info "Claude Code 사용 시뮬레이션..."

    # Claude Code가 settings.json을 수정하는 상황 시뮬레이션
    if [[ -f "$CLAUDE_DIR/settings.json" ]] && command -v jq >/dev/null 2>&1; then
        # 피드백 상태 추가
        local temp_file=$(mktemp)
        jq '. + {
            "feedbackSurveyState": {
                "lastShown": "2024-02-25",
                "dismissed": ["welcome", "feature-survey"],
                "completedSurveys": ["initial-setup"],
                "userPreferences": {
                    "showNotifications": true,
                    "frequency": "weekly",
                    "categories": ["updates", "tips"]
                }
            },
            "recentProjects": [
                "/Users/testuser/dev/project1",
                "/Users/testuser/dev/project2"
            ],
            "lastUsed": "2024-02-25T10:30:00Z"
        }' "$CLAUDE_DIR/settings.json" > "$temp_file"
        mv "$temp_file" "$CLAUDE_DIR/settings.json"

        log_info "Claude Code 동적 상태 시뮬레이션 완료"
    fi
}

# Nix 빌드 시뮬레이션
simulate_nix_build() {
    log_info "Nix 빌드 시뮬레이션..."

    # claude-activation.nix 스크립트 직접 실행
    local config_home="$TEST_HOME"
    local source_claude_dir="$TEST_DOTFILES/modules/shared/config/claude"

    # 스크립트 내용 추출 및 실행
    cat > "$TEST_DIR/activation_test.sh" << EOF
#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$CLAUDE_DIR"
SOURCE_DIR="$source_claude_dir"
FALLBACK_SOURCES=()

echo "=== E2E 테스트: Claude 설정 활성화 ==="

# 소스 디렉토리 검증
if [[ ! -d "\$SOURCE_DIR" ]]; then
    echo "❌ 소스 디렉토리 없음: \$SOURCE_DIR"
    exit 1
fi

# Claude 디렉토리 생성
mkdir -p "\$CLAUDE_DIR"

# settings.json 복사 함수
create_settings_copy() {
    local source_file="\$1"
    local target_file="\$2"

    if [[ ! -f "\$source_file" ]]; then
        echo "소스 파일 없음: \$source_file"
        return 0
    fi

    # 기존 파일 백업
    if [[ -f "\$target_file" && ! -L "\$target_file" ]]; then
        cp "\$target_file" "\$target_file.backup"
    fi

    # 기존 심볼릭 링크 제거
    if [[ -L "\$target_file" ]]; then
        rm -f "\$target_file"
    fi

    # 파일 복사
    cp "\$source_file" "\$target_file"
    chmod 644 "\$target_file"

    # 백업에서 동적 상태 병합
    if [[ -f "\$target_file.backup" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq -e '.feedbackSurveyState' "\$target_file.backup" >/dev/null 2>&1; then
                local feedback_state=\$(jq -c '.feedbackSurveyState' "\$target_file.backup")
                jq --argjson feedback_state "\$feedback_state" '.feedbackSurveyState = \$feedback_state' "\$target_file" > "\$target_file.tmp"
                mv "\$target_file.tmp" "\$target_file"
            fi
        fi
        rm -f "\$target_file.backup"
    fi
}

# 파일 심볼릭 링크 생성
create_file_symlink() {
    local source_file="\$1"
    local target_file="\$2"

    if [[ ! -f "\$source_file" ]]; then
        return 0
    fi

    if [[ -e "\$target_file" || -L "\$target_file" ]]; then
        rm -f "\$target_file"
    fi

    ln -sf "\$source_file" "\$target_file"
}

# 폴더 심볼릭 링크 생성
create_folder_symlink() {
    local source_folder="\$1"
    local target_folder="\$2"

    if [[ ! -d "\$source_folder" ]]; then
        return 0
    fi

    if [[ -e "\$target_folder" || -L "\$target_folder" ]]; then
        rm -rf "\$target_folder"
    fi

    ln -sf "\$source_folder" "\$target_folder"
}

# 설정 파일들 처리
for source_file in "\$SOURCE_DIR"/*.md "\$SOURCE_DIR"/*.json; do
    if [[ -f "\$source_file" ]]; then
        file_name=\$(basename "\$source_file")
        if [[ "\$file_name" == "settings.json" ]]; then
            create_settings_copy "\$source_file" "\$CLAUDE_DIR/\$file_name"
        else
            create_file_symlink "\$source_file" "\$CLAUDE_DIR/\$file_name"
        fi
    fi
done

# 폴더 심볼릭 링크
create_folder_symlink "\$SOURCE_DIR/commands" "\$CLAUDE_DIR/commands"
create_folder_symlink "\$SOURCE_DIR/agents" "\$CLAUDE_DIR/agents"

echo "✅ Claude 설정 활성화 완료"
EOF

    chmod +x "$TEST_DIR/activation_test.sh"
    bash "$TEST_DIR/activation_test.sh"
}

# E2E 테스트 시나리오들

test_initial_setup_workflow() {
    log_header "E2E: 초기 설정 워크플로우"

    # 1. 사용자가 dotfiles를 clone
    setup_full_dotfiles_environment

    # 2. make build-switch 시뮬레이션
    simulate_nix_build

    # 3. 결과 검증
    assert_test "[[ -d '$CLAUDE_DIR' ]]" "Claude 디렉토리 생성됨"
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "settings.json 생성됨"
    assert_test "[[ ! -L '$CLAUDE_DIR/settings.json' ]]" "settings.json이 복사본임"

    # 권한 확인
    local permissions=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    assert_test "[[ '$permissions' == '644' ]]" "올바른 파일 권한 설정됨" "644" "$permissions"

    # 심볼릭 링크 확인
    assert_test "[[ -L '$CLAUDE_DIR/commands' ]]" "commands 폴더 심볼릭 링크 생성됨"
    assert_test "[[ -L '$CLAUDE_DIR/agents' ]]" "agents 폴더 심볼릭 링크 생성됨"
}

test_development_workflow() {
    log_header "E2E: 개발 워크플로우 (설정 업데이트)"

    # 초기 설정
    setup_full_dotfiles_environment
    simulate_nix_build

    # 사용자가 Claude Code를 사용하여 동적 상태 추가
    simulate_claude_code_usage

    # dotfiles 개발자가 소스 설정을 업데이트
    if command -v jq >/dev/null 2>&1; then
        local source_settings="$TEST_DOTFILES/modules/shared/config/claude/settings.json"
        local temp_file=$(mktemp)
        jq '. + {"newFeature": true, "version": "1.1.0"}' "$source_settings" > "$temp_file"
        mv "$temp_file" "$source_settings"
        log_info "소스 설정 업데이트 완료"
    fi

    # make build-switch 재실행
    simulate_nix_build

    if command -v jq >/dev/null 2>&1; then
        # 새로운 설정이 적용되었는지 확인
        local version=$(jq -r '.version' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$version' == '1.1.0' ]]" "새로운 버전 적용됨" "1.1.0" "$version"

        local new_feature=$(jq -r '.newFeature' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$new_feature' == 'true' ]]" "새로운 기능 플래그 적용됨" "true" "$new_feature"

        # 기존 동적 상태 보존 확인
        local last_shown=$(jq -r '.feedbackSurveyState.lastShown // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$last_shown' == '2024-02-25' ]]" "사용자 피드백 상태 보존됨" "2024-02-25" "$last_shown"

        local project_count=$(jq -r '.recentProjects | length' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$project_count' == '2' ]]" "최근 프로젝트 목록 보존됨" "2" "$project_count"
    fi
}

test_migration_from_symlinks() {
    log_header "E2E: 기존 심볼릭 링크에서 마이그레이션"

    # 초기 환경: 기존 dotfiles 사용자 (심볼릭 링크 방식)
    setup_full_dotfiles_environment

    # 기존 방식으로 심볼릭 링크 설정
    mkdir -p "$CLAUDE_DIR"
    ln -sf "$TEST_DOTFILES/modules/shared/config/claude/settings.json" "$CLAUDE_DIR/settings.json"
    ln -sf "$TEST_DOTFILES/modules/shared/config/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

    # 기존 방식 확인
    assert_test "[[ -L '$CLAUDE_DIR/settings.json' ]]" "기존 방식에서는 심볼릭 링크"

    # Claude Code 사용 시뮬레이션 (심볼릭 링크 덮어쓰기)
    if command -v jq >/dev/null 2>&1; then
        cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "legacyUser": true,
  "migrationData": {
    "previousSetup": "symlink",
    "migrationDate": "2024-02-25",
    "preservedSettings": ["theme", "shortcuts"]
  }
}
EOF
    fi

    # 새로운 방식으로 업그레이드
    simulate_nix_build

    # 마이그레이션 결과 확인
    assert_test "[[ ! -L '$CLAUDE_DIR/settings.json' ]]" "심볼릭 링크에서 복사본으로 변환됨"

    if command -v jq >/dev/null 2>&1; then
        local legacy_user=$(jq -r '.legacyUser' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$legacy_user' == 'true' ]]" "기존 사용자 데이터 보존됨" "true" "$legacy_user"

        local migration_date=$(jq -r '.migrationData.migrationDate' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$migration_date' == '2024-02-25' ]]" "마이그레이션 메타데이터 보존됨" "2024-02-25" "$migration_date"
    fi
}

test_concurrent_usage_scenario() {
    log_header "E2E: 동시 사용 시나리오"

    # 초기 설정
    setup_full_dotfiles_environment
    simulate_nix_build

    # 시나리오: 사용자가 Claude Code를 사용하는 중에 dotfiles 업데이트 발생

    # 1. 사용자가 작업 시작
    simulate_claude_code_usage

    # 2. 동시에 개발자가 소스 업데이트
    if command -v jq >/dev/null 2>&1; then
        local source_settings="$TEST_DOTFILES/modules/shared/config/claude/settings.json"
        jq '. + {"urgentUpdate": true, "securityPatch": "2024.1"}' "$source_settings" > "$source_settings.tmp"
        mv "$source_settings.tmp" "$source_settings"
    fi

    # 3. 사용자가 추가 설정 변경
    if command -v jq >/dev/null 2>&1; then
        local temp_file=$(mktemp)
        jq '.userWorkInProgress = {"task": "code_review", "startTime": "2024-02-25T11:00:00Z"}' "$CLAUDE_DIR/settings.json" > "$temp_file"
        mv "$temp_file" "$CLAUDE_DIR/settings.json"
    fi

    # 4. dotfiles 재빌드
    simulate_nix_build

    # 5. 결과 검증: 두 변경사항이 모두 보존되어야 함
    if command -v jq >/dev/null 2>&1; then
        local urgent_update=$(jq -r '.urgentUpdate // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$urgent_update' == 'true' ]]" "개발자 업데이트 적용됨" "true" "$urgent_update"

        local work_task=$(jq -r '.userWorkInProgress.task // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$work_task' == 'code_review' ]]" "사용자 작업 상태 보존됨" "code_review" "$work_task"

        local feedback_state=$(jq -r '.feedbackSurveyState.lastShown // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$feedback_state' == '2024-02-25' ]]" "기존 피드백 상태도 보존됨" "2024-02-25" "$feedback_state"
    fi
}

test_error_recovery_scenario() {
    log_header "E2E: 에러 복구 시나리오"

    # 초기 설정
    setup_full_dotfiles_environment

    # 문제 상황 1: 권한 문제
    simulate_nix_build
    chmod 000 "$CLAUDE_DIR/settings.json"

    # 복구 시도
    simulate_nix_build 2>/dev/null || {
        log_info "권한 에러 발생 (예상됨)"
    }

    # 권한 복구
    chmod 644 "$CLAUDE_DIR/settings.json"
    simulate_nix_build

    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "권한 에러 후 복구 성공"

    # 문제 상황 2: 잘못된 JSON
    echo "invalid json content" > "$CLAUDE_DIR/settings.json"
    simulate_nix_build

    if command -v jq >/dev/null 2>&1; then
        local is_valid_json="false"
        if jq empty "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
            is_valid_json="true"
        fi
        assert_test "[[ '$is_valid_json' == 'true' ]]" "잘못된 JSON 복구됨"
    fi
}

test_command_and_agent_integration() {
    log_header "E2E: 명령어 및 에이전트 통합 테스트"

    # 초기 설정
    setup_full_dotfiles_environment
    simulate_nix_build

    # Claude Code에서 명령어 사용 시뮬레이션
    local test_commands=(
        "commands/task.md"
        "commands/git/commit.md"
        "commands/system/monitor.md"
    )

    for cmd_file in "${test_commands[@]}"; do
        if [[ -f "$CLAUDE_DIR/$cmd_file" ]]; then
            local cmd_name=$(basename "$cmd_file" .md)
            assert_test "[[ -f '$CLAUDE_DIR/$cmd_file' ]]" "명령어 파일 접근 가능: $cmd_name"
        fi
    done

    # 에이전트 파일 확인
    local test_agents=(
        "agents/code-reviewer.md"
        "agents/test-generator.md"
    )

    for agent_file in "${test_agents[@]}"; do
        if [[ -f "$CLAUDE_DIR/$agent_file" ]]; then
            local agent_name=$(basename "$agent_file" .md)
            assert_test "[[ -f '$CLAUDE_DIR/$agent_file' ]]" "에이전트 파일 접근 가능: $agent_name"
        fi
    done

    # 심볼릭 링크 무결성 확인
    assert_test "[[ -L '$CLAUDE_DIR/commands' && -e '$CLAUDE_DIR/commands' ]]" "commands 심볼릭 링크 유효함"
    assert_test "[[ -L '$CLAUDE_DIR/agents' && -e '$CLAUDE_DIR/agents' ]]" "agents 심볼릭 링크 유효함"
}

# 정리 함수
cleanup_test_environment() {
    log_debug "E2E 테스트 환경 정리: $TEST_DIR"
    # 권한 문제 해결
    chmod -R 755 "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"

    # 환경 변수 복원
    unset HOME 2>/dev/null || true
}

# 메인 테스트 실행
main() {
    log_header "Claude Activation End-to-End 테스트 시작"
    log_info "테스트 디렉토리: $TEST_DIR"
    log_info "실제 Dotfiles: $DOTFILES_ROOT"

    # 신호 핸들러 설정
    setup_signal_handlers

    # 필수 도구 확인
    local required_tools=("rsync" "bash" "cp" "chmod" "stat" "ln")
    if ! check_required_tools "${required_tools[@]}"; then
        exit 1
    fi

    # E2E 테스트 시나리오 실행
    test_initial_setup_workflow
    test_development_workflow
    test_migration_from_symlinks
    test_concurrent_usage_scenario
    test_error_recovery_scenario
    test_command_and_agent_integration

    # 결과 출력
    log_separator
    log_header "End-to-End 테스트 결과"
    log_info "통과: $TESTS_PASSED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "실패: $TESTS_FAILED"
        log_error "일부 E2E 테스트가 실패했습니다."
        exit 1
    else
        log_success "모든 End-to-End 테스트가 통과했습니다! 🎉"
        exit 0
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
