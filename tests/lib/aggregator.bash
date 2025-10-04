#!/usr/bin/env bash
# T023: Test result aggregator for comprehensive test result collection and analysis
# Provides result aggregation, statistics, and reporting functionality

set -euo pipefail

# Source required models
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/models/test_suite.bash"
source "$SCRIPT_DIR/models/test_file.bash"
source "$SCRIPT_DIR/models/test_result.bash"

# Test Result Aggregator implementation
declare -A AGGREGATOR_INSTANCES=()
declare -A AGGREGATED_RESULTS=()

# Aggregator constructor
# Usage: aggregator_new <aggregator_id> <output_format>
aggregator_new() {
  local aggregator_id="$1"
  local output_format="${2:-json}"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }

  # Validate output format
  case "$output_format" in
  json | xml | junit | tap | csv) ;;
  *)
    echo "Error: Invalid output format '$output_format'. Must be one of: json, xml, junit, tap, csv" >&2
    return 1
    ;;
  esac

  # Initialize aggregator instance
  AGGREGATOR_INSTANCES["${aggregator_id}:id"]="$aggregator_id"
  AGGREGATOR_INSTANCES["${aggregator_id}:output_format"]="$output_format"
  AGGREGATOR_INSTANCES["${aggregator_id}:include_passed"]="true"
  AGGREGATOR_INSTANCES["${aggregator_id}:include_failed"]="true"
  AGGREGATOR_INSTANCES["${aggregator_id}:include_skipped"]="true"
  AGGREGATOR_INSTANCES["${aggregator_id}:include_details"]="true"
  AGGREGATOR_INSTANCES["${aggregator_id}:sort_by"]="file"
  AGGREGATOR_INSTANCES["${aggregator_id}:group_by"]="category"
  AGGREGATOR_INSTANCES["${aggregator_id}:result_count"]="0"
  AGGREGATOR_INSTANCES["${aggregator_id}:start_time"]="$(date -Iseconds)"
  AGGREGATOR_INSTANCES["${aggregator_id}:end_time"]=""

  echo "$aggregator_id"
}

# Get aggregator property
# Usage: aggregator_get <aggregator_id> <property>
aggregator_get() {
  local aggregator_id="$1"
  local property="$2"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }
  [[ -n $property ]] || {
    echo "Error: property is required"
    return 1
  }

  local key="${aggregator_id}:${property}"
  echo "${AGGREGATOR_INSTANCES[$key]:-}"
}

# Set aggregator property
# Usage: aggregator_set <aggregator_id> <property> <value>
aggregator_set() {
  local aggregator_id="$1"
  local property="$2"
  local value="$3"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }
  [[ -n $property ]] || {
    echo "Error: property is required"
    return 1
  }

  local key="${aggregator_id}:${property}"
  AGGREGATOR_INSTANCES["$key"]="$value"
}

# Add test result to aggregator
# Usage: aggregator_add_result <aggregator_id> <result_data>
aggregator_add_result() {
  local aggregator_id="$1"
  local result_data="$2"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }
  [[ -n $result_data ]] || {
    echo "Error: result_data is required"
    return 1
  }

  # Validate result data is valid JSON
  if ! echo "$result_data" | jq . >/dev/null 2>&1; then
    echo "Error: result_data is not valid JSON" >&2
    return 1
  fi

  # Generate unique result ID
  local result_count
  result_count=$(aggregator_get "$aggregator_id" "result_count")
  local result_id="${aggregator_id}_result_${result_count}"

  # Store result data
  AGGREGATED_RESULTS["$result_id"]="$result_data"

  # Update result count
  aggregator_set "$aggregator_id" "result_count" "$((result_count + 1))"

  echo "$result_id"
}

# Add test suite results to aggregator
# Usage: aggregator_add_suite <aggregator_id> <suite_id>
aggregator_add_suite() {
  local aggregator_id="$1"
  local suite_id="$2"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }
  [[ -n $suite_id ]] || {
    echo "Error: suite_id is required"
    return 1
  }

  # Extract suite data and convert to result format
  local suite_data
  suite_data=$(_aggregator_convert_suite_to_result "$suite_id")

  # Add to aggregator
  aggregator_add_result "$aggregator_id" "$suite_data"
}

