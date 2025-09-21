#!/usr/bin/env bash

# Platform System Unit Tests
# Tests the platform detection and system identification functionality

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

assert_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        assert_pass "$description"
    else
        assert_fail "$description" "파일이 존재하지 않음: $file"
    fi
}

# Test setup
setup_test_environment() {
    log_info "테스트 디렉토리: $TEST_HOME"
    log_info "프로젝트 루트: $PROJECT_ROOT"
    
    # Ensure the platform-system.nix file exists
    assert_file_exists "$PROJECT_ROOT/lib/platform-system.nix" "platform-system.nix 파일 존재 확인"
}

# Main tests
test_platform_detection() {
    log_test_suite "Platform Detection 테스트"
    
    # Test current system detection
    local current_system
    current_system=$(nix eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).system' --raw 2>/dev/null || echo "")
    assert_not_empty "$current_system" "현재 시스템 식별"
    
    # Test platform detection
    local current_platform
    current_platform=$(nix eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).platform' --raw 2>/dev/null || echo "")
    assert_not_empty "$current_platform" "현재 플랫폼 식별"
    
    # Test architecture detection
    local current_arch
    current_arch=$(nix eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).arch' --raw 2>/dev/null || echo "")
    assert_not_empty "$current_arch" "현재 아키텍처 식별"
}

test_supported_platforms() {
    log_test_suite "지원 플랫폼 테스트"
    
    # Test known system mappings
    local test_systems=(
        "x86_64-linux:linux:x86_64"
        "aarch64-linux:linux:aarch64"
        "x86_64-darwin:darwin:x86_64"
        "aarch64-darwin:darwin:aarch64"
    )
    
    for test_case in "${test_systems[@]}"; do
        IFS=':' read -r system expected_platform expected_arch <<< "$test_case"
        
        local actual_platform
        actual_platform=$(nix eval --expr "(import ./lib/platform-system.nix { system = \"$system\"; }).platform" --raw 2>/dev/null || echo "")
        assert_equals "$expected_platform" "$actual_platform" "$system 플랫폼 매핑"
        
        local actual_arch
        actual_arch=$(nix eval --expr "(import ./lib/platform-system.nix { system = \"$system\"; }).arch" --raw 2>/dev/null || echo "")
        assert_equals "$expected_arch" "$actual_arch" "$system 아키텍처 매핑"
    done
}

test_platform_utilities() {
    log_test_suite "플랫폼 유틸리티 함수 테스트"
    
    # Test isDarwin function
    local is_darwin_linux
    is_darwin_linux=$(nix eval --expr "(import ./lib/platform-system.nix { system = \"x86_64-linux\"; }).isDarwin" 2>/dev/null || echo "false")
    assert_equals "false" "$is_darwin_linux" "Linux에서 isDarwin false"
    
    local is_darwin_macos
    is_darwin_macos=$(nix eval --expr "(import ./lib/platform-system.nix { system = \"x86_64-darwin\"; }).isDarwin" 2>/dev/null || echo "false")
    assert_equals "true" "$is_darwin_macos" "macOS에서 isDarwin true"
    
    # Test isLinux function  
    local is_linux_linux
    is_linux_linux=$(nix eval --expr "(import ./lib/platform-system.nix { system = \"x86_64-linux\"; }).isLinux" 2>/dev/null || echo "false")
    assert_equals "true" "$is_linux_linux" "Linux에서 isLinux true"
    
    local is_linux_macos
    is_linux_macos=$(nix eval --expr "(import ./lib/platform-system.nix { system = \"x86_64-darwin\"; }).isLinux" 2>/dev/null || echo "true")
    assert_equals "false" "$is_linux_macos" "macOS에서 isLinux false"
}

test_performance() {
    log_test_suite "성능 테스트"
    
    # Test evaluation performance (should be fast since it's pure evaluation)
    local start_time=$(date +%s%3N)
    
    for i in {1..5}; do
        nix eval --expr "(import ./lib/platform-system.nix { system = builtins.currentSystem; }).platform" --raw >/dev/null 2>&1
    done
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    if [[ $duration -lt 1000 ]]; then
        assert_pass "5회 평가가 1초 이내 완료 (${duration}ms)"
    else
        assert_fail "5회 평가가 1초 이내 완료" "예상: <1000ms, 실제: ${duration}ms"
    fi
}

# Main execution
main() {
    log_test_suite "Platform System 포괄적 테스트 시작"
    
    # Set up test environment
    setup_test_environment
    
    # Change to project root for nix commands
    cd "$PROJECT_ROOT"
    
    # Run test suites
    test_platform_detection
    test_supported_platforms
    test_platform_utilities
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