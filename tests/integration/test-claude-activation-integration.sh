#!/usr/bin/env bash
# ABOUTME: Claude activation 통합 테스트 - 실제 Nix 활성화 스크립트와의 통합 테스트
# ABOUTME: 전체 claude-activation.nix 로직을 실제 환경에서 검증

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
SOURCE_BASE="$TEST_DIR/dotfiles_mock/modules/shared/config/claude"
TARGET_BASE="$TEST_DIR/home"
CLAUDE_DIR="$TARGET_BASE/.claude"

# 공통 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

# 실제 dotfiles 루트 디렉토리 찾기
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

# 모의 dotfiles 환경 설정
setup_mock_dotfiles() {
    log_info "모의 dotfiles 환경 설정 중..."

    # 디렉토리 구조 생성
    mkdir -p "$SOURCE_BASE"/{commands,agents}
    mkdir -p "$SOURCE_BASE/commands"/{git,workflow,system}
    mkdir -p "$TARGET_BASE"

    # 실제 설정 파일들을 참조하여 테스트 파일 생성
    if [[ -f "$DOTFILES_ROOT/modules/shared/config/claude/settings.json" ]]; then
        cp "$DOTFILES_ROOT/modules/shared/config/claude/settings.json" "$SOURCE_BASE/settings.json"
    else
        # 기본 settings.json 생성
        cat > "$SOURCE_BASE/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true,
  "debugMode": false,
  "workspaceSettings": {
    "defaultDirectory": "~/dev",
    "preferredShell": "zsh"
  }
}
EOF
    fi

    # CLAUDE.md 파일
    cat > "$SOURCE_BASE/CLAUDE.md" << 'EOF'
# Claude Integration Test Configuration

This is a test configuration for Claude activation integration tests.

## Test Features
- Settings copy functionality
- Dynamic state preservation
- Symlink to copy conversion
EOF

    # 명령어 파일들
    cat > "$SOURCE_BASE/commands/task.md" << 'EOF'
# Task Command
Root level task command for testing
EOF

    cat > "$SOURCE_BASE/commands/git/commit.md" << 'EOF'
# Git Commit Command
Git workflow command in subdirectory
EOF

    cat > "$SOURCE_BASE/commands/workflow/deploy.md" << 'EOF'
# Deployment Workflow
Workflow automation command
EOF

    cat > "$SOURCE_BASE/commands/system/monitor.md" << 'EOF'
# System Monitor Command
System monitoring utilities
EOF

    # 에이전트 파일들
    cat > "$SOURCE_BASE/agents/code-reviewer.md" << 'EOF'
# Code Reviewer Agent
Automated code review agent
EOF

    cat > "$SOURCE_BASE/agents/test-generator.md" << 'EOF'
# Test Generator Agent
Automated test generation agent
EOF
}

# 실제 claude-activation.nix 스크립트 실행
run_activation_script() {
    local config_home_dir="$1"
    local source_dir="$2"

    # Nix 표현식 생성 및 실행
    local nix_expr=$(cat << EOF
let
  # 모의 config 객체 생성
  config = {
    home.homeDirectory = "$config_home_dir";
  };

  lib = (import <nixpkgs> {}).lib;

  # claude-activation.nix에서 스크립트 생성
  activationScript = import "$DOTFILES_ROOT/modules/shared/lib/claude-activation.nix" {
    inherit config lib;
    self = null;
    platform = "darwin";
  };
in activationScript
EOF
)

    # 임시 Nix 파일 생성
    local temp_nix="$TEST_DIR/activation.nix"
    echo "$nix_expr" > "$temp_nix"

    # 환경 변수 설정하여 소스 디렉토리 오버라이드
    local activation_script_content
    activation_script_content=$(nix-instantiate --eval --strict --expr "$nix_expr" | sed 's/^"//;s/"$//' | sed 's/\\n/\n/g' | sed 's/\\"/"/g')

    # 소스 디렉토리 치환
    activation_script_content="${activation_script_content//\$\{sourceDir\}/$source_dir}"
    activation_script_content="${activation_script_content//\$SOURCE_DIR/$source_dir}"

    # 스크립트 실행
    echo "$activation_script_content" | bash
}

