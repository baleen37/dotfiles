#!/bin/bash

# Test script for cc (Claude CLI) command

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    echo -n "Testing: $test_name ... "

    # Run command and capture output
    output=$(eval "$test_command" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        if echo "$output" | grep -qE "$expected_pattern"; then
            echo -e "${GREEN}✓ PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  Expected pattern: $expected_pattern"
            echo "  Got: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if [ "$expected_pattern" = "SHOULD_FAIL" ]; then
            echo -e "${GREEN}✓ PASSED${NC} (Expected failure)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  Command failed with exit code $exit_code"
            echo "  Output: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

echo "================================"
echo "Testing cc (Claude CLI) Command"
echo "================================"
echo

# Test 1: Check if cc command exists
run_test "cc command exists" "which cc" "/cc$"

# Test 2: Check if cc is in PATH
run_test "cc is in user's local bin" "which cc" "/.local/bin/cc"

# Test 3: Check cc version
run_test "cc shows Claude version" "cc --version" "Claude Code"

# Test 4: Check that cc is executable
run_test "cc is executable" "test -x \$HOME/.local/bin/cc && echo 'executable'" "executable"

# Test 5: Check script content
run_test "cc script contains claude command" "grep 'claude' \$HOME/.local/bin/cc" "claude"

# Test 6: Verify it's not the C compiler
run_test "cc is not C compiler" "cc --version | grep -v gcc | grep -v GNU" "Claude"

# Test 7: Check if original cc is still accessible
run_test "original cc still accessible" "/usr/bin/cc --version" "(gcc|GNU|Ubuntu)"

# Test 8: Test cc with help flag
run_test "cc help flag works" "cc --help 2>&1" "(Claude|claude|Usage)"

# Test 9: Verify PATH order
run_test "PATH has .local/bin" "echo \$PATH | grep '.local/bin'" "\.local/bin"

# Test 10: Check bashrc integration
run_test "bashrc has PATH setup" "grep '.local/bin' ~/.bashrc" "\.local/bin"

# Test 11: Test that cc script is a bash script
run_test "cc is a bash script" "head -1 \$HOME/.local/bin/cc" "#!/bin/bash"

# Test 12: Test cc can be executed from different directory
run_test "cc works from different directory" "cd /tmp && cc --version" "Claude Code"

echo
echo "================================"
echo "Test Results Summary"
echo "================================"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
