#!/usr/bin/env bash

# T027: Common test utilities
# Provides shared functionality for all test scripts

set -euo pipefail

# Color constants (only set if not already defined)
if [[ -z ${RED:-} ]]; then readonly RED='\033[0;31m'; fi
if [[ -z ${GREEN:-} ]]; then readonly GREEN='\033[0;32m'; fi
if [[ -z ${YELLOW:-} ]]; then readonly YELLOW='\033[1;33m'; fi
if [[ -z ${BLUE:-} ]]; then readonly BLUE='\033[0;34m'; fi
if [[ -z ${PURPLE:-} ]]; then readonly PURPLE='\033[0;35m'; fi
if [[ -z ${BOLD:-} ]]; then readonly BOLD='\033[1m'; fi
if [[ -z ${NC:-} ]]; then readonly NC='\033[0m'; fi

# Test state variables
declare -g TESTS_TOTAL=0
declare -g TESTS_PASSED=0
declare -g TESTS_FAILED=0
declare -g TESTS_SKIPPED=0

# Current test context
declare -g CURRENT_TEST_SUITE=""
declare -g CURRENT_TEST_NAME=""
declare -g TEST_START_TIME=""

# Test configuration
declare -g TEST_VERBOSE=${TEST_VERBOSE:-false}
declare -g TEST_PARALLEL=${TEST_PARALLEL:-true}

# Common test setup function to reduce duplication
common_test_setup() {
  local test_name="${1:-${BATS_TEST_NAME:-unknown}}"
  local test_dirname="${2:-${BATS_TEST_DIRNAME:-/tmp}}"

  # Create unique temporary test directory
  export TEST_TEMP_DIR="${BATS_TMPDIR}/$(basename "$test_name")_$$"
  mkdir -p "$TEST_TEMP_DIR"

  # Set up standard test environment variables
  export BATS_TEST_NAME="${test_name}"
  export BATS_TEST_DIRNAME="${test_dirname}"

  # Initialize test start time for performance tracking
  export TEST_START_TIME=$(date +%s.%N)

  test_debug "Common setup completed for test: $test_name"
}

# Common test teardown function to reduce duplication
common_test_teardown() {
  # Calculate test duration
  if [[ -n ${TEST_START_TIME:-} ]]; then
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $TEST_START_TIME" | bc -l 2>/dev/null || echo "0")
    test_debug "Test duration: ${duration}s"
  fi

  # Clean up temporary test directory
  if [[ -d ${TEST_TEMP_DIR:-} ]]; then
    rm -rf "$TEST_TEMP_DIR"
    test_debug "Cleaned up test directory: $TEST_TEMP_DIR"
  fi

  # Clean up any test-specific environment variables
  unset TEST_TEMP_DIR TEST_START_TIME
}
declare -g TEST_TIMEOUT=${TEST_TIMEOUT:-30}

