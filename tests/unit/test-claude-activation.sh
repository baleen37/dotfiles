#!/usr/bin/env bash
# ABOUTME: Claude activation 스크립트의 서브디렉토리 지원 기능 단위 테스트
# ABOUTME: 파일 복사, 디렉토리 처리, 해시 비교 로직을 검증합니다.

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
SOURCE_BASE="$TEST_DIR/source"
TARGET_BASE="$TEST_DIR/target"
CLAUDE_DIR="$TARGET_BASE/.claude"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

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

# 테스트 헬퍼 함수
setup_test_environment() {
    log_info "테스트 환경 설정 중..."

    # 소스 디렉토리 구조 생성
    mkdir -p "$SOURCE_BASE/commands/git"
    mkdir -p "$SOURCE_BASE/commands/workflow"
    mkdir -p "$SOURCE_BASE/agents"

    # 타겟 디렉토리 구조 생성
    mkdir -p "$CLAUDE_DIR/commands"
    mkdir -p "$CLAUDE_DIR/agents"

    # 테스트 파일 생성
    cat > "$SOURCE_BASE/CLAUDE.md" << 'EOF'
# Claude Configuration
Test configuration file
EOF

    cat > "$SOURCE_BASE/settings.json" << 'EOF'
{
  "test": "configuration"
}
EOF

    cat > "$SOURCE_BASE/commands/task.md" << 'EOF'
# Task Command
Root level command
EOF

    cat > "$SOURCE_BASE/commands/git/commit.md" << 'EOF'
# Git Commit Command
Git subdirectory command
EOF

    cat > "$SOURCE_BASE/commands/git/upsert-pr.md" << 'EOF'
# Git Upsert PR Command
Another git subdirectory command
EOF

    cat > "$SOURCE_BASE/commands/workflow/deploy.md" << 'EOF'
# Workflow Deploy Command
Workflow subdirectory command
EOF

    cat > "$SOURCE_BASE/agents/code-reviewer.md" << 'EOF'
# Code Reviewer Agent
Test agent file
EOF
}

cleanup_test_environment() {
    log_info "테스트 환경 정리 중..."
    rm -rf "$TEST_DIR"
}

# Claude activation 스크립트 실행 함수
run_claude_activation() {
    local dry_run="${1:-0}"

    # Claude activation 스크립트 내용을 함수로 실행
    export CLAUDE_DIR="$CLAUDE_DIR"
    export SOURCE_DIR="$SOURCE_BASE"
    export DRY_RUN="$dry_run"

    # DRY_RUN_CMD 설정
    local DRY_RUN_CMD=""
    if [[ "$DRY_RUN" == "1" ]]; then
        DRY_RUN_CMD="echo '[DRY RUN]'"
    fi

    # 디렉토리 생성
    eval "$DRY_RUN_CMD mkdir -p \"$CLAUDE_DIR/commands\""
    eval "$DRY_RUN_CMD mkdir -p \"$CLAUDE_DIR/agents\""

    # 파일 해시 비교 함수 (macOS 호환)
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
            # Fallback: 파일 크기 비교
            local source_size=$(wc -c < "$source")
            local target_size=$(wc -c < "$target")
            [[ "$source_size" != "$target_size" ]]
            return $?
        fi

        [[ "$source_hash" != "$target_hash" ]]
    }

    # 조건부 복사 함수
    smart_copy() {
        local source_file="$1"
        local target_file="$2"

        if [[ ! -f "$source_file" ]]; then
            echo "소스 파일 없음: $source_file"
            return 0
        fi

        if [[ ! -f "$target_file" ]]; then
            echo "새 파일 복사: $(basename "$source_file")"
            eval "$DRY_RUN_CMD cp \"$source_file\" \"$target_file\""
            eval "$DRY_RUN_CMD chmod 644 \"$target_file\""
            return 0
        fi

        if files_differ "$source_file" "$target_file"; then
            echo "파일 업데이트: $(basename "$source_file")"
            eval "$DRY_RUN_CMD cp \"$source_file\" \"$target_file\""
            eval "$DRY_RUN_CMD chmod 644 \"$target_file\""
        else
            echo "파일 동일: $(basename "$source_file")"
        fi
    }

    # 메인 설정 파일들 처리
    for config_file in "settings.json" "CLAUDE.md"; do
        smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
    done

    # commands 디렉토리 처리 (서브디렉토리 지원)
    if [[ -d "$SOURCE_DIR/commands" ]]; then
        find "$SOURCE_DIR/commands" -name "*.md" -type f | while read -r cmd_file; do
            # 소스에서 commands 디렉토리를 기준으로 한 상대 경로 계산
            rel_path="${cmd_file#$SOURCE_DIR/commands/}"
            target_file="$CLAUDE_DIR/commands/$rel_path"

            # 타겟 디렉토리가 없으면 생성
            target_dir=$(dirname "$target_file")
            eval "$DRY_RUN_CMD mkdir -p \"$target_dir\""

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
}

