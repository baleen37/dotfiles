#!/usr/bin/env bash

# User Resolution Unit Tests
# Tests the user resolution and home directory detection functionality

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_HOME="${TEST_HOME:-$(mktemp -d)}"

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test utilities
passed_tests=0
failed_tests=0

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_test_suite() { echo -e "${PURPLE}${BOLD}[TEST SUITE]${NC} $*"; }

assert_pass() {
    echo -e "${GREEN}✅${NC} $1"
    ((passed_tests++))
}

assert_fail() {
    echo -e "${RED}❌${NC} $1"
    echo -e "${RED}[ERROR]${NC}   $2"
    ((failed_tests++))
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        assert_pass "$description"
    else
        assert_fail "$description" "예상: '$expected', 실제: '$actual'"
    fi
}

assert_not_empty() {
    local value="$1"
    local description="$2"
    
    if [[ -n "$value" ]]; then
        assert_pass "$description"
    else
        assert_fail "$description" "값이 비어있음"
    fi
}

assert_directory_exists() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$dir" ]]; then
        assert_pass "$description"
    else
        assert_fail "$description" "디렉토리가 존재하지 않음: $dir"
    fi
}

# Test setup
setup_test_environment() {
    log_info "테스트 디렉토리: $TEST_HOME"
    log_info "프로젝트 루트: $PROJECT_ROOT"
    log_info "현재 사용자: $(whoami)"
    log_info "현재 홈 디렉토리: $HOME"
}

# Main tests
test_user_detection() {
    log_test_suite "사용자 탐지 테스트"
    
    # Test current user detection
    local current_user=$(whoami)
    assert_not_empty "$current_user" "현재 사용자 식별"
    
    # Test USER environment variable
    if [[ -n "${USER:-}" ]]; then
        assert_equals "$current_user" "$USER" "USER 환경변수 일치성"
    else
        log_warn "USER 환경변수가 설정되지 않음"
    fi
    
    # Test home directory detection
    assert_not_empty "$HOME" "HOME 환경변수 설정"
    assert_directory_exists "$HOME" "홈 디렉토리 존재"
}

test_home_manager_compatibility() {
    log_test_suite "Home Manager 호환성 테스트"
    
    # Test typical home-manager directory structure expectations
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    assert_not_empty "$config_home" "XDG_CONFIG_HOME 또는 기본값 설정"
    
    # Test data directory
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    assert_not_empty "$data_home" "XDG_DATA_HOME 또는 기본값 설정"
    
    # Test cache directory
    local cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
    assert_not_empty "$cache_home" "XDG_CACHE_HOME 또는 기본값 설정"
}

test_nix_environment() {
    log_test_suite "Nix 환경 테스트"
    
    # Test if running in Nix build environment
    if [[ -n "${NIX_BUILD_TOP:-}" ]]; then
        log_info "Nix 빌드 환경에서 실행 중"
        assert_not_empty "$NIX_BUILD_TOP" "NIX_BUILD_TOP 설정됨"
    else
        log_info "일반 사용자 환경에서 실행 중"
    fi
    
    # Test nix command availability
    if command -v nix >/dev/null 2>&1; then
        assert_pass "nix 명령어 사용 가능"
        
        # Test basic nix functionality
        local nix_version
        nix_version=$(nix --version 2>/dev/null | head -1)
        assert_not_empty "$nix_version" "nix 버전 확인 가능"
    else
        log_warn "nix 명령어를 찾을 수 없음"
    fi
}

test_permissions() {
    log_test_suite "권한 테스트"
    
    # Test home directory permissions
    if [[ -r "$HOME" ]]; then
        assert_pass "홈 디렉토리 읽기 권한"
    else
        assert_fail "홈 디렉토리 읽기 권한" "홈 디렉토리를 읽을 수 없음"
    fi
    
    if [[ -w "$HOME" ]]; then
        assert_pass "홈 디렉토리 쓰기 권한"
    else
        assert_fail "홈 디렉토리 쓰기 권한" "홈 디렉토리에 쓸 수 없음"
    fi
    
    # Test temporary directory creation
    local temp_test_dir
    temp_test_dir=$(mktemp -d)
    if [[ -d "$temp_test_dir" ]]; then
        assert_pass "임시 디렉토리 생성 가능"
        rm -rf "$temp_test_dir"
    else
        assert_fail "임시 디렉토리 생성 가능" "임시 디렉토리를 생성할 수 없음"
    fi
}

test_edge_cases() {
    log_test_suite "엣지 케이스 테스트"
    
    # Test with different USER values
    local original_user="$USER"
    
    # Test empty USER
    if USER="" whoami >/dev/null 2>&1; then
        assert_pass "USER 변수가 비어있어도 whoami 동작"
    else
        log_warn "USER 변수가 비어있으면 일부 기능이 작동하지 않을 수 있음"
    fi
    
    # Restore original USER
    export USER="$original_user"
    
    # Test path resolution
    local resolved_home
    resolved_home=$(eval echo "~")
    assert_equals "$HOME" "$resolved_home" "틸드 확장이 HOME과 일치"
}

test_makefile_compatibility() {
    log_test_suite "Makefile 호환성 테스트"
    
    # Test that the Makefile can detect USER properly
    cd "$PROJECT_ROOT"
    
    if [[ -f "Makefile" ]]; then
        # Test make variable detection
        local make_user
        make_user=$(make check-user 2>/dev/null | grep "USER is set to:" | cut -d: -f2 | xargs || echo "")
        
        if [[ -n "$make_user" ]]; then
            assert_equals "$(whoami)" "$make_user" "Makefile USER 탐지 일치성"
        else
            log_warn "Makefile에서 USER 변수를 탐지할 수 없음"
        fi
    else
        log_warn "Makefile을 찾을 수 없음"
    fi
}

test_performance() {
    log_test_suite "성능 테스트"
    
    # Test user resolution performance
    local start_time=$(date +%s%3N)
    
    for i in {1..10}; do
        whoami >/dev/null
    done
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    if [[ $duration -lt 100 ]]; then
        assert_pass "10회 사용자 탐지가 100ms 이내 완료 (${duration}ms)"
    else
        assert_fail "10회 사용자 탐지가 100ms 이내 완료" "예상: <100ms, 실제: ${duration}ms"
    fi
}

# Main execution
main() {
    log_test_suite "User Resolution 포괄적 테스트 시작"
    
    # Set up test environment
    setup_test_environment
    
    # Run test suites
    test_user_detection
    test_home_manager_compatibility
    test_nix_environment
    test_permissions
    test_edge_cases
    test_makefile_compatibility
    test_performance
    
    # Test summary
    echo ""
    log_test_suite "테스트 완료"
    log_info "통과: $passed_tests"
    if [[ $failed_tests -gt 0 ]]; then
        log_error "실패: $failed_tests"
        exit 1
    else
        log_info "모든 테스트 통과!"
        exit 0
    fi
}

# Cleanup on exit
cleanup() {
    if [[ -n "${TEST_HOME:-}" && "$TEST_HOME" != "/" ]]; then
        rm -rf "$TEST_HOME"
    fi
}
trap cleanup EXIT

# Run main function
main "$@"