#!/usr/bin/env bash

# T028: Test assertions library
# Provides comprehensive assertion functions for test validation

set -euo pipefail

# Basic test functions (without sourcing common.bash to avoid conflicts)

test_pass() {
    local message="$1"
    echo -e "\033[0;32m✅\033[0m $message"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

test_fail() {
    local message="$1"
    local details="${2:-}"
    echo -e "\033[0;31m❌\033[0m $message"
    if [[ -n "$details" ]]; then
        echo -e "\033[0;31m[ERROR]\033[0m   $details"
    fi
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

# Basic equality assertions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        test_pass "${message:-Values match: '$actual'}"
    else
        test_fail "${message:-Values don't match}" "Expected: '$expected', Actual: '$actual'"
    fi
}

assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" != "$actual" ]]; then
        test_pass "${message:-Values differ: '$actual'}"
    else
        test_fail "${message:-Values are the same}" "Unexpected value: '$actual'"
    fi
}

# String assertions
assert_empty() {
    local value="$1"
    local message="${2:-}"

    if [[ -z "$value" ]]; then
        test_pass "${message:-String is empty}"
    else
        test_fail "${message:-String is not empty}" "Actual value: '$value'"
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-}"

    if [[ -n "$value" ]]; then
        test_pass "${message:-String is not empty}"
    else
        test_fail "${message:-String is empty}" "Value is empty"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "${message:-String contains: '$needle'}"
    else
        test_fail "${message:-String does not contain: '$needle'}" "Target string: '$haystack'"
    fi
}

# File and directory assertions
assert_file_exists() {
    local file="$1"
    local message="${2:-}"

    if [[ -f "$file" ]]; then
        test_pass "${message:-File exists: '$file'}"
    else
        test_fail "${message:-File does not exist: '$file'}"
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-}"

    if [[ -d "$dir" ]]; then
        test_pass "${message:-Directory exists: '$dir'}"
    else
        test_fail "${message:-Directory does not exist: '$dir'}"
    fi
}

assert_executable() {
    local file="$1"
    local message="${2:-}"

    if [[ -x "$file" ]]; then
        test_pass "${message:-File is executable: '$file'}"
    else
        test_fail "${message:-File is not executable: '$file'}"
    fi
}

# Command execution assertions
assert_command_succeeds() {
    local command="$1"
    local message="${2:-}"

    if eval "$command" >/dev/null 2>&1; then
        test_pass "${message:-Command succeeded: \"$command\"}"
    else
        test_fail "${message:-Command failed: \"$command\"}"
    fi
}

assert_command_fails() {
    local command="$1"
    local message="${2:-}"

    if ! eval "$command" >/dev/null 2>&1; then
        test_pass "${message:-Command failed as expected: \"$command\"}"
    else
        test_fail "${message:-Command succeeded: \"$command\"}"
    fi
}

# Performance assertions
assert_executes_in_time() {
    local max_time="$1"
    local command="$2"
    local message="${3:-}"

    local start_time=$(date +%s%3N)
    eval "$command" >/dev/null 2>&1
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    if [[ $duration -le $max_time ]]; then
        test_pass "${message:-Command executed in time: ${duration}ms <= ${max_time}ms}"
    else
        test_fail "${message:-Command took too long}" "Actual: ${duration}ms, Max: ${max_time}ms"
    fi
}
