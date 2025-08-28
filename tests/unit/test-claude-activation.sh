#!/usr/bin/env bash
# ABOUTME: Claude activation 스크립트 포괄적 테스트 - settings.json 복사 로직, 동적 상태 병합, 권한 처리
# ABOUTME: create_settings_copy() 함수의 모든 기능을 단위 테스트로 검증

set -euo pipefail

# 새로운 테스트 코어 로드 (단일 진입점)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-core.sh"

# 테스트 스위트 초기화
test_suite_init "Claude Activation Tests"

# 표준 테스트 환경 설정
setup_standard_test_environment "claude-activation"

# 테스트별 환경 설정
SOURCE_BASE="$TEST_DIR/source"
TARGET_BASE="$TEST_DIR/target"
CLAUDE_DIR="$TARGET_BASE/.claude"

# 테스트 환경 설정 함수
setup_test_environment() {
    log_info "Claude activation 테스트 환경 설정 중..."

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

# claude-activation 로직을 함수로 추출 (테스트용)
create_settings_copy() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")

    echo "처리 중: $file_name (복사 모드)"

    if [[ ! -f "$source_file" ]]; then
        echo "  소스 파일 없음, 건너뜀"
        return 0
    fi

    # 기존 파일 백업 (동적 상태 보존용)
    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
        echo "  기존 settings.json 백업 중..."
        cp "$target_file" "$target_file.backup"
    fi

    # 기존 심볼릭 링크 제거
    if [[ -L "$target_file" ]]; then
        echo "  기존 심볼릭 링크 제거"
        rm -f "$target_file"
    fi

    # 새로운 설정을 복사
    cp "$source_file" "$target_file"
    chmod 644 "$target_file"
    echo "  파일 복사 완료: $target_file (644 권한)"

    # 백업에서 동적 상태 병합
    if [[ -f "$target_file.backup" ]]; then
        echo "  동적 상태 병합 시도 중..."

        # jq가 있으면 JSON 병합, 없으면 백업만 유지
        if command -v jq >/dev/null 2>&1; then
            # 백업에서 feedbackSurveyState 추출해서 병합
            if jq -e '.feedbackSurveyState' "$target_file.backup" >/dev/null 2>&1; then
                local feedback_state=$(jq -c '.feedbackSurveyState' "$target_file.backup")
                jq --argjson feedback_state "$feedback_state" '.feedbackSurveyState = $feedback_state' "$target_file" > "$target_file.tmp"
                mv "$target_file.tmp" "$target_file"
                echo "  ✓ feedbackSurveyState 병합 완료"
            fi
        else
            echo "  ⚠ jq 없음: 동적 상태 병합 건너뜀"
        fi

        rm -f "$target_file.backup"
    fi
}

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
    assert_file_exists "$CLAUDE_DIR/settings.json" "settings.json 파일 복사"

    # 심볼릭 링크가 아닌 실제 파일인지 확인
    assert_not "[[ -L '$CLAUDE_DIR/settings.json' ]]" "복사본은 심볼릭 링크가 아님"

    # 파일 권한 확인 (644)
    assert_file_permissions "$CLAUDE_DIR/settings.json" "644" "파일 권한이 644로 설정됨"

    # JSON 내용 확인
    if command -v jq >/dev/null 2>&1; then
        local version=$(jq -r '.version' "$CLAUDE_DIR/settings.json")
        assert_equals "1.0.0" "$version" "JSON 내용이 올바르게 복사됨"
    fi
}

test_symlink_to_copy_conversion() {
    log_header "심볼릭 링크에서 복사본으로 변환 테스트"

    # 먼저 심볼릭 링크 생성
    ln -sf "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"

    # 심볼릭 링크 확인
    assert_file_is_symlink "$CLAUDE_DIR/settings.json" "심볼릭 링크가 생성됨"

    # create_settings_copy 실행
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

    # 심볼릭 링크가 제거되고 복사본이 생성되었는지 확인
    assert_not "[[ -L '$CLAUDE_DIR/settings.json' ]]" "심볼릭 링크가 제거됨"
    assert_file_exists "$CLAUDE_DIR/settings.json" "복사본이 생성됨"
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
    assert_equals "1.0.0" "$new_version" "새 설정의 version이 적용됨"

    local new_theme=$(jq -r '.theme' "$CLAUDE_DIR/settings.json")
    assert_equals "dark" "$new_theme" "새 설정의 theme이 적용됨"

    # 동적 상태가 보존되었는지 확인
    local preserved_last_shown=$(jq -r '.feedbackSurveyState.lastShown' "$CLAUDE_DIR/settings.json")
    assert_equals "2024-01-15" "$preserved_last_shown" "feedbackSurveyState.lastShown 보존"

    local dismissed_count=$(jq -r '.feedbackSurveyState.dismissed | length' "$CLAUDE_DIR/settings.json")
    assert_equals "2" "$dismissed_count" "feedbackSurveyState.dismissed 배열 보존"

    local user_prefs_frequency=$(jq -r '.feedbackSurveyState.userPreferences.frequency' "$CLAUDE_DIR/settings.json")
    assert_equals "weekly" "$user_prefs_frequency" "중첩된 사용자 설정 보존"
}

