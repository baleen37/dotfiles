#!/usr/bin/env bash
# T013: TestSuite model - represents a collection of test files and their execution state
# Provides functionality for managing test suite lifecycle and metadata

set -euo pipefail

# TestSuite class implementation
declare -A TEST_SUITE_INSTANCES=()

# TestSuite constructor
# Usage: test_suite_new <suite_name> <base_path>
test_suite_new() {
    local suite_name="$1"
    local base_path="$2"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    [[ -n "$base_path" ]] || { echo "Error: base_path is required"; return 1; }
    [[ -d "$base_path" ]] || { echo "Error: base_path '$base_path' does not exist"; return 1; }
    
    # Initialize suite instance
    TEST_SUITE_INSTANCES["${suite_name}:name"]="$suite_name"
    TEST_SUITE_INSTANCES["${suite_name}:base_path"]="$base_path"
    TEST_SUITE_INSTANCES["${suite_name}:created_at"]="$(date -Iseconds)"
    TEST_SUITE_INSTANCES["${suite_name}:status"]="created"
    TEST_SUITE_INSTANCES["${suite_name}:test_files"]=""
    TEST_SUITE_INSTANCES["${suite_name}:total_tests"]="0"
    TEST_SUITE_INSTANCES["${suite_name}:passed_tests"]="0"
    TEST_SUITE_INSTANCES["${suite_name}:failed_tests"]="0"
    TEST_SUITE_INSTANCES["${suite_name}:skipped_tests"]="0"
    TEST_SUITE_INSTANCES["${suite_name}:execution_time"]="0"
    TEST_SUITE_INSTANCES["${suite_name}:parallel_enabled"]="false"
    TEST_SUITE_INSTANCES["${suite_name}:coverage_threshold"]="80"
    
    echo "$suite_name"
}

# Get suite property
# Usage: test_suite_get <suite_name> <property>
test_suite_get() {
    local suite_name="$1"
    local property="$2"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    [[ -n "$property" ]] || { echo "Error: property is required"; return 1; }
    
    local key="${suite_name}:${property}"
    echo "${TEST_SUITE_INSTANCES[$key]:-}"
}

# Set suite property
# Usage: test_suite_set <suite_name> <property> <value>
test_suite_set() {
    local suite_name="$1"
    local property="$2"
    local value="$3"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    [[ -n "$property" ]] || { echo "Error: property is required"; return 1; }
    
    local key="${suite_name}:${property}"
    TEST_SUITE_INSTANCES["$key"]="$value"
}

# Add test file to suite
# Usage: test_suite_add_file <suite_name> <test_file_path>
test_suite_add_file() {
    local suite_name="$1"
    local test_file_path="$2"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    [[ -n "$test_file_path" ]] || { echo "Error: test_file_path is required"; return 1; }
    [[ -f "$test_file_path" ]] || { echo "Error: test file '$test_file_path' does not exist"; return 1; }
    
    local current_files
    current_files=$(test_suite_get "$suite_name" "test_files")
    
    if [[ -n "$current_files" ]]; then
        test_suite_set "$suite_name" "test_files" "$current_files:$test_file_path"
    else
        test_suite_set "$suite_name" "test_files" "$test_file_path"
    fi
}

# Get all test files in suite
# Usage: test_suite_get_files <suite_name>
test_suite_get_files() {
    local suite_name="$1"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    
    local files
    files=$(test_suite_get "$suite_name" "test_files")
    
    if [[ -n "$files" ]]; then
        echo "$files" | tr ':' '\n'
    fi
}

# Discover test files in suite base path
# Usage: test_suite_discover <suite_name> [pattern]
test_suite_discover() {
    local suite_name="$1"
    local pattern="${2:-*.bats}"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    
    local base_path
    base_path=$(test_suite_get "$suite_name" "base_path")
    
    # Find test files matching pattern
    while IFS= read -r -d '' test_file; do
        test_suite_add_file "$suite_name" "$test_file"
    done < <(find "$base_path" -name "$pattern" -type f -print0 2>/dev/null)
}