# 통합 테스트 함수들

test_full_activation_clean_environment() {
    log_header "깨끗한 환경에서 전체 활성화 테스트"

    # 모의 dotfiles 설정
    setup_mock_dotfiles

    # 활성화 스크립트 실행
    run_activation_script "$TARGET_BASE" "$SOURCE_BASE" 2>/dev/null || {
        log_error "활성화 스크립트 실행 실패"
        ((TESTS_FAILED++))
        return 1
    }

    # 결과 검증
    assert_test "[[ -d '$CLAUDE_DIR' ]]" "Claude 디렉토리 생성됨"
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "settings.json 파일 생성됨"
    assert_test "[[ -f '$CLAUDE_DIR/CLAUDE.md' ]]" "CLAUDE.md 파일 생성됨"

    # settings.json이 복사본인지 확인 (심볼릭 링크가 아님)
    assert_test "[[ ! -L '$CLAUDE_DIR/settings.json' ]]" "settings.json이 복사본임"

    # 권한 확인
    local permissions=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    assert_test "[[ '$permissions' == '644' ]]" "settings.json 권한이 644임" "644" "$permissions"

    # 폴더 심볼릭 링크 확인
    assert_test "[[ -L '$CLAUDE_DIR/commands' ]]" "commands 폴더가 심볼릭 링크임"
    assert_test "[[ -L '$CLAUDE_DIR/agents' ]]" "agents 폴더가 심볼릭 링크임"

    # 서브디렉토리 접근 확인
    assert_test "[[ -f '$CLAUDE_DIR/commands/git/commit.md' ]]" "서브디렉토리 명령어 파일 접근 가능"
}

test_symlink_conversion_with_state_preservation() {
    log_header "기존 심볼릭 링크 변환 및 상태 보존 테스트"

    # 모의 dotfiles 설정
    setup_mock_dotfiles

    # Claude 디렉토리 수동 생성 및 심볼릭 링크 설정
    mkdir -p "$CLAUDE_DIR"
    ln -sf "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"

    # 심볼릭 링크 확인
    assert_test "[[ -L '$CLAUDE_DIR/settings.json' ]]" "초기에 심볼릭 링크로 설정됨"

    # 사용자가 동적 상태 추가 (Claude Code 사용 시뮬레이션)
    if command -v jq >/dev/null 2>&1; then
        # 새로운 동적 상태로 파일 덮어쓰기
        cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true,
  "debugMode": false,
  "workspaceSettings": {
    "defaultDirectory": "~/dev",
    "preferredShell": "zsh"
  },
  "feedbackSurveyState": {
    "lastShown": "2024-02-20",
    "dismissed": ["welcome", "feedback-v1"],
    "userPreferences": {
      "showNotifications": false,
      "frequency": "monthly"
    }
  },
  "userModifications": {
    "customTheme": "monokai",
    "shortcuts": ["ctrl+s", "ctrl+z"]
  }
}
EOF
    fi

    # 활성화 스크립트 재실행
    run_activation_script "$TARGET_BASE" "$SOURCE_BASE" 2>/dev/null || {
        log_error "활성화 스크립트 재실행 실패"
        ((TESTS_FAILED++))
        return 1
    }

    # 결과 검증
    assert_test "[[ ! -L '$CLAUDE_DIR/settings.json' ]]" "심볼릭 링크가 복사본으로 변환됨"

    if command -v jq >/dev/null 2>&1; then
        # 새로운 기본 설정이 적용되었는지 확인
        local theme=$(jq -r '.theme' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$theme' == 'dark' ]]" "새로운 기본 설정 적용됨" "dark" "$theme"

        # 동적 상태가 보존되었는지 확인
        local last_shown=$(jq -r '.feedbackSurveyState.lastShown // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$last_shown' == '2024-02-20' ]]" "feedbackSurveyState 보존됨" "2024-02-20" "$last_shown"

        local custom_theme=$(jq -r '.userModifications.customTheme // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$custom_theme' == 'monokai' ]]" "사용자 수정사항 보존됨" "monokai" "$custom_theme"

        local shortcuts_count=$(jq -r '.userModifications.shortcuts | length' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$shortcuts_count' == '2' ]]" "배열 형태 사용자 설정 보존됨" "2" "$shortcuts_count"
    fi
}

