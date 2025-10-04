#!/usr/bin/env bash
# Test Fixes Summary
# Demonstrates that all the unit test fixes work properly

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $1"; }
log_fail() { echo -e "${RED}❌${NC} $1"; }
log_header() { echo -e "${PURPLE}${BOLD}[TEST SUMMARY]${NC} $*"; }

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
  local test_name="$1"
  local test_script="$2"

  log_info "Running $test_name..."
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if timeout 30s "$test_script" >/dev/null 2>&1; then
    log_success "$test_name passed"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    log_fail "$test_name failed"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

main() {
  log_header "Testing All Fixed Unit Tests"
  echo ""

  # Change to project root
  cd "$(dirname "$0")/.."

  # Test environment detection
  local env_type="local"
  if [[ -n ${NIX_BUILD_TOP:-} ]] || [[ "$(whoami)" == "nixbld"* ]]; then
    env_type="nix-build"
  elif [[ ${CI:-false} == "true" ]]; then
    env_type="ci"
  fi

  log_info "Environment: $env_type"
  log_info "User: $(whoami)"
  log_info "Home: $HOME"
  echo ""

  # Run all fixed tests
  run_test "Platform System Test" "./tests/unit/test-platform-system.sh"
  run_test "User Resolution Test" "./tests/unit/test-user-resolution.sh"
  run_test "Error System Test" "./tests/unit/test-error-system.sh"

  # Summary
  echo ""
  log_header "Test Results Summary"
  log_info "Environment: $env_type"
  log_info "Total tests: $TOTAL_TESTS"
  log_info "Passed: $PASSED_TESTS"

  if [[ $FAILED_TESTS -gt 0 ]]; then
    log_error "Failed: $FAILED_TESTS"
    echo ""
    log_error "Some tests failed. The fixes need more work."
    exit 1
  else
    log_success "All tests passed!"
    echo ""
    log_info "✨ All unit test fixes are working correctly!"
    log_info "The tests now handle:"
    log_info "  • Nix build environments (nixbld user context)"
    log_info "  • Missing tools and commands (graceful degradation)"
    log_info "  • Emoji and formatting issues in different terminals"
    log_info "  • CI environment constraints"
    log_info "  • Timeout handling for slow Nix evaluations"
    exit 0
  fi
}

main "$@"
