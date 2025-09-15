#!/usr/bin/env bash
# ABOUTME: Claude activation 통합 테스트 - settings.json 복사 로직, 동적 상태 병합, 권한 처리
# ABOUTME: create_settings_copy() 함수의 모든 기능을 실제 환경에서 통합 테스트로 검증

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
SOURCE_BASE="$TEST_DIR/source"
TARGET_BASE="$TEST_DIR/target"
CLAUDE_DIR="$TARGET_BASE/.claude"

# 공통 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/claude-activation-utils.sh"

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

# 공통 유틸리티의 어설션 함수 사용
assert_test() {
    local condition="$1"
    local test_name="$2"
    local expected="${3:-}"
    local actual="${4:-}"

    if assert_claude_test "$condition" "$test_name" "$expected" "$actual"; then
        ((TESTS_PASSED++))
        return 0
    else
        ((TESTS_FAILED++))
        return 1
    fi
}

# 테스트 환경 설정 함수
setup_test_environment() {
    log_info "테스트 환경 설정 중..."

    # 디렉토리 구조 생성
    mkdir -p "$SOURCE_BASE/commands" "$SOURCE_BASE/agents"
    mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/agents"

    # 테스트용 settings.json 파일들 생성
    cat > "$SOURCE_BASE/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true,
  "debugMode": false
}
EOF

    # 동적 상태가 있는 기존 settings.json (백업용)
    cat > "$TEST_DIR/existing_settings.json" << 'EOF'
{
  "version": "0.9.0",
  "theme": "light",
  "autoSave": false,
  "debugMode": true,
  "feedbackSurveyState": {
    "lastShown": "2024-01-15",
    "dismissed": ["survey1", "survey2"],
    "completedSurveys": ["initial"],
    "userPreferences": {
      "showSurveys": true,
      "frequency": "weekly"
    }
  }
}
EOF

    # 잘못된 JSON 형식 테스트용
    cat > "$TEST_DIR/invalid_settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark"
  // 잘못된 JSON 형식 (주석)
EOF

    # 테스트용 CLAUDE.md
    cat > "$SOURCE_BASE/CLAUDE.md" << 'EOF'
# Test Claude Configuration
Test configuration markdown file
EOF
}

# create_settings_copy 함수는 이제 claude-activation-utils.sh에서 제공됩니다.

# 단위 테스트 함수들

