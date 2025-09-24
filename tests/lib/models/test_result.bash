#!/usr/bin/env bash
# T016: TestResult model - represents individual test execution results
# Provides functionality for managing test result data and aggregation

set -euo pipefail

# TestResult class implementation
declare -A TEST_RESULT_INSTANCES=()

# TestResult constructor
# Usage: test_result_new <result_id> <test_name> <file_path>
test_result_new() {
    local result_id="$1"
    local test_name="$2"
    local file_path="$3"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ -n "$test_name" ]] || { echo "Error: test_name is required"; return 1; }
    [[ -n "$file_path" ]] || { echo "Error: file_path is required"; return 1; }

    # Initialize result instance
    TEST_RESULT_INSTANCES["${result_id}:id"]="$result_id"
    TEST_RESULT_INSTANCES["${result_id}:test_name"]="$test_name"
    TEST_RESULT_INSTANCES["${result_id}:file_path"]="$file_path"
    TEST_RESULT_INSTANCES["${result_id}:status"]="pending"
    TEST_RESULT_INSTANCES["${result_id}:start_time"]=""
    TEST_RESULT_INSTANCES["${result_id}:end_time"]=""
    TEST_RESULT_INSTANCES["${result_id}:execution_time"]="0"
    TEST_RESULT_INSTANCES["${result_id}:output"]=""
    TEST_RESULT_INSTANCES["${result_id}:error_output"]=""
    TEST_RESULT_INSTANCES["${result_id}:exit_code"]=""
    TEST_RESULT_INSTANCES["${result_id}:assertion_count"]="0"
    TEST_RESULT_INSTANCES["${result_id}:failed_assertions"]="0"
    TEST_RESULT_INSTANCES["${result_id}:skip_reason"]=""
    TEST_RESULT_INSTANCES["${result_id}:retry_count"]="0"
    TEST_RESULT_INSTANCES["${result_id}:tags"]=""
    TEST_RESULT_INSTANCES["${result_id}:category"]="unit"

    echo "$result_id"
}

# Get result property
# Usage: test_result_get <result_id> <property>
test_result_get() {
    local result_id="$1"
    local property="$2"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ -n "$property" ]] || { echo "Error: property is required"; return 1; }

    local key="${result_id}:${property}"
    echo "${TEST_RESULT_INSTANCES[$key]:-}"
}

# Set result property
# Usage: test_result_set <result_id> <property> <value>
test_result_set() {
    local result_id="$1"
    local property="$2"
    local value="$3"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ -n "$property" ]] || { echo "Error: property is required"; return 1; }

    local key="${result_id}:${property}"
    TEST_RESULT_INSTANCES["$key"]="$value"
}

# Start test execution timing
# Usage: test_result_start <result_id>
test_result_start() {
    local result_id="$1"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    local start_time
    start_time=$(date -Iseconds)
    test_result_set "$result_id" "start_time" "$start_time"
    test_result_set "$result_id" "status" "running"
}

# End test execution timing
# Usage: test_result_end <result_id>
test_result_end() {
    local result_id="$1"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    local end_time start_time execution_time
    end_time=$(date -Iseconds)
    start_time=$(test_result_get "$result_id" "start_time")

    test_result_set "$result_id" "end_time" "$end_time"

    # Calculate execution time in milliseconds
    if [[ -n "$start_time" ]]; then
        local start_epoch end_epoch
        start_epoch=$(date -d "$start_time" +%s%3N)
        end_epoch=$(date -d "$end_time" +%s%3N)
        execution_time=$((end_epoch - start_epoch))
        test_result_set "$result_id" "execution_time" "$execution_time"
    fi
}

# Mark test as passed
# Usage: test_result_pass <result_id> [assertion_count]
test_result_pass() {
    local result_id="$1"
    local assertion_count="${2:-1}"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ "$assertion_count" =~ ^[0-9]+$ ]] || { echo "Error: assertion_count must be a number"; return 1; }

    test_result_set "$result_id" "status" "passed"
    test_result_set "$result_id" "assertion_count" "$assertion_count"
    test_result_set "$result_id" "failed_assertions" "0"
    test_result_end "$result_id"
}

# Mark test as failed
# Usage: test_result_fail <result_id> <error_message> [assertion_count] [failed_assertions]
test_result_fail() {
    local result_id="$1"
    local error_message="$2"
    local assertion_count="${3:-1}"
    local failed_assertions="${4:-1}"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ -n "$error_message" ]] || { echo "Error: error_message is required"; return 1; }
    [[ "$assertion_count" =~ ^[0-9]+$ ]] || { echo "Error: assertion_count must be a number"; return 1; }
    [[ "$failed_assertions" =~ ^[0-9]+$ ]] || { echo "Error: failed_assertions must be a number"; return 1; }

    test_result_set "$result_id" "status" "failed"
    test_result_set "$result_id" "error_output" "$error_message"
    test_result_set "$result_id" "assertion_count" "$assertion_count"
    test_result_set "$result_id" "failed_assertions" "$failed_assertions"
    test_result_end "$result_id"
}

# Mark test as skipped
# Usage: test_result_skip <result_id> <skip_reason>
test_result_skip() {
    local result_id="$1"
    local skip_reason="$2"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ -n "$skip_reason" ]] || { echo "Error: skip_reason is required"; return 1; }

    test_result_set "$result_id" "status" "skipped"
    test_result_set "$result_id" "skip_reason" "$skip_reason"
    test_result_end "$result_id"
}

