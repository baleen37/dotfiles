#!/bin/bash
# Unit test for logging.sh file availability in build-switch process

set -e

# Test configuration
TEST_NAME="Logging Module Availability Test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for test output
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_pass() {
  echo -e "${GREEN}✅ PASS: $1${NC}"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}❌ FAIL: $1${NC}"
  ((TESTS_FAILED++))
}

test_info() {
  echo -e "${YELLOW}ℹ️  INFO: $1${NC}"
}

# Test 1: Check if logging.sh exists in scripts/lib
test_logging_exists_in_scripts_lib() {
  local logging_path="$PROJECT_ROOT/scripts/lib/logging.sh"

  if [ -f "$logging_path" ]; then
    test_pass "logging.sh exists in scripts/lib directory"
  else
    test_fail "logging.sh missing from scripts/lib directory"
  fi
}

# Test 2: Check if logging.sh should exist in apps/aarch64-darwin/lib
test_logging_should_exist_in_apps_lib() {
  local expected_path="$PROJECT_ROOT/apps/aarch64-darwin/lib/logging.sh"

  if [ -f "$expected_path" ]; then
    test_pass "logging.sh exists in apps/aarch64-darwin/lib directory"
  else
    test_fail "logging.sh missing from apps/aarch64-darwin/lib directory (expected by build-switch-common.sh)"
  fi
}

# Test 3: Check if build-switch-common.sh references correct path
test_build_switch_common_references() {
  local common_script="$PROJECT_ROOT/scripts/build-switch-common.sh"

  if [ -f "$common_script" ]; then
    if grep -q 'LIB_DIR/logging.sh' "$common_script"; then
      test_pass "build-switch-common.sh references logging.sh correctly"
    else
      test_fail "build-switch-common.sh does not reference logging.sh"
    fi
  else
    test_fail "build-switch-common.sh not found"
  fi
}

# Test 4: Check if apps/aarch64-darwin/lib directory exists
test_apps_lib_directory_exists() {
  local lib_dir="$PROJECT_ROOT/apps/aarch64-darwin/lib"

  if [ -d "$lib_dir" ]; then
    test_pass "apps/aarch64-darwin/lib directory exists"
  else
    test_fail "apps/aarch64-darwin/lib directory does not exist"
  fi
}

# Test 5: Simulate build-switch-common.sh execution to verify loading
test_simulate_logging_load() {
  local common_script="$PROJECT_ROOT/scripts/build-switch-common.sh"

  # Create temporary test environment
  local temp_dir=$(mktemp -d)
  local temp_script="$temp_dir/test-logging-load.sh"

  # Create test script that mimics build-switch-common.sh logging load
  cat >"$temp_script" <<'EOF'
#!/bin/sh -e
SCRIPT_DIR="$(dirname "$0")"
LIB_DIR="$SCRIPT_DIR/lib"

# Try to load logging.sh
if [ -f "$LIB_DIR/logging.sh" ]; then
    . "$LIB_DIR/logging.sh"
    echo "SUCCESS: logging.sh loaded successfully"
    exit 0
else
    echo "ERROR: logging.sh not found at $LIB_DIR/logging.sh"
    exit 1
fi
EOF

  chmod +x "$temp_script"

  # Test from apps/aarch64-darwin context
  local test_dir="$PROJECT_ROOT/apps/aarch64-darwin"
  cd "$test_dir"

  if bash -c "SCRIPT_DIR='$test_dir' $temp_script" 2>/dev/null; then
    test_pass "logging.sh can be loaded from apps/aarch64-darwin context"
  else
    test_fail "logging.sh cannot be loaded from apps/aarch64-darwin context"
  fi

  # Cleanup
  rm -rf "$temp_dir"
  cd "$PROJECT_ROOT"
}

# Run all tests
echo "Running $TEST_NAME"
echo "=================================="

test_logging_exists_in_scripts_lib
test_logging_should_exist_in_apps_lib
test_build_switch_common_references
test_apps_lib_directory_exists
test_simulate_logging_load

echo ""
echo "=================================="
echo "Test Summary:"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi
