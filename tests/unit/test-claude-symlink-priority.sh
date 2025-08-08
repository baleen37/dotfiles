#!/usr/bin/env bash
# ABOUTME: Claude 심볼릭 링크 우선순위 테스트
# ABOUTME: dotfiles 경로가 Nix store보다 우선되는지 검증합니다.

set -uo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
HOME_TEST="$TEST_DIR/home"
DOTFILES_TEST="$HOME_TEST/dev/dotfiles"
CLAUDE_DIR="$HOME_TEST/.claude"

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
    if [[ -d "$sourceDir" ]]; then
        actualSourceDir="$sourceDir"
        log_info "✅ 기본 소스 디렉토리 선택: dotfiles"
        ((TESTS_PASSED++))
    else
        log_error "❌ 기본 소스 디렉토리 없음"
        ((TESTS_FAILED++))
        return 1
    fi

    # 선택된 소스가 dotfiles인지 확인
    if [[ "$actualSourceDir" == *"dev/dotfiles"* ]]; then
        log_info "✅ 올바른 우선순위: dotfiles 경로 선택됨"
        ((TESTS_PASSED++))
    else
        log_error "❌ 잘못된 우선순위: $actualSourceDir"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 심볼릭 링크 생성 테스트
test_symlink_creation() {
    log_info "테스트: 심볼릭 링크 생성 확인"

    local sourceFile="$DOTFILES_TEST/modules/shared/config/claude/settings.json"
    local targetFile="$CLAUDE_DIR/settings.json"

    # 심볼릭 링크 생성
    ln -sf "$sourceFile" "$targetFile"

    # 링크 검증
    if [[ -L "$targetFile" ]]; then
        log_info "✅ 심볼릭 링크 생성 성공"
        ((TESTS_PASSED++))

        # 링크 타겟 확인
        local linkTarget=$(readlink "$targetFile")
        if [[ "$linkTarget" == *"dev/dotfiles"* ]]; then
            log_info "✅ 심볼릭 링크가 dotfiles를 가리킴"
            ((TESTS_PASSED++))
        else
            log_error "❌ 심볼릭 링크가 잘못된 경로를 가리킴: $linkTarget"
            ((TESTS_FAILED++))
        fi
    else
        log_error "❌ 심볼릭 링크 생성 실패"
        ((TESTS_FAILED++))
    fi
}

# 파일 내용 확인 테스트
test_file_content_resolution() {
    log_info "테스트: 파일 내용 해석 확인"

    local targetFile="$CLAUDE_DIR/settings.json"

    if [[ -f "$targetFile" ]]; then
        # dotfiles의 내용이 나와야 함
        if grep -q '"source": "dotfiles"' "$targetFile"; then
            log_info "✅ dotfiles 설정 파일 내용 확인됨"
            ((TESTS_PASSED++))
        else
            log_error "❌ 잘못된 파일 내용: dotfiles 설정이 아님"
            ((TESTS_FAILED++))
            log_warning "실제 내용:"
            cat "$targetFile"
        fi

        # Nix store 내용이 나오면 안됨
        if ! grep -q '"source": "nix-store"' "$targetFile"; then
            log_info "✅ Nix store 설정이 사용되지 않음"
            ((TESTS_PASSED++))
        else
            log_error "❌ 잘못된 우선순위: Nix store 설정이 사용됨"
            ((TESTS_FAILED++))
        fi
    else
        log_error "❌ 타겟 파일이 존재하지 않음"
        ((TESTS_FAILED++))
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
        if [[ -d "$nixStoreSource" ]]; then
            log_info "✅ Nix store fallback 확인됨"
            ((TESTS_PASSED++))
        else
            log_error "❌ Nix store fallback 실패"
            ((TESTS_FAILED++))
        fi
    fi

    # 복원
    mv "$backupPath" "$dotfilesPath"
}

# 메인 테스트 실행
main() {
    log_info "Claude 심볼릭 링크 우선순위 테스트 시작"
    log_info "테스트 디렉토리: $TEST_DIR"

    # 테스트 환경 설정
    setup_test_environment

    # 테스트 실행
    test_source_directory_priority
    test_symlink_creation
    test_file_content_resolution
    test_nix_store_fallback

    # 테스트 환경 정리
    cleanup_test_environment

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