# Convert test suite to result format
# Usage: _aggregator_convert_suite_to_result <suite_id>
_aggregator_convert_suite_to_result() {
  local suite_id="$1"

  local name status total passed failed skipped execution_time
  name=$(test_suite_get "$suite_id" "name")
  status=$(test_suite_get "$suite_id" "status")
  total=$(test_suite_get "$suite_id" "total_tests")
  passed=$(test_suite_get "$suite_id" "passed_tests")
  failed=$(test_suite_get "$suite_id" "failed_tests")
  skipped=$(test_suite_get "$suite_id" "skipped_tests")
  execution_time=$(test_suite_get "$suite_id" "execution_time")

  # Get test files in suite
  local test_files_json="[]"
  if command -v jq >/dev/null 2>&1; then
    local files=()
    while IFS= read -r file_path; do
      [[ -n $file_path ]] && files+=("\"$file_path\"")
    done < <(test_suite_get_files "$suite_id")

    if [[ ${#files[@]} -gt 0 ]]; then
      test_files_json="[$(
        IFS=,
        echo "${files[*]}"
      )]"
    fi
  fi

  cat <<EOF
{
  "type": "suite",
  "id": "$suite_id",
  "name": "$name",
  "status": "$status",
  "stats": {
    "total": $total,
    "passed": $passed,
    "failed": $failed,
    "skipped": $skipped
  },
  "execution_time_ms": $execution_time,
  "test_files": $test_files_json,
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Generate aggregated report
# Usage: aggregator_generate_report <aggregator_id>
aggregator_generate_report() {
  local aggregator_id="$1"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }

  # Set end time
  aggregator_set "$aggregator_id" "end_time" "$(date -Iseconds)"

  # Get output format
  local output_format
  output_format=$(aggregator_get "$aggregator_id" "output_format")

  case "$output_format" in
  json)
    _aggregator_generate_json_report "$aggregator_id"
    ;;
  xml)
    _aggregator_generate_xml_report "$aggregator_id"
    ;;
  junit)
    _aggregator_generate_junit_report "$aggregator_id"
    ;;
  tap)
    _aggregator_generate_tap_report "$aggregator_id"
    ;;
  csv)
    _aggregator_generate_csv_report "$aggregator_id"
    ;;
  *)
    echo "Error: Unsupported output format: $output_format" >&2
    return 1
    ;;
  esac
}

# Generate JSON report
# Usage: _aggregator_generate_json_report <aggregator_id>
_aggregator_generate_json_report() {
  local aggregator_id="$1"

  # Collect all results
  local results=()
  local result_count
  result_count=$(aggregator_get "$aggregator_id" "result_count")

  for ((i = 0; i < result_count; i++)); do
    local result_id="${aggregator_id}_result_${i}"
    if [[ -n ${AGGREGATED_RESULTS[$result_id]:-} ]]; then
      results+=("${AGGREGATED_RESULTS[$result_id]}")
    fi
  done

  # Calculate summary statistics
  local summary
  summary=$(_aggregator_calculate_summary "$aggregator_id" "${results[@]}")

  # Generate report metadata
  local start_time end_time
  start_time=$(aggregator_get "$aggregator_id" "start_time")
  end_time=$(aggregator_get "$aggregator_id" "end_time")

  # Build JSON report
  cat <<EOF
{
  "report": {
    "id": "$aggregator_id",
    "format": "json",
    "generated_at": "$(date -Iseconds)",
    "start_time": "$start_time",
    "end_time": "$end_time",
    "duration": "$(_aggregator_calculate_duration "$start_time" "$end_time")"
  },
  "summary": $summary,
  "results": [
    $(
    IFS=$'\n'
    echo "${results[*]}" | sed '$!s/$/,/'
  )
  ]
}
EOF
}

# Generate XML report
# Usage: _aggregator_generate_xml_report <aggregator_id>
_aggregator_generate_xml_report() {
  local aggregator_id="$1"

  local result_count
  result_count=$(aggregator_get "$aggregator_id" "result_count")

  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testReport id="$aggregator_id" timestamp="$(date -Iseconds)">
  <summary>
    $(_aggregator_get_summary_xml "$aggregator_id")
  </summary>
  <results>
EOF

  # Add each result
  for ((i = 0; i < result_count; i++)); do
    local result_id="${aggregator_id}_result_${i}"
    if [[ -n ${AGGREGATED_RESULTS[$result_id]:-} ]]; then
      echo "    $(_aggregator_convert_json_to_xml "${AGGREGATED_RESULTS[$result_id]}")"
    fi
  done

  cat <<EOF
  </results>
</testReport>
EOF
}

# Generate JUnit XML report
# Usage: _aggregator_generate_junit_report <aggregator_id>
_aggregator_generate_junit_report() {
  local aggregator_id="$1"

  # Calculate totals for JUnit format
  local total_tests=0 total_failures=0 total_errors=0 total_skipped=0
  local result_count
  result_count=$(aggregator_get "$aggregator_id" "result_count")

  for ((i = 0; i < result_count; i++)); do
    local result_id="${aggregator_id}_result_${i}"
    if [[ -n ${AGGREGATED_RESULTS[$result_id]:-} ]]; then
      local result_data="${AGGREGATED_RESULTS[$result_id]}"

      if command -v jq >/dev/null 2>&1; then
        local passed failed skipped
        passed=$(echo "$result_data" | jq -r '.stats.passed // 0')
        failed=$(echo "$result_data" | jq -r '.stats.failed // 0')
        skipped=$(echo "$result_data" | jq -r '.stats.skipped // 0')

        total_tests=$((total_tests + passed + failed + skipped))
        total_failures=$((total_failures + failed))
        total_skipped=$((total_skipped + skipped))
      fi
    fi
  done

  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="$aggregator_id" tests="$total_tests" failures="$total_failures" errors="0" skipped="$total_skipped" time="0" timestamp="$(date -Iseconds)">
EOF

  # Add test cases
  for ((i = 0; i < result_count; i++)); do
    local result_id="${aggregator_id}_result_${i}"
    if [[ -n ${AGGREGATED_RESULTS[$result_id]:-} ]]; then
      echo "  $(_aggregator_convert_to_junit_testcase "${AGGREGATED_RESULTS[$result_id]}")"
    fi
  done

  echo "</testsuite>"
}

# Generate TAP (Test Anything Protocol) report
# Usage: _aggregator_generate_tap_report <aggregator_id>
_aggregator_generate_tap_report() {
  local aggregator_id="$1"

  local result_count test_number=1
  result_count=$(aggregator_get "$aggregator_id" "result_count")

  echo "TAP version 13"
  echo "1..$result_count"

  for ((i = 0; i < result_count; i++)); do
    local result_id="${aggregator_id}_result_${i}"
    if [[ -n ${AGGREGATED_RESULTS[$result_id]:-} ]]; then
      local result_data="${AGGREGATED_RESULTS[$result_id]}"

      if command -v jq >/dev/null 2>&1; then
        local name status
        name=$(echo "$result_data" | jq -r '.name // "unknown"')
        status=$(echo "$result_data" | jq -r '.status // "unknown"')

        if [[ $status == "passed" ]]; then
          echo "ok $test_number - $name"
        elif [[ $status == "skipped" ]]; then
          echo "ok $test_number - $name # SKIP"
        else
          echo "not ok $test_number - $name"
        fi
      else
        echo "ok $test_number - Test $i"
      fi

      ((test_number++))
    fi
  done
}

# Generate CSV report
# Usage: _aggregator_generate_csv_report <aggregator_id>
_aggregator_generate_csv_report() {
  local aggregator_id="$1"

  # CSV header
  echo "ID,Name,Status,Total,Passed,Failed,Skipped,ExecutionTime,Timestamp"

  local result_count
  result_count=$(aggregator_get "$aggregator_id" "result_count")

  for ((i = 0; i < result_count; i++)); do
    local result_id="${aggregator_id}_result_${i}"
    if [[ -n ${AGGREGATED_RESULTS[$result_id]:-} ]]; then
      local result_data="${AGGREGATED_RESULTS[$result_id]}"

      if command -v jq >/dev/null 2>&1; then
        echo "$result_data" | jq -r '[.id, .name, .status, .stats.total, .stats.passed, .stats.failed, .stats.skipped, .execution_time_ms, .timestamp] | @csv'
      else
        # Fallback without jq
        echo "$result_id,Unknown,Unknown,0,0,0,0,0,$(date -Iseconds)"
      fi
    fi
  done
}

# Calculate summary statistics
# Usage: _aggregator_calculate_summary <aggregator_id> <results...>
_aggregator_calculate_summary() {
  local aggregator_id="$1"
  shift
  local results=("$@")

  local total_tests=0 total_passed=0 total_failed=0 total_skipped=0
  local total_execution_time=0 total_suites=${#results[@]}

  if command -v jq >/dev/null 2>&1; then
    for result in "${results[@]}"; do
      local passed failed skipped exec_time
      passed=$(echo "$result" | jq -r '.stats.passed // 0')
      failed=$(echo "$result" | jq -r '.stats.failed // 0')
      skipped=$(echo "$result" | jq -r '.stats.skipped // 0')
      exec_time=$(echo "$result" | jq -r '.execution_time_ms // 0')

      total_tests=$((total_tests + passed + failed + skipped))
      total_passed=$((total_passed + passed))
      total_failed=$((total_failed + failed))
      total_skipped=$((total_skipped + skipped))
      total_execution_time=$((total_execution_time + exec_time))
    done
  fi

  # Calculate success rate
  local success_rate=0
  if [[ $total_tests -gt 0 ]]; then
    success_rate=$(((total_passed * 100) / total_tests))
  fi

  cat <<EOF
{
  "total_suites": $total_suites,
  "total_tests": $total_tests,
  "passed": $total_passed,
  "failed": $total_failed,
  "skipped": $total_skipped,
  "success_rate": $success_rate,
  "total_execution_time_ms": $total_execution_time
}
EOF
}

# Calculate duration between timestamps
# Usage: _aggregator_calculate_duration <start_time> <end_time>
_aggregator_calculate_duration() {
  local start_time="$1"
  local end_time="$2"

  if command -v date >/dev/null 2>&1; then
    local start_epoch end_epoch duration
    start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
    end_epoch=$(date -d "$end_time" +%s 2>/dev/null || echo "0")
    duration=$((end_epoch - start_epoch))
    echo "${duration}s"
  else
    echo "unknown"
  fi
}

# Get aggregation statistics
# Usage: aggregator_get_stats <aggregator_id>
aggregator_get_stats() {
  local aggregator_id="$1"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }

  local result_count start_time end_time
  result_count=$(aggregator_get "$aggregator_id" "result_count")
  start_time=$(aggregator_get "$aggregator_id" "start_time")
  end_time=$(aggregator_get "$aggregator_id" "end_time")

  cat <<EOF
{
  "aggregator_id": "$aggregator_id",
  "result_count": $result_count,
  "start_time": "$start_time",
  "end_time": "$end_time",
  "status": "${end_time:+completed}"
}
EOF
}

# Clean up aggregator instance
# Usage: aggregator_destroy <aggregator_id>
aggregator_destroy() {
  local aggregator_id="$1"

  [[ -n $aggregator_id ]] || {
    echo "Error: aggregator_id is required"
    return 1
  }

  # Remove all aggregated results
  local result_count
  result_count=$(aggregator_get "$aggregator_id" "result_count")

  for ((i = 0; i < result_count; i++)); do
    local result_id="${aggregator_id}_result_${i}"
    unset AGGREGATED_RESULTS["$result_id"] 2>/dev/null || true
  done

  # Remove all aggregator data
  for key in "${!AGGREGATOR_INSTANCES[@]}"; do
    if [[ $key == "${aggregator_id}:"* ]]; then
      unset AGGREGATOR_INSTANCES["$key"]
    fi
  done
}

# Export functions for use in other scripts
export -f aggregator_new
export -f aggregator_get
export -f aggregator_set
export -f aggregator_add_result
export -f aggregator_add_suite
export -f aggregator_generate_report
export -f aggregator_get_stats
export -f aggregator_destroy