test_fallback_source_resolution() {
    log_header "Fallback 소스 디렉토리 해상도 테스트"

    # 잘못된 기본 소스 디렉토리 설정
    local wrong_source="$TEST_DIR/wrong_path/modules/shared/config/claude"
    local correct_fallback="$SOURCE_BASE"

    # 모의 dotfiles 설정 (올바른 fallback 위치에)
    setup_mock_dotfiles

    # claude-activation.nix에서 fallback 로직 시뮬레이션
    local activation_script=$(cat << 'SCRIPT'
set -euo pipefail

CLAUDE_DIR="$1"
SOURCE_DIR="$2"
FALLBACK_SOURCES=("$3")

echo "=== Claude 설정 폴더 심볼릭 링크 업데이트 시작 ==="

# 소스 디렉토리 유효성 검사 및 fallback
ACTUAL_SOURCE_DIR=""

if [[ -d "$SOURCE_DIR" ]]; then
    ACTUAL_SOURCE_DIR="$SOURCE_DIR"
    echo "✓ 기본 소스 디렉토리 확인됨: $SOURCE_DIR"
else
    echo "⚠ 기본 소스 디렉토리 없음: $SOURCE_DIR"
    for fallback_dir in "${FALLBACK_SOURCES[@]}"; do
        if [[ -d "$fallback_dir" ]]; then
            ACTUAL_SOURCE_DIR="$fallback_dir"
            echo "✓ Fallback 소스 발견: $fallback_dir"
            break
        fi
    done

    if [[ -z "$ACTUAL_SOURCE_DIR" ]]; then
        echo "❌ 오류: Claude 설정 소스 디렉토리를 찾을 수 없습니다!"
        exit 1
    fi
fi

# 간단한 파일 복사 테스트
mkdir -p "$CLAUDE_DIR"
if [[ -f "$ACTUAL_SOURCE_DIR/settings.json" ]]; then
    cp "$ACTUAL_SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    chmod 644 "$CLAUDE_DIR/settings.json"
    echo "SUCCESS: Fallback을 통해 설정 파일 복사 완료"
else
    echo "ERROR: 설정 파일을 찾을 수 없음"
    exit 1
fi
SCRIPT
)

    # 스크립트 실행
    echo "$activation_script" | bash -s "$CLAUDE_DIR" "$wrong_source" "$correct_fallback"
    local exit_code=$?

    # 결과 검증
    assert_test "[[ $exit_code -eq 0 ]]" "Fallback 소스 해상도 성공" "0" "$exit_code"
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "Fallback을 통한 파일 복사 성공"
}

test_concurrent_modification_handling() {
    log_header "동시 수정 처리 테스트"

    # 모의 dotfiles 설정
    setup_mock_dotfiles

    # 활성화 스크립트 첫 실행
    run_activation_script "$TARGET_BASE" "$SOURCE_BASE" 2>/dev/null

    # 사용자가 settings.json 수정 (Claude Code 시뮬레이션)
    if command -v jq >/dev/null 2>&1; then
        jq '.userAddedField = "user_modification"' "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp"
        mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
    fi

    # 동시에 소스 파일도 업데이트
    if command -v jq >/dev/null 2>&1; then
        jq '.version = "1.1.0" | .newFeature = true' "$SOURCE_BASE/settings.json" > "$SOURCE_BASE/settings.json.tmp"
        mv "$SOURCE_BASE/settings.json.tmp" "$SOURCE_BASE/settings.json"
    fi

    # 활성화 스크립트 재실행
    run_activation_script "$TARGET_BASE" "$SOURCE_BASE" 2>/dev/null

    if command -v jq >/dev/null 2>&1; then
        # 새로운 소스 설정이 적용되었는지 확인
        local version=$(jq -r '.version' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$version' == '1.1.0' ]]" "새로운 소스 버전 적용됨" "1.1.0" "$version"

        local new_feature=$(jq -r '.newFeature' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$new_feature' == 'true' ]]" "새로운 소스 기능 적용됨" "true" "$new_feature"

        # 사용자 수정사항이 보존되었는지 확인
        local user_field=$(jq -r '.userAddedField // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$user_field' == 'user_modification' ]]" "사용자 수정사항 보존됨" "user_modification" "$user_field"
    fi
}

test_broken_symlink_cleanup() {
    log_header "끊어진 심볼릭 링크 정리 테스트"

    # 모의 dotfiles 설정
    setup_mock_dotfiles

    # Claude 디렉토리 생성
    mkdir -p "$CLAUDE_DIR"

    # 끊어진 심볼릭 링크들 생성
    ln -sf "$SOURCE_BASE/nonexistent.json" "$CLAUDE_DIR/broken1.json"
    ln -sf "/nonexistent/path/file.md" "$CLAUDE_DIR/broken2.md"

    # 유효한 심볼릭 링크도 생성
    ln -sf "$SOURCE_BASE/CLAUDE.md" "$CLAUDE_DIR/valid_link.md"

    # 활성화 스크립트 실행
    run_activation_script "$TARGET_BASE" "$SOURCE_BASE" 2>/dev/null

    # 끊어진 링크가 정리되었는지 확인
    assert_test "[[ ! -L '$CLAUDE_DIR/broken1.json' ]]" "끊어진 심볼릭 링크 1이 정리됨"
    assert_test "[[ ! -L '$CLAUDE_DIR/broken2.md' ]]" "끊어진 심볼릭 링크 2가 정리됨"

    # 유효한 링크는 보존되었는지 확인
    assert_test "[[ -L '$CLAUDE_DIR/valid_link.md' ]]" "유효한 심볼릭 링크는 보존됨"
}

test_error_recovery() {
    log_header "에러 복구 테스트"

    # 모의 dotfiles 설정
    setup_mock_dotfiles

    # 권한 문제 시뮬레이션
    mkdir -p "$CLAUDE_DIR"
    touch "$CLAUDE_DIR/settings.json"
    chmod 000 "$CLAUDE_DIR/settings.json"

    # 활성화 스크립트 실행 (에러 발생해도 계속)
    run_activation_script "$TARGET_BASE" "$SOURCE_BASE" 2>/dev/null || true

    # 권한 복구 후 다시 시도
    chmod 644 "$CLAUDE_DIR/settings.json"
    run_activation_script "$TARGET_BASE" "$SOURCE_BASE" 2>/dev/null || true

    # 최종 결과 확인
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "에러 복구 후 파일 생성됨"

    local permissions=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    assert_test "[[ '$permissions' == '644' ]]" "복구 후 올바른 권한 설정됨" "644" "$permissions"
}

# 정리 함수
cleanup_test_environment() {
    log_debug "통합 테스트 환경 정리: $TEST_DIR"
    chmod -R 755 "$TEST_DIR" 2>/dev/null || true  # 권한 문제 해결
    rm -rf "$TEST_DIR"
}

# 메인 테스트 실행
main() {
    log_header "Claude Activation 통합 테스트 시작"
    log_info "테스트 디렉토리: $TEST_DIR"
    log_info "Dotfiles 루트: $DOTFILES_ROOT"

    # 신호 핸들러 설정
    setup_signal_handlers

    # 필수 도구 확인
    local required_tools=("nix-instantiate" "bash" "cp" "chmod" "stat" "ln")
    if ! check_required_tools "${required_tools[@]}"; then
        exit 1
    fi

    # NIX_PATH가 설정되어 있는지 확인
    if [[ -z "${NIX_PATH:-}" ]]; then
        log_warning "NIX_PATH가 설정되지 않았습니다. 기본 nixpkgs를 사용합니다."
        export NIX_PATH="nixpkgs=channel:nixpkgs-unstable"
    fi

    # 통합 테스트 실행
    test_full_activation_clean_environment
    test_symlink_conversion_with_state_preservation
    test_fallback_source_resolution
    test_concurrent_modification_handling
    test_broken_symlink_cleanup
    test_error_recovery

    # 결과 출력
    log_separator
    log_header "통합 테스트 결과"
    log_info "통과: $TESTS_PASSED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "실패: $TESTS_FAILED"
        log_error "일부 통합 테스트가 실패했습니다."
        exit 1
    else
        log_success "모든 통합 테스트가 통과했습니다! 🎉"
        exit 0
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
