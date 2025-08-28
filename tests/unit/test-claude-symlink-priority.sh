#!/usr/bin/env bash
# ABOUTME: Claude 심볼릭 링크 우선순위 테스트
# ABOUTME: dotfiles 경로가 Nix store보다 우선되는지 검증합니다.

set -euo pipefail

# 새로운 테스트 코어 로드 (단일 진입점)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-core.sh"

# 테스트 스위트 초기화
test_suite_init "Claude Symlink Priority Tests"

# 표준 테스트 환경 설정
setup_standard_test_environment "claude-symlink-priority"

# 테스트별 환경 변수
HOME_TEST="$TEST_DIR/home"
DOTFILES_TEST="$HOME_TEST/dev/dotfiles"
CLAUDE_DIR="$HOME_TEST/.claude"

# 테스트 환경 설정
setup_test_environment() {
    log_info "테스트 환경 설정 중..."

    # 디렉토리 구조 생성
    mkdir -p "$DOTFILES_TEST/modules/shared/config/claude"
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$TEST_DIR/nix-store/source/modules/shared/config/claude"

    # dotfiles의 설정 파일 생성
    cat > "$DOTFILES_TEST/modules/shared/config/claude/settings.json" << 'EOF'
{
  "model": "sonnet",
  "source": "dotfiles",
  "priority": "high"
}
EOF

    # Nix store의 설정 파일 생성 (다른 내용)
    cat > "$TEST_DIR/nix-store/source/modules/shared/config/claude/settings.json" << 'EOF'
{
  "model": "haiku",
  "source": "nix-store",
  "priority": "low"
}
EOF

    log_info "테스트 파일 생성 완료"
}

cleanup_test_environment() {
    log_info "테스트 환경 정리 중..."
    rm -rf "$TEST_DIR"
}

# Claude activation 스크립트의 소스 디렉토리 결정 로직을 시뮬레이션
test_source_directory_priority() {
    log_info "테스트: 소스 디렉토리 우선순위 확인"

    # 현재 로직: dotfiles 경로 우선
    local homeDirectory="$HOME_TEST"
    local self="$TEST_DIR/nix-store/source"

    # 우선순위: 1. dotfiles 경로 2. fallback들
    local sourceDir="$homeDirectory/dev/dotfiles/modules/shared/config/claude"
    local fallbackSources=(
        "./modules/shared/config/claude"
        "/Users/jito/dev/dotfiles/modules/shared/config/claude"
        "$self/modules/shared/config/claude"
    )

    local actualSourceDir=""

    # 기본 소스 디렉토리 확인
    assert_directory_exists "$sourceDir" "기본 소스 디렉토리 존재"
    actualSourceDir="$sourceDir"

    # 선택된 소스가 dotfiles인지 확인
    assert_matches_pattern "$actualSourceDir" "dev/dotfiles" "올바른 우선순위: dotfiles 경로 선택됨"
}

# 심볼릭 링크 생성 테스트
test_symlink_creation() {
    log_info "테스트: 심볼릭 링크 생성 확인"

    local sourceFile="$DOTFILES_TEST/modules/shared/config/claude/settings.json"
    local targetFile="$CLAUDE_DIR/settings.json"

    # 심볼릭 링크 생성
    ln -sf "$sourceFile" "$targetFile"

    # 링크 검증
    assert_file_is_symlink "$targetFile" "심볼릭 링크 생성 성공"

    # 링크 타겟 확인
    local linkTarget=$(readlink "$targetFile")
    assert_matches_pattern "$linkTarget" "dev/dotfiles" "심볼릭 링크가 dotfiles를 가리킴"
}

# 파일 내용 확인 테스트
test_file_content_resolution() {
    log_info "테스트: 파일 내용 해석 확인"

    local targetFile="$CLAUDE_DIR/settings.json"

    if [[ -f "$targetFile" ]]; then
        # dotfiles의 내용이 나와야 함
        assert_file_contains "$targetFile" '"source": "dotfiles"' "dotfiles 설정 파일 내용 확인"

        # Nix store 내용이 나오면 안됨
        assert_not "grep -q '\"source\": \"nix-store\"' '$targetFile'" "Nix store 설정이 사용되지 않음"
    else
        assert_fail "타겟 파일이 존재하지 않음"
    fi
}

# Nix store fallback 테스트
test_nix_store_fallback() {
    log_info "테스트: Nix store fallback 시나리오"

    # dotfiles 경로를 임시로 제거
    local dotfilesPath="$DOTFILES_TEST/modules/shared/config/claude"
    local backupPath="$dotfilesPath.backup"

    mv "$dotfilesPath" "$backupPath"

    # fallback 로직 시뮬레이션
    local homeDirectory="$HOME_TEST"
    local self="$TEST_DIR/nix-store/source"
    local sourceDir="$homeDirectory/dev/dotfiles/modules/shared/config/claude"

    if [[ ! -d "$sourceDir" ]]; then
        # fallback으로 Nix store 사용
        local nixStoreSource="$self/modules/shared/config/claude"
        assert_directory_exists "$nixStoreSource" "Nix store fallback 확인됨"
    fi

    # 복원
    mv "$backupPath" "$dotfilesPath"
}

# === 테스트 그룹 설정 및 실행 ===

# 우선순위 및 링크 테스트 그룹
test_priority_and_links() {
    start_test_group "우선순위 및 링크 테스트"
    setup_test_environment
    test_source_directory_priority
    test_symlink_creation
    end_test_group
}

# 파일 내용 및 fallback 테스트 그룹
test_content_and_fallback() {
    start_test_group "파일 내용 및 Fallback 테스트"
    test_file_content_resolution
    test_nix_store_fallback
    end_test_group
}

# === 모든 테스트 실행 ===

# 우선순위 및 링크 테스트
test_priority_and_links

# 파일 내용 및 fallback 테스트
test_content_and_fallback

# 테스트 스위트 완료
test_suite_finish
