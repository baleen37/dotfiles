#!/usr/bin/env bash
# Enhanced BATS Test Framework Helpers
# Provides utility functions for all test layers

# Set strict error handling
set -euo pipefail

# Test Framework Configuration
export TEST_TIMEOUT="${TEST_TIMEOUT:-300}"
export TEST_PARALLEL="${TEST_PARALLEL:-true}"
export DEBUG="${DEBUG:-false}"

# Colors for output (if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

# Test Utility Functions

# Assert that a command succeeds
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Expected success but got exit code $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Expected failure but command succeeded" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Assert that a command fails with specific exit code
assert_failure_with_code() {
    local expected_code="$1"
    if [[ "$status" -ne "$expected_code" ]]; then
        echo "Expected exit code $expected_code but got $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Assert that output contains a string
assert_output_contains() {
    local expected="$1"
    if ! echo "$output" | grep -q "$expected"; then
        echo "Output does not contain: $expected" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Assert that output matches a pattern
assert_output_matches() {
    local pattern="$1"
    if ! echo "$output" | grep -qE "$pattern"; then
        echo "Output does not match pattern: $pattern" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -e "$file" ]]; then
        echo "File does not exist: $file" >&2
        return 1
    fi
}

# Assert that a file does not exist
assert_file_not_exists() {
    local file="$1"
    if [[ -e "$file" ]]; then
        echo "File should not exist: $file" >&2
        return 1
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Directory does not exist: $dir" >&2
        return 1
    fi
}

# Assert that a command is available
assert_command_available() {
    local command="$1"
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Command not available: $command" >&2
        return 1
    fi
}

# Assert that a service is active (systemd)
assert_service_active() {
    local service="$1"
    if ! systemctl --user is-active "$service" >/dev/null 2>&1; then
        echo "Service is not active: $service" >&2
        return 1
    fi
}

# Assert that a service is inactive (systemd)
assert_service_inactive() {
    local service="$1"
    if systemctl --user is-active "$service" >/dev/null 2>&1; then
        echo "Service should not be active: $service" >&2
        return 1
    fi
}

# Assert that a port is open
assert_port_open() {
    local port="$1"
    local host="${2:-localhost}"
    
    if ! nc -z "$host" "$port" 2>/dev/null; then
        echo "Port $port is not open on $host" >&2
        return 1
    fi
}

# Wait for a condition to be true
wait_for() {
    local condition="$1"
    local timeout="${2:-30}"
    local interval="${3:-1}"
    
    local start_time
    start_time=$(date +%s)
    
    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [[ $elapsed -gt $timeout ]]; then
            echo "Timeout waiting for condition: $condition" >&2
            return 1
        fi
        
        if eval "$condition" 2>/dev/null; then
            return 0
        fi
        
        sleep "$interval"
    done
}

# Wait for a file to exist
wait_for_file() {
    local file="$1"
    local timeout="${2:-30}"
    wait_for "[[ -e '$file' ]]" "$timeout"
}

# Wait for a service to be active
wait_for_service() {
    local service="$1"
    local timeout="${2:-30}"
    wait_for "systemctl --user is-active '$service' >/dev/null 2>&1" "$timeout"
}

# Wait for a port to be open
wait_for_port() {
    local port="$1"
    local host="${2:-localhost}"
    local timeout="${3:-30}"
    wait_for "nc -z '$host' '$port' 2>/dev/null" "$timeout"
}

# Create a temporary directory
make_temp_dir() {
    mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX"
}

# Create a temporary file
make_temp_file() {
    mktemp "${TMPDIR:-/tmp}/bats_test.XXXXXX"
}

# Cleanup function for temporary resources
cleanup_temp() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    if [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

# Run a command with timeout
run_with_timeout() {
    local timeout="$1"
    shift
    local command=("$@")
    
    timeout "$timeout" "${command[@]}"
}

# Get current system information
get_system_info() {
    echo "System: $(uname -s)"
    echo "Architecture: $(uname -m)"
    echo "Platform: $(nix eval --impure --expr 'builtins.currentSystem' 2>/dev/null | tr -d '"' || echo 'unknown')"
    echo "Nix version: $(nix --version 2>/dev/null || echo 'not available')"
}

# Test setup helper
test_setup() {
    log_debug "Setting up test: ${BATS_TEST_DESCRIPTION:-unknown}"
    
    # Create temporary directory if needed
    if [[ "${USE_TEMP_DIR:-false}" == "true" ]]; then
        export TEMP_DIR
        TEMP_DIR=$(make_temp_dir)
        log_debug "Created temp directory: $TEMP_DIR"
    fi
    
    # Set test timeout
    if command -v timeout >/dev/null 2>&1; then
        export BATS_TEST_TIMEOUT="$TEST_TIMEOUT"
    fi
}

# Test teardown helper
test_teardown() {
    log_debug "Tearing down test: ${BATS_TEST_DESCRIPTION:-unknown}"
    
    # Cleanup temporary resources
    cleanup_temp
    
    # Log test result
    if [[ "${BATS_TEST_COMPLETED:-false}" == "true" ]]; then
        log_success "Test completed: ${BATS_TEST_DESCRIPTION:-unknown}"
    else
        log_error "Test failed: ${BATS_TEST_DESCRIPTION:-unknown}"
    fi
}

# Nix-specific helpers

# Build a nix expression and return the store path
nix_build() {
    local expr="$1"
    nix build --impure --no-link --print-out-paths --expr "$expr"
}

# Evaluate a nix expression and return the result
nix_eval() {
    local expr="$1"
    nix eval --impure --expr "$expr"
}

# Check if a nix expression evaluates successfully
nix_check() {
    local expr="$1"
    nix eval --impure --expr "$expr" >/dev/null 2>&1
}

# Get flake info
flake_info() {
    local flake="${1:-.}"
    nix flake metadata "$flake" --json 2>/dev/null | jq -r '.'
}

# Export all functions
export -f log_info log_warn log_error log_success log_debug
export -f assert_success assert_failure assert_failure_with_code
export -f assert_output_contains assert_output_matches
export -f assert_file_exists assert_file_not_exists assert_dir_exists
export -f assert_command_available assert_service_active assert_service_inactive
export -f assert_port_open wait_for wait_for_file wait_for_service wait_for_port
export -f make_temp_dir make_temp_file cleanup_temp run_with_timeout
export -f get_system_info test_setup test_teardown
export -f nix_build nix_eval nix_check flake_info