test_basic_settings_copy() {
    log_header "기본 settings.json 복사 테스트"

    # 디버그 정보 출력
    log_debug "소스 파일 확인: $SOURCE_BASE/settings.json"
    log_debug "타겟 디렉토리: $CLAUDE_DIR"

    # 소스 파일 존재 여부 확인
    if [[ ! -f "$SOURCE_BASE/settings.json" ]]; then
        log_error "소스 파일이 존재하지 않습니다: $SOURCE_BASE/settings.json"
        ((TESTS_FAILED++))
        return 1
    fi

    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"

    # 파일이 복사되었는지 확인
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "settings.json 파일 복사"

    # 심볼릭 링크가 아닌 실제 파일인지 확인
    assert_test "[[ ! -L '$CLAUDE_DIR/settings.json' ]]" "복사본은 심볼릭 링크가 아님"

    # 파일 권한 확인 (644)
    local permissions=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    assert_test "[[ '$permissions' == '644' ]]" "파일 권한이 644로 설정됨" "644" "$permissions"

    # JSON 내용 확인
    if command -v jq >/dev/null 2>&1; then
        local version=$(jq -r '.version' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$version' == '1.0.0' ]]" "JSON 내용이 올바르게 복사됨" "1.0.0" "$version"
    fi
}

test_symlink_to_copy_conversion() {
    log_header "심볼릭 링크에서 복사본으로 변환 테스트"

    # 먼저 심볼릭 링크 생성
    ln -sf "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"

    # 심볼릭 링크 확인
    assert_test "[[ -L '$CLAUDE_DIR/settings.json' ]]" "심볼릭 링크가 생성됨"

    # create_settings_copy 실행
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

    # 심볼릭 링크가 제거되고 복사본이 생성되었는지 확인
    assert_test "[[ ! -L '$CLAUDE_DIR/settings.json' ]]" "심볼릭 링크가 제거됨"
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "복사본이 생성됨"
}

test_dynamic_state_preservation() {
    log_header "동적 상태 보존 테스트 (feedbackSurveyState)"

    # jq가 없으면 테스트 건너뜀
    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq가 없어서 동적 상태 병합 테스트를 건너뜁니다"
        return 0
    fi

    # 기존 동적 상태가 있는 파일 준비
    cp "$TEST_DIR/existing_settings.json" "$CLAUDE_DIR/settings.json"

    # create_settings_copy 실행
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

    # 새 설정이 적용되었는지 확인
    local new_version=$(jq -r '.version' "$CLAUDE_DIR/settings.json")
    assert_test "[[ '$new_version' == '1.0.0' ]]" "새 설정의 version이 적용됨" "1.0.0" "$new_version"

    local new_theme=$(jq -r '.theme' "$CLAUDE_DIR/settings.json")
    assert_test "[[ '$new_theme' == 'dark' ]]" "새 설정의 theme이 적용됨" "dark" "$new_theme"

    # 동적 상태가 보존되었는지 확인
    local preserved_last_shown=$(jq -r '.feedbackSurveyState.lastShown' "$CLAUDE_DIR/settings.json")
    assert_test "[[ '$preserved_last_shown' == '2024-01-15' ]]" "feedbackSurveyState.lastShown 보존" "2024-01-15" "$preserved_last_shown"

    local dismissed_count=$(jq -r '.feedbackSurveyState.dismissed | length' "$CLAUDE_DIR/settings.json")
    assert_test "[[ '$dismissed_count' == '2' ]]" "feedbackSurveyState.dismissed 배열 보존" "2" "$dismissed_count"

    local user_prefs_frequency=$(jq -r '.feedbackSurveyState.userPreferences.frequency' "$CLAUDE_DIR/settings.json")
    assert_test "[[ '$user_prefs_frequency' == 'weekly' ]]" "중첩된 사용자 설정 보존" "weekly" "$user_prefs_frequency"
}

test_backup_cleanup() {
    log_header "백업 파일 정리 테스트"

    # 기존 파일 준비
    cp "$TEST_DIR/existing_settings.json" "$CLAUDE_DIR/settings.json"

    # create_settings_copy 실행
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

    # 백업 파일이 정리되었는지 확인
    assert_test "[[ ! -f '$CLAUDE_DIR/settings.json.backup' ]]" "백업 파일이 정리됨"
}

test_missing_source_file() {
    log_header "존재하지 않는 소스 파일 처리 테스트"

    # 존재하지 않는 파일로 테스트
    create_settings_copy "$SOURCE_BASE/nonexistent.json" "$CLAUDE_DIR/nonexistent.json" >/dev/null 2>&1

    # 타겟 파일이 생성되지 않았는지 확인
    assert_test "[[ ! -f '$CLAUDE_DIR/nonexistent.json' ]]" "존재하지 않는 소스 파일 처리"
}

test_jq_fallback_behavior() {
    log_header "jq 없을 때 fallback 동작 테스트"

    # jq가 있는지 확인
    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq가 없어서 fallback 테스트를 건너뜁니다"
        return 0
    fi

    # 임시로 jq를 숨김 (PATH 조작)
    local original_path="$PATH"
    export PATH="/usr/bin:/bin:/sbin"  # jq가 없는 제한된 PATH

    # 기존 파일 준비
    cp "$TEST_DIR/existing_settings.json" "$CLAUDE_DIR/settings.json"

    # create_settings_copy 실행
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

    # PATH 복원
    export PATH="$original_path"

    # 새 설정이 적용되었는지 확인
    local version=$(jq -r '.version' "$CLAUDE_DIR/settings.json" 2>/dev/null || echo "unknown")
    assert_test "[[ '$version' == '1.0.0' ]]" "jq 없을 때도 새 설정 적용됨" "1.0.0" "$version"

    # 동적 상태는 병합되지 않아야 함 (jq 없을 때)
    local feedback_state="null"
    if jq -e '.feedbackSurveyState' "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
        feedback_state="present"
    fi
    assert_test "[[ '$feedback_state' == 'null' ]]" "jq 없을 때 동적 상태 병합 건너뜀"
}

test_invalid_json_handling() {
    log_header "잘못된 JSON 처리 테스트"

    # 잘못된 JSON이 있는 기존 파일 준비
    cp "$TEST_DIR/invalid_settings.json" "$CLAUDE_DIR/settings.json"

    # create_settings_copy 실행 (에러 발생해도 계속)
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1 || true

    # 새 설정이 적용되었는지 확인
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "잘못된 JSON에도 새 파일 생성됨"

    if command -v jq >/dev/null 2>&1; then
        # 유효한 JSON인지 확인
        local is_valid_json="false"
        if jq empty "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
            is_valid_json="true"
        fi
        assert_test "[[ '$is_valid_json' == 'true' ]]" "새 설정 파일이 유효한 JSON임"
    fi
}

test_file_permissions_consistency() {
    log_header "파일 권한 일관성 테스트"

    # 다양한 초기 권한으로 테스트
    for initial_perm in 600 755 777; do
        # 테스트 파일 생성
        touch "$CLAUDE_DIR/settings.json"
        chmod "$initial_perm" "$CLAUDE_DIR/settings.json"

        # create_settings_copy 실행
        create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

        # 최종 권한이 644인지 확인
        local final_perm=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
        assert_test "[[ '$final_perm' == '644' ]]" "초기 권한 $initial_perm에서 644로 변경됨" "644" "$final_perm"

        # 다음 테스트를 위한 정리
        rm -f "$CLAUDE_DIR/settings.json"
    done
}

# 통합 테스트 함수
test_complete_workflow() {
    log_header "완전한 워크플로우 통합 테스트"

    # 1단계: 심볼릭 링크로 시작
    ln -sf "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"

    # 2단계: 사용자가 동적 상태 추가
    if command -v jq >/dev/null 2>&1; then
        echo '{"version":"1.0.0","theme":"dark","autoSave":true,"debugMode":false,"feedbackSurveyState":{"userAdded":"true"}}' > "$CLAUDE_DIR/settings.json"
    fi

    # 3단계: create_settings_copy 실행
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

    # 4단계: 결과 검증
    assert_test "[[ ! -L '$CLAUDE_DIR/settings.json' ]]" "최종적으로 심볼릭 링크가 아님"
    assert_test "[[ -f '$CLAUDE_DIR/settings.json' ]]" "최종적으로 파일이 존재함"

    local final_perm=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    assert_test "[[ '$final_perm' == '644' ]]" "최종 권한이 644임" "644" "$final_perm"

    if command -v jq >/dev/null 2>&1; then
        local user_added=$(jq -r '.feedbackSurveyState.userAdded // "null"' "$CLAUDE_DIR/settings.json")
        assert_test "[[ '$user_added' == 'true' ]]" "사용자 추가 동적 상태 보존됨" "true" "$user_added"
    fi
}

# 정리 함수
cleanup_test_environment() {
    log_debug "테스트 환경 정리: $TEST_DIR"
    rm -rf "$TEST_DIR"
}

# 메인 테스트 실행
main() {
    log_header "Claude Activation 포괄적 테스트 시작"
    log_info "테스트 디렉토리: $TEST_DIR"

    # 신호 핸들러 설정
    setup_signal_handlers

    # 필수 도구 확인 (jq는 선택사항)
    local required_tools=("cp" "chmod" "stat" "ln")
    if ! check_required_tools "${required_tools[@]}"; then
        exit 1
    fi

    # 테스트 환경 설정
    setup_test_environment

    # 단위 테스트 실행
    test_basic_settings_copy
    test_symlink_to_copy_conversion
    test_dynamic_state_preservation
    test_backup_cleanup
    test_missing_source_file
    test_jq_fallback_behavior
    test_invalid_json_handling
    test_file_permissions_consistency

    # 통합 테스트 실행
    test_complete_workflow

    # 결과 출력
    log_separator
    log_header "테스트 결과"
    log_info "통과: $TESTS_PASSED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "실패: $TESTS_FAILED"
        log_error "일부 테스트가 실패했습니다."
        exit 1
    else
        log_success "모든 테스트가 통과했습니다! 🎉"
        exit 0
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