# Update test statistics
# Usage: test_suite_update_stats <suite_name> <total> <passed> <failed> <skipped> <execution_time>
test_suite_update_stats() {
    local suite_name="$1"
    local total="$2"
    local passed="$3"
    local failed="$4"
    local skipped="$5"
    local execution_time="$6"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    [[ "$total" =~ ^[0-9]+$ ]] || { echo "Error: total must be a number"; return 1; }
    [[ "$passed" =~ ^[0-9]+$ ]] || { echo "Error: passed must be a number"; return 1; }
    [[ "$failed" =~ ^[0-9]+$ ]] || { echo "Error: failed must be a number"; return 1; }
    [[ "$skipped" =~ ^[0-9]+$ ]] || { echo "Error: skipped must be a number"; return 1; }
    [[ "$execution_time" =~ ^[0-9]+$ ]] || { echo "Error: execution_time must be a number"; return 1; }
    
    test_suite_set "$suite_name" "total_tests" "$total"
    test_suite_set "$suite_name" "passed_tests" "$passed"
    test_suite_set "$suite_name" "failed_tests" "$failed"
    test_suite_set "$suite_name" "skipped_tests" "$skipped"
    test_suite_set "$suite_name" "execution_time" "$execution_time"
    
    # Update status based on results
    if [[ "$failed" -gt 0 ]]; then
        test_suite_set "$suite_name" "status" "failed"
    elif [[ "$total" -eq 0 ]]; then
        test_suite_set "$suite_name" "status" "empty"
    else
        test_suite_set "$suite_name" "status" "passed"
    fi
}

# Get suite summary
# Usage: test_suite_summary <suite_name>
test_suite_summary() {
    local suite_name="$1"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    
    local name status total passed failed skipped execution_time
    name=$(test_suite_get "$suite_name" "name")
    status=$(test_suite_get "$suite_name" "status")
    total=$(test_suite_get "$suite_name" "total_tests")
    passed=$(test_suite_get "$suite_name" "passed_tests")
    failed=$(test_suite_get "$suite_name" "failed_tests")
    skipped=$(test_suite_get "$suite_name" "skipped_tests")
    execution_time=$(test_suite_get "$suite_name" "execution_time")
    
    cat <<EOF
Test Suite: $name
Status: $status
Total Tests: $total
Passed: $passed
Failed: $failed
Skipped: $skipped
Execution Time: ${execution_time}ms
EOF
}

# Check if suite meets coverage threshold
# Usage: test_suite_check_coverage <suite_name> <coverage_percentage>
test_suite_check_coverage() {
    local suite_name="$1"
    local coverage_percentage="$2"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    [[ "$coverage_percentage" =~ ^[0-9]+$ ]] || { echo "Error: coverage_percentage must be a number"; return 1; }
    
    local threshold
    threshold=$(test_suite_get "$suite_name" "coverage_threshold")
    
    if [[ "$coverage_percentage" -ge "$threshold" ]]; then
        echo "PASS"
        return 0
    else
        echo "FAIL"
        return 1
    fi
}

# Clean up suite instance
# Usage: test_suite_destroy <suite_name>
test_suite_destroy() {
    local suite_name="$1"
    
    [[ -n "$suite_name" ]] || { echo "Error: suite_name is required"; return 1; }
    
    # Remove all suite data
    for key in "${!TEST_SUITE_INSTANCES[@]}"; do
        if [[ "$key" == "${suite_name}:"* ]]; then
            unset TEST_SUITE_INSTANCES["$key"]
        fi
    done
}

# Export functions for use in other scripts
export -f test_suite_new
export -f test_suite_get
export -f test_suite_set
export -f test_suite_add_file
export -f test_suite_get_files
export -f test_suite_discover
export -f test_suite_update_stats
export -f test_suite_summary
export -f test_suite_check_coverage
export -f test_suite_destroy