# 테스트 헬퍼 함수
assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    if [[ -f "$file_path" ]]; then
        log_info "✅ $test_name 성공"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "❌ $test_name 실패: $file_path 파일 없음"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 테스트 함수들
test_subdirectory_support() {
    log_info "테스트: 서브디렉토리 지원 확인"

    run_claude_activation 0

    # 테스트할 파일들 배열
    local files_to_test=(
        "$CLAUDE_DIR/commands/git/commit.md:Git commit 파일 복사"
        "$CLAUDE_DIR/commands/git/upsert-pr.md:Git upsert-pr 파일 복사"
        "$CLAUDE_DIR/commands/workflow/deploy.md:Workflow deploy 파일 복사"
        "$CLAUDE_DIR/commands/task.md:루트 레벨 명령어 파일 복사"
    )

    for file_test in "${files_to_test[@]}"; do
        IFS=':' read -r file_path test_name <<< "$file_test"
        assert_file_exists "$file_path" "$test_name"
    done
}

test_directory_structure_preservation() {
    log_info "테스트: 디렉토리 구조 보존 확인"

    # 서브디렉토리 구조가 제대로 생성되었는지 확인
    if [[ -d "$CLAUDE_DIR/commands/git" ]] && [[ -d "$CLAUDE_DIR/commands/workflow" ]]; then
        log_info "✅ 서브디렉토리 구조 보존 성공"
        ((TESTS_PASSED++))
    else
        log_error "❌ 서브디렉토리 구조 보존 실패"
        ((TESTS_FAILED++))
    fi
}

test_file_content_integrity() {
    log_info "테스트: 파일 내용 무결성 확인"

    # Git commit 파일 내용 확인
    if grep -q "Git Commit Command" "$CLAUDE_DIR/commands/git/commit.md"; then
        log_info "✅ Git commit 파일 내용 무결성 유지"
        ((TESTS_PASSED++))
    else
        log_error "❌ Git commit 파일 내용 손상"
        ((TESTS_FAILED++))
        return 1
    fi

    # Workflow deploy 파일 내용 확인
    if grep -q "Workflow Deploy Command" "$CLAUDE_DIR/commands/workflow/deploy.md"; then
        log_info "✅ Workflow deploy 파일 내용 무결성 유지"
        ((TESTS_PASSED++))
    else
        log_error "❌ Workflow deploy 파일 내용 손상"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_dry_run_mode() {
    log_info "테스트: Dry run 모드 확인"

    # 새로운 테스트 환경 생성
    local dry_test_dir=$(mktemp -d)
    local dry_claude_dir="$dry_test_dir/.claude"

    # 원본 환경 변수 백업
    local orig_claude_dir="$CLAUDE_DIR"
    export CLAUDE_DIR="$dry_claude_dir"

    # Dry run 실행
    run_claude_activation 1 > /dev/null 2>&1

    # Dry run에서는 실제 파일이 생성되지 않아야 함
    if [[ ! -d "$dry_claude_dir" ]]; then
        log_info "✅ Dry run 모드에서 파일 생성 안됨"
        ((TESTS_PASSED++))
    else
        log_error "❌ Dry run 모드에서 파일이 생성됨"
        ((TESTS_FAILED++))
    fi

    # 환경 복원
    export CLAUDE_DIR="$orig_claude_dir"
    rm -rf "$dry_test_dir"
}

test_missing_source_handling() {
    log_info "테스트: 존재하지 않는 소스 파일 처리"

    # smart_copy 함수를 환경에 로드
    export -f files_differ smart_copy
    export DRY_RUN_CMD CLAUDE_DIR

    # 존재하지 않는 파일 테스트
    if smart_copy "$SOURCE_BASE/nonexistent.md" "$CLAUDE_DIR/nonexistent.md" 2>/dev/null; then
        # smart_copy는 항상 성공하지만 파일은 복사되지 않아야 함
        if [[ ! -f "$CLAUDE_DIR/nonexistent.md" ]]; then
            log_info "✅ 존재하지 않는 소스 파일 올바르게 처리"
            ((TESTS_PASSED++))
        else
            log_error "❌ 존재하지 않는 소스 파일이 복사됨"
            ((TESTS_FAILED++))
        fi
    else
        log_info "✅ 존재하지 않는 소스 파일 올바르게 처리 (함수 실패)"
        ((TESTS_PASSED++))
    fi
}

# 메인 테스트 실행
main() {
    log_info "Claude Activation 서브디렉토리 지원 테스트 시작"
    log_info "테스트 디렉토리: $TEST_DIR"

    # 신호 핸들러 설정
    trap cleanup_test_environment EXIT

    # 테스트 환경 설정
    setup_test_environment

    # 테스트 실행
    test_subdirectory_support
    test_directory_structure_preservation
    test_file_content_integrity
    test_dry_run_mode
    test_missing_source_handling

    # 결과 출력
    echo
    log_info "=================== 테스트 결과 ==================="
    log_info "통과: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "실패: $TESTS_FAILED"
        log_error "일부 테스트가 실패했습니다."
        exit 1
    else
        log_info "모든 테스트가 통과했습니다! 🎉"
        exit 0
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
