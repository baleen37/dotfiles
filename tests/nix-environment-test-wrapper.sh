#!/usr/bin/env bash
# Nix Environment Test Wrapper
# Wraps unit tests to work properly in Nix build environments (CI and local builds)

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test state
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $1"; }
log_fail() { echo -e "${RED}❌${NC} $1"; }
log_skip() { echo -e "${YELLOW}⏭️${NC} $1"; }
log_header() { echo -e "${PURPLE}${BOLD}[TEST SUITE]${NC} $*"; }

# Detect environment type
detect_environment() {
    local env_type="unknown"
    
    if [[ -n "${NIX_BUILD_TOP:-}" ]]; then
        env_type="nix-build"
    elif [[ "$(whoami)" == "nixbld"* ]]; then
        env_type="nixbld"
    elif [[ -n "${IN_NIX_SHELL:-}" ]]; then
        env_type="nix-shell"
    elif [[ "${CI:-false}" == "true" ]] || [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
        env_type="ci"
    else
        env_type="local"
    fi
    
    echo "$env_type"
}

# Check tool availability
check_tool() {
    local tool="$1"
    local required="${2:-false}"
    
    if command -v "$tool" >/dev/null 2>&1; then
        log_info "$tool: available"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            log_error "$tool: required but not available"
            return 1
        else
            log_warn "$tool: not available (tests will be skipped)"
            return 1
        fi
    fi
}

# Environment-specific test configuration
configure_test_environment() {
    local env_type="$1"
    
    # Set environment variables for test adaptation
    export TEST_ENVIRONMENT="$env_type"
    export NIX_ENVIRONMENT_DETECTED="true"
    
    case "$env_type" in
        "nix-build"|"nixbld")
            export TEST_MODE="nix-build"
            export USER_RESOLUTION_STRICT="false"
            export EMOJI_SUPPORT="false"
            export NIX_EVAL_TIMEOUT="30"
            log_info "Configured for Nix build environment"
            ;;
        "nix-shell")
            export TEST_MODE="nix-shell"
            export USER_RESOLUTION_STRICT="false"
            export EMOJI_SUPPORT="true"
            export NIX_EVAL_TIMEOUT="15"
            log_info "Configured for Nix shell environment"
            ;;
        "ci")
            export TEST_MODE="ci"
            export USER_RESOLUTION_STRICT="false"
            export EMOJI_SUPPORT="false"
            export NIX_EVAL_TIMEOUT="20"
            log_info "Configured for CI environment"
            ;;
        "local")
            export TEST_MODE="local"
            export USER_RESOLUTION_STRICT="true"
            export EMOJI_SUPPORT="true"
            export NIX_EVAL_TIMEOUT="10"
            log_info "Configured for local development environment"
            ;;
        *)
            log_warn "Unknown environment type: $env_type, using default configuration"
            export TEST_MODE="default"
            export USER_RESOLUTION_STRICT="false"
            export EMOJI_SUPPORT="false"
            export NIX_EVAL_TIMEOUT="30"
            ;;
    esac
}

# Run a single test with environment-specific adaptations
run_test() {
    local test_script="$1"
    local test_path="$SCRIPT_DIR/$test_script"
    local test_name=$(basename "$test_script" .sh)
    
    log_header "Running $test_name"
    
    if [[ ! -f "$test_path" ]]; then
        log_error "Test script not found: $test_path"
        ((TESTS_FAILED++))
        return 1
    fi
    
    if [[ ! -x "$test_path" ]]; then
        chmod +x "$test_path"
    fi
    
    # Set up test-specific environment
    local test_home
    test_home=$(mktemp -d)
    export TEST_HOME="$test_home"
    
    # Run the test with timeout
    local exit_code=0
    local timeout_duration="${NIX_EVAL_TIMEOUT:-30}s"
    
    if timeout "$timeout_duration" bash "$test_path"; then
        log_success "$test_name passed"
        ((TESTS_PASSED++))
    else
        exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_fail "$test_name timed out (${timeout_duration})"
        else
            log_fail "$test_name failed (exit code: $exit_code)"
        fi
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    if [[ -n "$test_home" && -d "$test_home" ]]; then
        rm -rf "$test_home"
    fi
    
    return $exit_code
}

# Main test runner
main() {
    log_header "Nix Environment Test Wrapper"
    
    # Detect and configure environment
    local env_type
    env_type=$(detect_environment)
    log_info "Environment detected: $env_type"
    
    configure_test_environment "$env_type"
    
    # Check tool availability
    log_header "Tool Availability Check"
    local tools_available=true
    
    if ! check_tool "bash" true; then
        tools_available=false
    fi
    
    check_tool "nix" false
    check_tool "jq" false
    check_tool "make" false
    
    if [[ "$tools_available" != "true" ]]; then
        log_error "Required tools not available, aborting tests"
        exit 1
    fi
    
    # List of tests to run (relative to tests directory)
    local test_scripts=(
        "unit/test-platform-system.sh"
        "unit/test-user-resolution.sh" 
        "unit/test-error-system.sh"
    )
    
    log_header "Running Unit Tests"
    log_info "Total tests to run: ${#test_scripts[@]}"
    
    # Change to project root for nix commands
    cd "$PROJECT_ROOT"
    
    # Run each test
    for test_script in "${test_scripts[@]}"; do
        run_test "$test_script"
    done
    
    # Summary
    echo ""
    log_header "Test Results Summary"
    log_info "Environment: $env_type"
    log_info "Passed: $TESTS_PASSED"
    log_info "Failed: $TESTS_FAILED"
    log_info "Skipped: $TESTS_SKIPPED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Some tests failed"
        exit 1
    else
        log_success "All tests passed!"
        exit 0
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi