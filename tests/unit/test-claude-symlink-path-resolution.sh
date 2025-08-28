#!/usr/bin/env bash
# Unit test for Claude configuration symlink path resolution
# Tests the claude-activation.nix script's path resolution logic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_HOME_DIR="/tmp/test-claude-symlink-$$"
TEST_DOTFILES_DIR="$TEST_HOME_DIR/dev/dotfiles"
WRONG_DOTFILES_DIR="$TEST_HOME_DIR/dotfiles"  # This should NOT be used

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

print_test_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

print_test_result() {
    if [ "$1" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

setup_test_environment() {
    print_test_header "Setting up test environment"

    # Clean up any existing test directory
    rm -rf "$TEST_HOME_DIR"

    # Create test directory structure
    mkdir -p "$TEST_DOTFILES_DIR/modules/shared/config/claude/commands"
    mkdir -p "$WRONG_DOTFILES_DIR/modules/shared/config/claude/commands"
    mkdir -p "$TEST_HOME_DIR/.claude"

    # Create test files in correct location
    echo "correct-location-file" > "$TEST_DOTFILES_DIR/modules/shared/config/claude/commands/test-command.md"

    # Create test files in wrong location (should not be used)
    echo "wrong-location-file" > "$WRONG_DOTFILES_DIR/modules/shared/config/claude/commands/test-command.md"

    echo "Test environment created at: $TEST_HOME_DIR"
}

test_path_resolution_logic() {
    print_test_header "Testing path resolution logic"

    # Simulate the current faulty logic from claude-activation.nix
    local home_dir="$TEST_HOME_DIR"
    local source_dir="$home_dir/dotfiles/modules/shared/config/claude"  # Wrong path
    local fallback_sources=(
        "$home_dir/dev/dotfiles/modules/shared/config/claude"  # Correct path
    )

    local actual_source_dir=""

    # Test current faulty logic - checks directory existence but uses wrong path
    if [[ -d "$source_dir" ]]; then
        actual_source_dir="$source_dir"
        print_test_result "FAIL" "Current logic incorrectly uses wrong path: $source_dir"
    else
        for fallback_dir in "${fallback_sources[@]}"; do
            if [[ -d "$fallback_dir" ]]; then
                actual_source_dir="$fallback_dir"
                print_test_result "PASS" "Fallback logic would find correct path: $fallback_dir"
                break
            fi
        done
    fi

    # Test what happens when we create symlink with wrong path
    if [[ -n "$actual_source_dir" ]]; then
        local test_symlink="$TEST_HOME_DIR/.claude/commands"
        ln -sf "$actual_source_dir/commands" "$test_symlink"

        # Check if symlink points to correct location
        local link_target=$(readlink "$test_symlink")
        if [[ "$link_target" == "$TEST_DOTFILES_DIR/modules/shared/config/claude/commands" ]]; then
            print_test_result "PASS" "Symlink points to correct location"
        else
            print_test_result "FAIL" "Symlink points to wrong location: $link_target"
        fi
    fi
}

test_file_accessibility() {
    print_test_header "Testing file accessibility through symlinks"

    local test_symlink="$TEST_HOME_DIR/.claude/commands"

    if [[ -L "$test_symlink" ]]; then
        # Test if we can access files through the symlink
        if [[ -f "$test_symlink/test-command.md" ]]; then
            local file_content=$(cat "$test_symlink/test-command.md")
            if [[ "$file_content" == "correct-location-file" ]]; then
                print_test_result "PASS" "File accessible through symlink with correct content"
            else
                print_test_result "FAIL" "File contains wrong content: $file_content"
            fi
        else
            print_test_result "FAIL" "File not accessible through symlink"
        fi
    else
        print_test_result "FAIL" "Symlink not created"
    fi
}

cleanup_test_environment() {
    print_test_header "Cleaning up test environment"
    rm -rf "$TEST_HOME_DIR"
    echo "Test environment cleaned up"
}

print_test_summary() {
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "\n${RED}Tests failed - Claude path resolution needs improvement${NC}"
        exit 1
    else
        echo -e "\n${GREEN}All tests passed - Claude path resolution is working correctly${NC}"
        exit 0
    fi
}

main() {
    echo -e "${YELLOW}Claude Symlink Path Resolution Test${NC}"
    echo "This test reproduces the current path resolution issue"

    setup_test_environment
    test_path_resolution_logic
    test_file_accessibility
    cleanup_test_environment
    print_test_summary
}

# Run tests only if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
