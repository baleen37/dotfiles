#!/usr/bin/env bash
# T015: TestUtilities model - provides utility functions for test infrastructure
# Centralizes common test operations and helper functions

set -euo pipefail

# TestUtilities class implementation
declare -A TEST_UTILITIES_INSTANCES=()

# TestUtilities constructor
# Usage: test_utilities_new <util_id> <base_path>
test_utilities_new() {
  local util_id="$1"
  local base_path="$2"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $base_path ]] || {
    echo "Error: base_path is required"
    return 1
  }
  [[ -d $base_path ]] || {
    echo "Error: base_path '$base_path' does not exist"
    return 1
  }

  # Initialize utilities instance
  TEST_UTILITIES_INSTANCES["${util_id}:id"]="$util_id"
  TEST_UTILITIES_INSTANCES["${util_id}:base_path"]="$base_path"
  TEST_UTILITIES_INSTANCES["${util_id}:temp_dir"]=""
  TEST_UTILITIES_INSTANCES["${util_id}:cleanup_enabled"]="true"
  TEST_UTILITIES_INSTANCES["${util_id}:verbose"]="false"
  TEST_UTILITIES_INSTANCES["${util_id}:dry_run"]="false"
  TEST_UTILITIES_INSTANCES["${util_id}:timeout"]="30"

  echo "$util_id"
}

# Get utility property
# Usage: test_utilities_get <util_id> <property>
test_utilities_get() {
  local util_id="$1"
  local property="$2"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $property ]] || {
    echo "Error: property is required"
    return 1
  }

  local key="${util_id}:${property}"
  echo "${TEST_UTILITIES_INSTANCES[$key]:-}"
}

# Set utility property
# Usage: test_utilities_set <util_id> <property> <value>
test_utilities_set() {
  local util_id="$1"
  local property="$2"
  local value="$3"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $property ]] || {
    echo "Error: property is required"
    return 1
  }

  local key="${util_id}:${property}"
  TEST_UTILITIES_INSTANCES["$key"]="$value"
}

# Create temporary directory for testing
# Usage: test_utilities_create_temp_dir <util_id> [prefix]
test_utilities_create_temp_dir() {
  local util_id="$1"
  local prefix="${2:-test_}"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }

  local temp_dir
  temp_dir=$(mktemp -d -t "${prefix}XXXXXX")
  test_utilities_set "$util_id" "temp_dir" "$temp_dir"

  echo "$temp_dir"
}

# Clean up temporary directory
# Usage: test_utilities_cleanup_temp_dir <util_id>
test_utilities_cleanup_temp_dir() {
  local util_id="$1"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }

  local cleanup_enabled temp_dir
  cleanup_enabled=$(test_utilities_get "$util_id" "cleanup_enabled")
  temp_dir=$(test_utilities_get "$util_id" "temp_dir")

  if [[ $cleanup_enabled == "true" && -n $temp_dir && -d $temp_dir ]]; then
    rm -rf "$temp_dir"
    test_utilities_set "$util_id" "temp_dir" ""
  fi
}

# Create test fixture file
# Usage: test_utilities_create_fixture <util_id> <filename> <content>
test_utilities_create_fixture() {
  local util_id="$1"
  local filename="$2"
  local content="$3"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $filename ]] || {
    echo "Error: filename is required"
    return 1
  }

  local temp_dir
  temp_dir=$(test_utilities_get "$util_id" "temp_dir")

  if [[ -z $temp_dir ]]; then
    temp_dir=$(test_utilities_create_temp_dir "$util_id")
  fi

  local fixture_path="$temp_dir/$filename"
  echo "$content" >"$fixture_path"

  echo "$fixture_path"
}

# Create test directory structure
# Usage: test_utilities_create_structure <util_id> <structure_spec>
test_utilities_create_structure() {
  local util_id="$1"
  local structure_spec="$2"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $structure_spec ]] || {
    echo "Error: structure_spec is required"
    return 1
  }

  local temp_dir
  temp_dir=$(test_utilities_get "$util_id" "temp_dir")

  if [[ -z $temp_dir ]]; then
    temp_dir=$(test_utilities_create_temp_dir "$util_id")
  fi

  # Parse structure specification (format: "dir1/file1.txt:content1,dir2/file2.txt:content2")
  IFS=',' read -ra ENTRIES <<<"$structure_spec"
  for entry in "${ENTRIES[@]}"; do
    if [[ $entry == *":"* ]]; then
      local path_part="${entry%:*}"
      local content_part="${entry#*:}"
      local full_path="$temp_dir/$path_part"

      # Create directory if needed
      mkdir -p "$(dirname "$full_path")"

      # Create file with content
      echo "$content_part" >"$full_path"
    else
      # Just create directory
      mkdir -p "$temp_dir/$entry"
    fi
  done

  echo "$temp_dir"
}

# Execute command with timeout
# Usage: test_utilities_exec_with_timeout <util_id> <command> [timeout_seconds]
test_utilities_exec_with_timeout() {
  local util_id="$1"
  local command="$2"
  local timeout_seconds="${3:-}"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $command ]] || {
    echo "Error: command is required"
    return 1
  }

  if [[ -z $timeout_seconds ]]; then
    timeout_seconds=$(test_utilities_get "$util_id" "timeout")
  fi

  local dry_run
  dry_run=$(test_utilities_get "$util_id" "dry_run")

  if [[ $dry_run == "true" ]]; then
    echo "DRY RUN: Would execute: $command"
    return 0
  fi

  timeout "$timeout_seconds" bash -c "$command"
}

# Check if command exists
# Usage: test_utilities_command_exists <util_id> <command>
test_utilities_command_exists() {
  local util_id="$1"
  local command="$2"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $command ]] || {
    echo "Error: command is required"
    return 1
  }

  if command -v "$command" >/dev/null 2>&1; then
    echo "true"
    return 0
  else
    echo "false"
    return 1
  fi
}

# Generate random string
# Usage: test_utilities_random_string <util_id> [length]
test_utilities_random_string() {
  local util_id="$1"
  local length="${2:-8}"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ $length =~ ^[0-9]+$ ]] || {
    echo "Error: length must be a number"
    return 1
  }

  head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$length"
}

# Wait for condition with timeout
# Usage: test_utilities_wait_for_condition <util_id> <condition_command> [timeout_seconds] [check_interval]
test_utilities_wait_for_condition() {
  local util_id="$1"
  local condition_command="$2"
  local timeout_seconds="${3:-30}"
  local check_interval="${4:-1}"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $condition_command ]] || {
    echo "Error: condition_command is required"
    return 1
  }
  [[ $timeout_seconds =~ ^[0-9]+$ ]] || {
    echo "Error: timeout_seconds must be a number"
    return 1
  }
  [[ $check_interval =~ ^[0-9]+$ ]] || {
    echo "Error: check_interval must be a number"
    return 1
  }

  local start_time end_time
  start_time=$(date +%s)
  end_time=$((start_time + timeout_seconds))

  while [[ $(date +%s) -lt $end_time ]]; do
    if eval "$condition_command" >/dev/null 2>&1; then
      echo "true"
      return 0
    fi
    sleep "$check_interval"
  done

  echo "false"
  return 1
}

# Log message with timestamp
# Usage: test_utilities_log <util_id> <level> <message>
test_utilities_log() {
  local util_id="$1"
  local level="$2"
  local message="$3"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $level ]] || {
    echo "Error: level is required"
    return 1
  }
  [[ -n $message ]] || {
    echo "Error: message is required"
    return 1
  }

  local verbose
  verbose=$(test_utilities_get "$util_id" "verbose")

  if [[ $verbose == "true" || $level == "ERROR" ]]; then
    echo "[$(date -Iseconds)] [$level] $message" >&2
  fi
}

# Create backup of file
# Usage: test_utilities_backup_file <util_id> <file_path>
test_utilities_backup_file() {
  local util_id="$1"
  local file_path="$2"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
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

  local backup_path="${file_path}.backup.$(date +%s)"
  cp "$file_path" "$backup_path"

  echo "$backup_path"
}

# Restore file from backup
# Usage: test_utilities_restore_file <util_id> <backup_path> <original_path>
test_utilities_restore_file() {
  local util_id="$1"
  local backup_path="$2"
  local original_path="$3"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }
  [[ -n $backup_path ]] || {
    echo "Error: backup_path is required"
    return 1
  }
  [[ -n $original_path ]] || {
    echo "Error: original_path is required"
    return 1
  }
  [[ -f $backup_path ]] || {
    echo "Error: backup_path '$backup_path' does not exist"
    return 1
  }

  cp "$backup_path" "$original_path"
  rm -f "$backup_path"
}

# Clean up utility instance
# Usage: test_utilities_destroy <util_id>
test_utilities_destroy() {
  local util_id="$1"

  [[ -n $util_id ]] || {
    echo "Error: util_id is required"
    return 1
  }

  # Clean up temporary directory first
  test_utilities_cleanup_temp_dir "$util_id"

  # Remove all utility data
  for key in "${!TEST_UTILITIES_INSTANCES[@]}"; do
    if [[ $key == "${util_id}:"* ]]; then
      unset TEST_UTILITIES_INSTANCES["$key"]
    fi
  done
}

# Export functions for use in other scripts
export -f test_utilities_new
export -f test_utilities_get
export -f test_utilities_set
export -f test_utilities_create_temp_dir
export -f test_utilities_cleanup_temp_dir
export -f test_utilities_create_fixture
export -f test_utilities_create_structure
export -f test_utilities_exec_with_timeout
export -f test_utilities_command_exists
export -f test_utilities_random_string
export -f test_utilities_wait_for_condition
export -f test_utilities_log
export -f test_utilities_backup_file
export -f test_utilities_restore_file
export -f test_utilities_destroy
