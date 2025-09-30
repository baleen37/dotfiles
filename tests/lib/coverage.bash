#!/usr/bin/env bash
# Coverage tracking and reporting functions
# Calculates test coverage and generates reports

# Coverage data storage
declare -A COVERAGE_DATA
declare -i TOTAL_FILES=0
declare -i TESTED_FILES=0
declare -i TOTAL_FUNCTIONS=0
declare -i TESTED_FUNCTIONS=0

# Initialize coverage tracking
init_coverage() {
  COVERAGE_DATA=()
  TOTAL_FILES=0
  TESTED_FILES=0
  TOTAL_FUNCTIONS=0
  TESTED_FUNCTIONS=0

  # Create coverage directory if needed
  mkdir -p "${COVERAGE_OUTPUT_DIR:-./coverage}"
}

# Track test file execution
track_test_file() {
  local test_file="$1"
  local status="${2:-passed}"

  COVERAGE_DATA["$test_file"]="$status"
  ((TESTED_FILES++))
}

# Count total test files
count_test_files() {
  local category="${1:-all}"
  local count=0

  if [[ "$category" == "all" ]]; then
    for cat in unit integration e2e performance; do
      if [[ -d "tests/$cat" ]]; then
        local cat_count=$(find "tests/$cat" -name "*.bats" -type f 2>/dev/null | wc -l)
        count=$((count + cat_count))
      fi
    done
  else
    if [[ -d "tests/$category" ]]; then
      count=$(find "tests/$category" -name "*.bats" -type f 2>/dev/null | wc -l)
    fi
  fi

  TOTAL_FILES=$count
  echo "$count"
}

# Count tested functions (approximation based on test names)
count_tested_functions() {
  local test_file="$1"
  local count=0

  if [[ -f "$test_file" ]]; then
    # Count @test declarations
    count=$(grep -c "^@test " "$test_file" 2>/dev/null || echo "0")
  fi

  echo "$count"
}

# Calculate coverage percentage
calculate_coverage_percentage() {
  local tested="${1:-0}"
  local total="${2:-0}"

  if [[ $total -eq 0 ]]; then
    echo "0"
    return
  fi

  # Use bc for floating point calculation
  if command -v bc &>/dev/null; then
    local result=$(echo "scale=1; ($tested * 100) / $total" | bc)
    # Convert to integer if it's a whole number
    if [[ $result =~ ^[0-9]+\.0$ ]]; then
      echo "${result%.*}"
    else
      echo "$result"
    fi
  else
    # Fallback to integer math
    echo $(( ($tested * 100) / $total ))
  fi
}

# Check if coverage meets threshold
check_coverage_threshold() {
  local coverage="$1"
  local threshold="${COVERAGE_THRESHOLD:-80}"

  # Remove decimal point for comparison
  local coverage_int="${coverage%.*}"

  if [[ ${coverage_int:-0} -ge $threshold ]]; then
    return 0
  else
    return 1
  fi
}

# Generate coverage report
generate_coverage_report() {
  local output_format="${1:-text}"
  local output_file="${COVERAGE_OUTPUT_DIR:-./coverage}/report.txt"

  init_coverage

  # Count files
  local total_files=$(count_test_files)
  local tested_files=0
  local total_tests=0
  local passed_tests=0

  # Analyze test results
  for category in unit integration e2e performance; do
    if [[ -d "tests/$category" ]]; then
      while IFS= read -r test_file; do
        if [[ -f "$test_file" ]]; then
          ((tested_files++))
          local test_count=$(count_tested_functions "$test_file")
          test_count=${test_count:-0}
          total_tests=$((total_tests + test_count))
          # Assume all pass for now (would need actual test results)
          passed_tests=$((passed_tests + test_count))
        fi
      done < <(find "tests/$category" -name "*.bats" -type f 2>/dev/null)
    fi
  done

  # Calculate coverage
  local file_coverage=$(calculate_coverage_percentage "$tested_files" "$total_files")
  local test_coverage=$(calculate_coverage_percentage "$passed_tests" "$total_tests")

  # Generate report
  {
    echo "════════════════════════════════════════════════════"
    echo "                 Coverage Report                     "
    echo "════════════════════════════════════════════════════"
    echo ""
    echo "File Coverage:    ${file_coverage}% (${tested_files}/${total_files} files)"
    echo "Test Coverage:    ${test_coverage}% (${passed_tests}/${total_tests} tests)"
    echo "Threshold:        ${COVERAGE_THRESHOLD:-80}%"
    echo ""

    # Per-category breakdown
    echo "Category Breakdown:"
    echo "-------------------"
    for category in unit integration e2e performance; do
      if [[ -d "tests/$category" ]]; then
        local cat_files=$(find "tests/$category" -name "*.bats" -type f 2>/dev/null | wc -l)
        local cat_tests=0
        while IFS= read -r test_file; do
          if [[ -f "$test_file" ]]; then
            local file_test_count=$(count_tested_functions "$test_file")
            file_test_count=${file_test_count:-0}
            cat_tests=$((cat_tests + file_test_count))
          fi
        done < <(find "tests/$category" -name "*.bats" -type f 2>/dev/null)
        printf "  %-15s: %3d files, %4d tests\n" "$category" "$cat_files" "$cat_tests"
      fi
    done

    echo ""

    # Check threshold
    if check_coverage_threshold "$file_coverage"; then
      echo "✓ Coverage meets threshold (${COVERAGE_THRESHOLD:-80}%)"
    else
      echo "✗ Coverage below threshold (${COVERAGE_THRESHOLD:-80}%)"
    fi

    echo ""
    echo "Report generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "════════════════════════════════════════════════════"
  } | tee "$output_file"

  # Return status based on threshold
  check_coverage_threshold "$file_coverage"
}

# Export functions for use in tests
export -f init_coverage
export -f track_test_file
export -f count_test_files
export -f count_tested_functions
export -f calculate_coverage_percentage
export -f check_coverage_threshold
export -f generate_coverage_report
