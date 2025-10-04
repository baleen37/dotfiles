#!/usr/bin/env bash
# T014: TestFile model - represents individual test file and its execution state
# Provides functionality for managing individual test file lifecycle and metadata

set -euo pipefail

# TestFile class implementation
declare -A TEST_FILE_INSTANCES=()

# TestFile constructor
# Usage: test_file_new <file_id> <file_path>
test_file_new() {
  local file_id="$1"
  local file_path="$2"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }
  [[ -n $file_path ]] || {
    echo "Error: file_path is required"
    return 1
  }
  [[ -f $file_path ]] || {
    echo "Error: file_path '$file_path' does not exist"
    return 1
  }

  # Initialize file instance
  TEST_FILE_INSTANCES["${file_id}:id"]="$file_id"
  TEST_FILE_INSTANCES["${file_id}:path"]="$file_path"
  TEST_FILE_INSTANCES["${file_id}:name"]="$(basename "$file_path")"
  TEST_FILE_INSTANCES["${file_id}:directory"]="$(dirname "$file_path")"
  TEST_FILE_INSTANCES["${file_id}:created_at"]="$(date -Iseconds)"
  TEST_FILE_INSTANCES["${file_id}:status"]="pending"
  TEST_FILE_INSTANCES["${file_id}:test_count"]="0"
  TEST_FILE_INSTANCES["${file_id}:passed_count"]="0"
  TEST_FILE_INSTANCES["${file_id}:failed_count"]="0"
  TEST_FILE_INSTANCES["${file_id}:skipped_count"]="0"
  TEST_FILE_INSTANCES["${file_id}:execution_time"]="0"
  TEST_FILE_INSTANCES["${file_id}:error_message"]=""
  TEST_FILE_INSTANCES["${file_id}:coverage_percentage"]="0"
  TEST_FILE_INSTANCES["${file_id}:parallel_enabled"]="false"
  TEST_FILE_INSTANCES["${file_id}:timeout"]="60"
  TEST_FILE_INSTANCES["${file_id}:retry_count"]="0"
  TEST_FILE_INSTANCES["${file_id}:max_retries"]="0"

  echo "$file_id"
}

# Get file property
# Usage: test_file_get <file_id> <property>
test_file_get() {
  local file_id="$1"
  local property="$2"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }
  [[ -n $property ]] || {
    echo "Error: property is required"
    return 1
  }

  local key="${file_id}:${property}"
  echo "${TEST_FILE_INSTANCES[$key]:-}"
}

# Set file property
# Usage: test_file_set <file_id> <property> <value>
test_file_set() {
  local file_id="$1"
  local property="$2"
  local value="$3"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }
  [[ -n $property ]] || {
    echo "Error: property is required"
    return 1
  }

  local key="${file_id}:${property}"
  TEST_FILE_INSTANCES["$key"]="$value"
}

# Count tests in file
# Usage: test_file_count_tests <file_id>
test_file_count_tests() {
  local file_id="$1"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }

  local file_path
  file_path=$(test_file_get "$file_id" "path")

  # Count @test annotations in bats files
  local count=0
  if [[ $file_path == *.bats ]]; then
    count=$(grep -c "^@test" "$file_path" 2>/dev/null || echo "0")
  else
    # For shell scripts, count function definitions starting with test_
    count=$(grep -c "^test_[a-zA-Z_][a-zA-Z0-9_]*(" "$file_path" 2>/dev/null || echo "0")
  fi

  test_file_set "$file_id" "test_count" "$count"
  echo "$count"
}

# Update execution results
# Usage: test_file_update_results <file_id> <passed> <failed> <skipped> <execution_time> [error_message]
test_file_update_results() {
  local file_id="$1"
  local passed="$2"
  local failed="$3"
  local skipped="$4"
  local execution_time="$5"
  local error_message="${6:-}"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }
  [[ $passed =~ ^[0-9]+$ ]] || {
    echo "Error: passed must be a number"
    return 1
  }
  [[ $failed =~ ^[0-9]+$ ]] || {
    echo "Error: failed must be a number"
    return 1
  }
  [[ $skipped =~ ^[0-9]+$ ]] || {
    echo "Error: skipped must be a number"
    return 1
  }
  [[ $execution_time =~ ^[0-9]+$ ]] || {
    echo "Error: execution_time must be a number"
    return 1
  }

  test_file_set "$file_id" "passed_count" "$passed"
  test_file_set "$file_id" "failed_count" "$failed"
  test_file_set "$file_id" "skipped_count" "$skipped"
  test_file_set "$file_id" "execution_time" "$execution_time"
  test_file_set "$file_id" "error_message" "$error_message"

  # Update status based on results
  if [[ -n $error_message ]]; then
    test_file_set "$file_id" "status" "error"
  elif [[ $failed -gt 0 ]]; then
    test_file_set "$file_id" "status" "failed"
  elif [[ $passed -gt 0 ]]; then
    test_file_set "$file_id" "status" "passed"
  else
    test_file_set "$file_id" "status" "skipped"
  fi
}