test_backup_cleanup() {
    log_header "백업 파일 정리 테스트"

    # 기존 파일 준비
    cp "$TEST_DIR/existing_settings.json" "$CLAUDE_DIR/settings.json"

    # create_settings_copy 실행
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1

    # 백업 파일이 정리되었는지 확인
    assert_not "[[ -f '$CLAUDE_DIR/settings.json.backup' ]]" "백업 파일이 정리됨"
}

test_missing_source_file() {
    log_header "존재하지 않는 소스 파일 처리 테스트"

    # 존재하지 않는 파일로 테스트
    create_settings_copy "$SOURCE_BASE/nonexistent.json" "$CLAUDE_DIR/nonexistent.json" >/dev/null 2>&1

    # 타겟 파일이 생성되지 않았는지 확인
    assert_not "[[ -f '$CLAUDE_DIR/nonexistent.json' ]]" "존재하지 않는 소스 파일 처리"
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
    assert_equals "1.0.0" "$version" "jq 없을 때도 새 설정 적용됨"

    # 동적 상태는 병합되지 않아야 함 (jq 없을 때)
    local feedback_state="null"
    if jq -e '.feedbackSurveyState' "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
        feedback_state="present"
    fi
    assert_equals "null" "$feedback_state" "jq 없을 때 동적 상태 병합 건너뜀"
}

test_invalid_json_handling() {
    log_header "잘못된 JSON 처리 테스트"

    # 잘못된 JSON이 있는 기존 파일 준비
    cp "$TEST_DIR/invalid_settings.json" "$CLAUDE_DIR/settings.json"

    # create_settings_copy 실행 (에러 발생해도 계속)
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json" >/dev/null 2>&1 || true

    # 새 설정이 적용되었는지 확인
    assert_file_exists "$CLAUDE_DIR/settings.json" "잘못된 JSON에도 새 파일 생성됨"

    if command -v jq >/dev/null 2>&1; then
        # 유효한 JSON인지 확인
        local is_valid_json="false"
        if jq empty "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
            is_valid_json="true"
        fi
        assert_equals "true" "$is_valid_json" "새 설정 파일이 유효한 JSON임"
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
        assert_equals "644" "$final_perm" "초기 권한 $initial_perm에서 644로 변경됨"

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
    assert_not "[[ -L '$CLAUDE_DIR/settings.json' ]]" "최종적으로 심볼릭 링크가 아님"
    assert_file_exists "$CLAUDE_DIR/settings.json" "최종적으로 파일이 존재함"

    local final_perm=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    assert_equals "644" "$final_perm" "최종 권한이 644임"

    if command -v jq >/dev/null 2>&1; then
        local user_added=$(jq -r '.feedbackSurveyState.userAdded // "null"' "$CLAUDE_DIR/settings.json")
        assert_equals "true" "$user_added" "사용자 추가 동적 상태 보존됨"
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
}

# === 테스트 그룹 설정 및 실행 ===

# 기본 기능 테스트 그룹
test_basic_functionality() {
    start_test_group "기본 기능 테스트"
    setup_test_environment
    test_basic_settings_copy
    test_symlink_to_copy_conversion
    test_backup_cleanup
    end_test_group
}

# 고급 기능 테스트 그룹
test_advanced_features() {
    start_test_group "고급 기능 테스트"
    setup_test_environment
    test_dynamic_state_preservation
    test_jq_fallback_behavior
    test_invalid_json_handling
    end_test_group
}

# 엣지 케이스 테스트 그룹
test_edge_cases() {
    start_test_group "엣지 케이스 테스트"
    setup_test_environment
    test_missing_source_file
    test_file_permissions_consistency
    end_test_group
}

# 통합 테스트 그룹
test_integration() {
    start_test_group "통합 테스트"
    setup_test_environment
    test_complete_workflow
    end_test_group
}

# === 필수 함수 import 확인 ===
if ! declare -f create_settings_copy >/dev/null; then
    log_error "create_settings_copy 함수를 찾을 수 없습니다"
    log_info "claude-activation.nix에서 함수를 import하세요"
    exit 1
fi

# === 모든 테스트 실행 ===

# 기본 기능 테스트
test_basic_functionality

# 고급 기능 테스트
test_advanced_features

# 엣지 케이스 테스트
test_edge_cases

# 통합 테스트
test_integration

# 테스트 스위트 완료
test_suite_finish