# Set test output
# Usage: test_result_set_output <result_id> <output> [error_output]
test_result_set_output() {
    local result_id="$1"
    local output="$2"
    local error_output="${3:-}"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    test_result_set "$result_id" "output" "$output"
    if [[ -n "$error_output" ]]; then
        test_result_set "$result_id" "error_output" "$error_output"
    fi
}

# Set exit code
# Usage: test_result_set_exit_code <result_id> <exit_code>
test_result_set_exit_code() {
    local result_id="$1"
    local exit_code="$2"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ "$exit_code" =~ ^[0-9]+$ ]] || { echo "Error: exit_code must be a number"; return 1; }

    test_result_set "$result_id" "exit_code" "$exit_code"
}

# Add tag to test result
# Usage: test_result_add_tag <result_id> <tag>
test_result_add_tag() {
    local result_id="$1"
    local tag="$2"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ -n "$tag" ]] || { echo "Error: tag is required"; return 1; }

    local current_tags
    current_tags=$(test_result_get "$result_id" "tags")

    if [[ -n "$current_tags" ]]; then
        test_result_set "$result_id" "tags" "$current_tags,$tag"
    else
        test_result_set "$result_id" "tags" "$tag"
    fi
}

# Check if test has tag
# Usage: test_result_has_tag <result_id> <tag>
test_result_has_tag() {
    local result_id="$1"
    local tag="$2"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }
    [[ -n "$tag" ]] || { echo "Error: tag is required"; return 1; }

    local tags
    tags=$(test_result_get "$result_id" "tags")

    if [[ "$tags" == *"$tag"* ]]; then
        echo "true"
        return 0
    else
        echo "false"
        return 1
    fi
}

# Get test duration in human readable format
# Usage: test_result_get_duration <result_id>
test_result_get_duration() {
    local result_id="$1"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    local execution_time
    execution_time=$(test_result_get "$result_id" "execution_time")

    if [[ "$execution_time" -eq 0 ]]; then
        echo "0ms"
    elif [[ "$execution_time" -lt 1000 ]]; then
        echo "${execution_time}ms"
    elif [[ "$execution_time" -lt 60000 ]]; then
        echo "$((execution_time / 1000)).$((execution_time % 1000 / 100))s"
    else
        local minutes seconds
        minutes=$((execution_time / 60000))
        seconds=$(((execution_time % 60000) / 1000))
        echo "${minutes}m${seconds}s"
    fi
}

# Is test result successful
# Usage: test_result_is_success <result_id>
test_result_is_success() {
    local result_id="$1"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    local status
    status=$(test_result_get "$result_id" "status")

    if [[ "$status" == "passed" ]]; then
        echo "true"
        return 0
    else
        echo "false"
        return 1
    fi
}

# Get result summary
# Usage: test_result_summary <result_id>
test_result_summary() {
    local result_id="$1"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    local test_name status duration assertion_count failed_assertions
    test_name=$(test_result_get "$result_id" "test_name")
    status=$(test_result_get "$result_id" "status")
    duration=$(test_result_get_duration "$result_id")
    assertion_count=$(test_result_get "$result_id" "assertion_count")
    failed_assertions=$(test_result_get "$result_id" "failed_assertions")

    cat <<EOF
Test: $test_name
Status: $status
Duration: $duration
Assertions: $assertion_count
Failed Assertions: $failed_assertions
EOF
}

# Get detailed result information
# Usage: test_result_details <result_id>
test_result_details() {
    local result_id="$1"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    local test_name status file_path start_time end_time duration output error_output
    test_name=$(test_result_get "$result_id" "test_name")
    status=$(test_result_get "$result_id" "status")
    file_path=$(test_result_get "$result_id" "file_path")
    start_time=$(test_result_get "$result_id" "start_time")
    end_time=$(test_result_get "$result_id" "end_time")
    duration=$(test_result_get_duration "$result_id")
    output=$(test_result_get "$result_id" "output")
    error_output=$(test_result_get "$result_id" "error_output")

    cat <<EOF
=== Test Result Details ===
Test: $test_name
File: $file_path
Status: $status
Start Time: $start_time
End Time: $end_time
Duration: $duration

Output:
$output

Error Output:
$error_output
EOF
}

# Clean up result instance
# Usage: test_result_destroy <result_id>
test_result_destroy() {
    local result_id="$1"

    [[ -n "$result_id" ]] || { echo "Error: result_id is required"; return 1; }

    # Remove all result data
    for key in "${!TEST_RESULT_INSTANCES[@]}"; do
        if [[ "$key" == "${result_id}:"* ]]; then
            unset TEST_RESULT_INSTANCES["$key"]
        fi
    done
}

# Export functions for use in other scripts
export -f test_result_new
export -f test_result_get
export -f test_result_set
export -f test_result_start
export -f test_result_end
export -f test_result_pass
export -f test_result_fail
export -f test_result_skip
export -f test_result_set_output
export -f test_result_set_exit_code
export -f test_result_add_tag
export -f test_result_has_tag
export -f test_result_get_duration
export -f test_result_is_success
export -f test_result_summary
export -f test_result_details
export -f test_result_destroy