# Check if file is executable
# Usage: test_file_is_executable <file_id>
test_file_is_executable() {
  local file_id="$1"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }

  local file_path
  file_path=$(test_file_get "$file_id" "path")

  if [[ -x $file_path ]]; then
    echo "true"
    return 0
  else
    echo "false"
    return 1
  fi
}

# Get file type
# Usage: test_file_get_type <file_id>
test_file_get_type() {
  local file_id="$1"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }

  local file_path
  file_path=$(test_file_get "$file_id" "path")

  case "$file_path" in
  *.bats)
    echo "bats"
    ;;
  *.sh)
    echo "shell"
    ;;
  *)
    echo "unknown"
    ;;
  esac
}

# Check if file should run in parallel
# Usage: test_file_can_parallel <file_id>
test_file_can_parallel() {
  local file_id="$1"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }

  local parallel_enabled
  parallel_enabled=$(test_file_get "$file_id" "parallel_enabled")

  if [[ $parallel_enabled == "true" ]]; then
    echo "true"
    return 0
  else
    echo "false"
    return 1
  fi
}

# Mark file for retry
# Usage: test_file_mark_retry <file_id>
test_file_mark_retry() {
  local file_id="$1"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }

  local retry_count max_retries
  retry_count=$(test_file_get "$file_id" "retry_count")
  max_retries=$(test_file_get "$file_id" "max_retries")

  if [[ $retry_count -lt $max_retries ]]; then
    test_file_set "$file_id" "retry_count" "$((retry_count + 1))"
    test_file_set "$file_id" "status" "retry"
    echo "true"
    return 0
  else
    echo "false"
    return 1
  fi
}

# Get file summary
# Usage: test_file_summary <file_id>
test_file_summary() {
  local file_id="$1"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }

  local name status test_count passed failed skipped execution_time coverage
  name=$(test_file_get "$file_id" "name")
  status=$(test_file_get "$file_id" "status")
  test_count=$(test_file_get "$file_id" "test_count")
  passed=$(test_file_get "$file_id" "passed_count")
  failed=$(test_file_get "$file_id" "failed_count")
  skipped=$(test_file_get "$file_id" "skipped_count")
  execution_time=$(test_file_get "$file_id" "execution_time")
  coverage=$(test_file_get "$file_id" "coverage_percentage")

  cat <<EOF
Test File: $name
Status: $status
Test Count: $test_count
Passed: $passed
Failed: $failed
Skipped: $skipped
Execution Time: ${execution_time}ms
Coverage: ${coverage}%
EOF
}

# Update coverage percentage
# Usage: test_file_update_coverage <file_id> <coverage_percentage>
test_file_update_coverage() {
  local file_id="$1"
  local coverage_percentage="$2"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }
  [[ $coverage_percentage =~ ^[0-9]+$ ]] || {
    echo "Error: coverage_percentage must be a number"
    return 1
  }
  [[ $coverage_percentage -le 100 ]] || {
    echo "Error: coverage_percentage cannot exceed 100"
    return 1
  }

  test_file_set "$file_id" "coverage_percentage" "$coverage_percentage"
}

# Clean up file instance
# Usage: test_file_destroy <file_id>
test_file_destroy() {
  local file_id="$1"

  [[ -n $file_id ]] || {
    echo "Error: file_id is required"
    return 1
  }

  # Remove all file data
  for key in "${!TEST_FILE_INSTANCES[@]}"; do
    if [[ $key == "${file_id}:"* ]]; then
      unset TEST_FILE_INSTANCES["$key"]
    fi
  done
}

# Export functions for use in other scripts
export -f test_file_new
export -f test_file_get
export -f test_file_set
export -f test_file_count_tests
export -f test_file_update_results
export -f test_file_is_executable
export -f test_file_get_type
export -f test_file_can_parallel
export -f test_file_mark_retry
export -f test_file_summary
export -f test_file_update_coverage
export -f test_file_destroy