# Logging functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_debug() {
  if [[ $TEST_VERBOSE == "true" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*"
  fi
}

log_test_suite() {
  echo -e "${PURPLE}${BOLD}[TEST SUITE]${NC} $*"
}

# Test lifecycle functions
test_suite_start() {
  local suite_name="$1"
  CURRENT_TEST_SUITE="$suite_name"
  log_test_suite "$suite_name 시작"
}

test_suite_end() {
  local suite_name="${1:-$CURRENT_TEST_SUITE}"
  log_test_suite "$suite_name 완료"
  CURRENT_TEST_SUITE=""
}

test_start() {
  local test_name="$1"
  CURRENT_TEST_NAME="$test_name"
  TEST_START_TIME=$(date +%s%3N)
  log_debug "테스트 시작: $test_name"
}

test_end() {
  local test_name="${1:-$CURRENT_TEST_NAME}"
  local end_time=$(date +%s%3N)
  local duration=$((end_time - TEST_START_TIME))
  log_debug "테스트 완료: $test_name (${duration}ms)"
  CURRENT_TEST_NAME=""
  TEST_START_TIME=""
}

# Test result tracking
test_pass() {
  local message="$1"
  echo -e "${GREEN}✅${NC} $message"
  ((TESTS_PASSED++))
  ((TESTS_TOTAL++))
}

test_fail() {
  local message="$1"
  local details="${2:-}"
  echo -e "${RED}❌${NC} $message"
  if [[ -n $details ]]; then
    echo -e "${RED}[ERROR]${NC}   $details"
  fi
  ((TESTS_FAILED++))
  ((TESTS_TOTAL++))
}

test_skip() {
  local message="$1"
  local reason="${2:-}"
  echo -e "${YELLOW}⏭️${NC} $message"
  if [[ -n $reason ]]; then
    echo -e "${YELLOW}[SKIP]${NC}   $reason"
  fi
  ((TESTS_SKIPPED++))
  ((TESTS_TOTAL++))
}

# Test summary
test_summary() {
  echo ""
  log_test_suite "테스트 완료"
  log_info "총 테스트: $TESTS_TOTAL"
  log_info "통과: $TESTS_PASSED"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    log_error "실패: $TESTS_FAILED"
  fi

  if [[ $TESTS_SKIPPED -gt 0 ]]; then
    log_warn "스킵: $TESTS_SKIPPED"
  fi

  # Return appropriate exit code
  if [[ $TESTS_FAILED -gt 0 ]]; then
    return 1
  else
    return 0
  fi
}

# Environment utilities
get_project_root() {
  # Find project root by looking for flake.nix
  local dir="$PWD"
  while [[ $dir != "/" ]]; do
    if [[ -f "$dir/flake.nix" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  echo "Error: Could not find project root (no flake.nix found)" >&2
  return 1
}

get_temp_dir() {
  local temp_dir
  temp_dir=$(mktemp -d)
  echo "$temp_dir"
}

cleanup_temp_dir() {
  local temp_dir="$1"
  if [[ -n $temp_dir && $temp_dir != "/" && -d $temp_dir ]]; then
    rm -rf "$temp_dir"
  fi
}

# File utilities
file_exists() {
  [[ -f $1 ]]
}

dir_exists() {
  [[ -d $1 ]]
}

is_executable() {
  [[ -x $1 ]]
}

# String utilities
is_empty() {
  [[ -z $1 ]]
}

is_not_empty() {
  [[ -n $1 ]]
}

contains() {
  local string="$1"
  local substring="$2"
  [[ $string == *"$substring"* ]]
}

# Process utilities
is_running() {
  local process_name="$1"
  pgrep -f "$process_name" >/dev/null 2>&1
}

wait_for_process() {
  local process_name="$1"
  local timeout="${2:-10}"
  local count=0

  while ! is_running "$process_name" && [[ $count -lt $timeout ]]; do
    sleep 1
    ((count++))
  done

  [[ $count -lt $timeout ]]
}

# Network utilities
is_port_open() {
  local host="${1:-localhost}"
  local port="$2"
  timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null
}

wait_for_port() {
  local host="${1:-localhost}"
  local port="$2"
  local timeout="${3:-10}"
  local count=0

  while ! is_port_open "$host" "$port" && [[ $count -lt $timeout ]]; do
    sleep 1
    ((count++))
  done

  [[ $count -lt $timeout ]]
}

# Platform utilities
is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

get_arch() {
  uname -m
}

# Test execution utilities
run_with_timeout() {
  local timeout="$1"
  shift
  timeout "$timeout" "$@"
}

retry() {
  local times="$1"
  local delay="${2:-1}"
  shift 2

  local count=0
  while [[ $count -lt $times ]]; do
    if "$@"; then
      return 0
    fi

    ((count++))
    if [[ $count -lt $times ]]; then
      sleep "$delay"
    fi
  done

  return 1
}

# Performance utilities
measure_time() {
  local start_time=$(date +%s%3N)
  "$@"
  local exit_code=$?
  local end_time=$(date +%s%3N)
  local duration=$((end_time - start_time))
  echo "$duration"
  return $exit_code
}

# Environment validation
validate_environment() {
  local required_commands=("bash" "nix" "git")
  local missing_commands=()

  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_commands+=("$cmd")
    fi
  done

  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing_commands[*]}"
    return 1
  fi

  return 0
}

# Test data utilities
generate_test_data() {
  local type="$1"
  local size="${2:-small}"

  case "$type" in
  "string")
    case "$size" in
    "small") echo "test_string" ;;
    "medium") head -c 100 </dev/urandom | base64 | tr -d '\n' ;;
    "large") head -c 1000 </dev/urandom | base64 | tr -d '\n' ;;
    esac
    ;;
  "number")
    case "$size" in
    "small") echo "42" ;;
    "medium") echo "1234567890" ;;
    "large") echo "123456789012345" ;;
    esac
    ;;
  "file")
    local temp_file
    temp_file=$(mktemp)
    case "$size" in
    "small") echo "test content" >"$temp_file" ;;
    "medium") head -c 1024 </dev/urandom >"$temp_file" ;;
    "large") head -c 10240 </dev/urandom >"$temp_file" ;;
    esac
    echo "$temp_file"
    ;;
  esac
}

# Error handling
handle_error() {
  local exit_code=$?
  local line_number="$1"
  local bash_lineno="$2"
  local last_command="$3"

  log_error "Error occurred in test:"
  log_error "  Line: $line_number"
  log_error "  Bash line: $bash_lineno"
  log_error "  Command: $last_command"
  log_error "  Exit code: $exit_code"

  exit $exit_code
}

# Set up error handling
trap 'handle_error ${LINENO} $BASH_LINENO "$BASH_COMMAND"' ERR

# Functions exported automatically when sourced
