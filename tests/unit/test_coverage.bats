#!/usr/bin/env bats
# T038: Unit tests for coverage calculator in tests/unit/test_coverage.bats
# Tests the coverage tracking and reporting functionality

# Load the test library
load "../lib/common.bash"
load "../lib/coverage.bash"

setup() {
  common_test_setup "$BATS_TEST_NAME" "$BATS_TEST_DIRNAME"

  # Set up coverage environment
  export COVERAGE_DIR="$TEST_TEMP_DIR/coverage"
  export COVERAGE_FILE="$COVERAGE_DIR/coverage.data"
  mkdir -p "$COVERAGE_DIR"

  # Initialize coverage tracking
  init_coverage_tracking
}

teardown() {
  common_test_teardown
}

@test "init_coverage_tracking() creates coverage directory and files" {
  # Remove coverage dir first to test initialization
  rm -rf "$COVERAGE_DIR"

  run init_coverage_tracking

  [ "$status" -eq 0 ]
  [ -d "$COVERAGE_DIR" ]
  [ -f "$COVERAGE_FILE" ]
}

@test "record_test_execution() records test execution data" {
  local test_name="sample_test"
  local test_file="test_file.bats"
  local status="PASS"
  local duration="1.234"

  run record_test_execution "$test_name" "$test_file" "$status" "$duration"

  [ "$status" -eq 0 ]
  [ -f "$COVERAGE_FILE" ]

  # Verify data was recorded
  run grep "$test_name" "$COVERAGE_FILE"
  [ "$status" -eq 0 ]
  [[ $output =~ $test_file ]]
  [[ $output =~ $status ]]
  [[ $output =~ $duration ]]
}

@test "record_function_coverage() tracks function execution" {
  local function_name="test_function"
  local source_file="source.bash"
  local line_number="42"

  run record_function_coverage "$function_name" "$source_file" "$line_number"

  [ "$status" -eq 0 ]

  # Verify function coverage was recorded
  local coverage_data_file="$COVERAGE_DIR/functions.data"
  [ -f "$coverage_data_file" ]

  run grep "$function_name" "$coverage_data_file"
  [ "$status" -eq 0 ]
  [[ $output =~ $source_file ]]
  [[ $output =~ $line_number ]]
}

@test "calculate_test_coverage() computes coverage percentage" {
  # Create mock test data
  cat >"$COVERAGE_FILE" <<EOF
test_one|test_file.bats|PASS|1.0
test_two|test_file.bats|PASS|2.0
test_three|other_test.bats|FAIL|0.5
EOF

  run calculate_test_coverage

  [ "$status" -eq 0 ]
  [[ $output =~ "Coverage:" ]]
  [[ $output =~ "%" ]]

  # Test specific coverage calculation
  run calculate_test_coverage "test_file.bats"
  [ "$status" -eq 0 ]
  [[ $output =~ "test_file.bats" ]]
}

@test "calculate_line_coverage() computes line coverage from function data" {
  # Create mock function coverage data
  local func_data="$COVERAGE_DIR/functions.data"
  cat >"$func_data" <<EOF
func1|source1.bash|10
func2|source1.bash|20
func3|source2.bash|15
func1|source1.bash|10
EOF

  run calculate_line_coverage

  [ "$status" -eq 0 ]
  [[ $output =~ "Line coverage:" ]]
  [[ $output =~ "%" ]]
}

@test "generate_coverage_report() creates HTML report" {
  # Create test coverage data
  cat >"$COVERAGE_FILE" <<EOF
test_one|test_file.bats|PASS|1.0
test_two|test_file.bats|FAIL|2.0
EOF

  local report_file="$COVERAGE_DIR/coverage_report.html"
  run generate_coverage_report "$report_file"

  [ "$status" -eq 0 ]
  [ -f "$report_file" ]

  # Verify HTML content
  run grep "<html>" "$report_file"
  [ "$status" -eq 0 ]

  run grep "Coverage Report" "$report_file"
  [ "$status" -eq 0 ]

  run grep "test_one" "$report_file"
  [ "$status" -eq 0 ]
}

@test "generate_json_report() creates JSON coverage report" {
  # Create test coverage data
  cat >"$COVERAGE_FILE" <<EOF
test_one|test_file.bats|PASS|1.0
test_two|test_file.bats|PASS|2.0
EOF

  local json_report="$COVERAGE_DIR/coverage.json"
  run generate_json_report "$json_report"

  [ "$status" -eq 0 ]
  [ -f "$json_report" ]

  # Verify JSON structure
  run grep '"tests":' "$json_report"
  [ "$status" -eq 0 ]

  run grep '"coverage_percentage":' "$json_report"
  [ "$status" -eq 0 ]

  run grep '"test_one"' "$json_report"
  [ "$status" -eq 0 ]
}

@test "check_coverage_threshold() passes when coverage meets threshold" {
  # Create coverage data with 100% pass rate
  cat >"$COVERAGE_FILE" <<EOF
test_one|test_file.bats|PASS|1.0
test_two|test_file.bats|PASS|2.0
test_three|test_file.bats|PASS|1.5
EOF

  # Test with 80% threshold (should pass)
  run check_coverage_threshold 80

  [ "$status" -eq 0 ]
  [[ $output =~ "Coverage threshold met" ]]
}

@test "check_coverage_threshold() fails when coverage below threshold" {
  # Create coverage data with 50% pass rate
  cat >"$COVERAGE_FILE" <<EOF
test_one|test_file.bats|PASS|1.0
test_two|test_file.bats|FAIL|2.0
EOF

  # Test with 80% threshold (should fail)
  run check_coverage_threshold 80

  [ "$status" -eq 1 ]
  [[ $output =~ "Coverage threshold not met" ]]
}

@test "get_coverage_stats() returns statistical information" {
  # Create comprehensive test data
  cat >"$COVERAGE_FILE" <<EOF
test_one|test_file.bats|PASS|1.0
test_two|test_file.bats|PASS|2.0
test_three|test_file.bats|FAIL|0.5
test_four|other_test.bats|PASS|3.0
EOF

  run get_coverage_stats

  [ "$status" -eq 0 ]
  [[ $output =~ "Total tests:" ]]
  [[ $output =~ "Passed:" ]]
  [[ $output =~ "Failed:" ]]
  [[ $output =~ "Average duration:" ]]
  [[ $output =~ "Success rate:" ]]
}

@test "clean_coverage_data() removes old coverage files" {
  # Create coverage files
  touch "$COVERAGE_FILE"
  touch "$COVERAGE_DIR/functions.data"
  touch "$COVERAGE_DIR/coverage.json"
  touch "$COVERAGE_DIR/coverage_report.html"

  run clean_coverage_data

  [ "$status" -eq 0 ]
  [ ! -f "$COVERAGE_FILE" ]
  [ ! -f "$COVERAGE_DIR/functions.data" ]
  [ ! -f "$COVERAGE_DIR/coverage.json" ]
  [ ! -f "$COVERAGE_DIR/coverage_report.html" ]
  [ -d "$COVERAGE_DIR" ] # Directory should still exist
}

@test "merge_coverage_data() combines multiple coverage files" {
  # Create multiple coverage files
  local coverage1="$COVERAGE_DIR/coverage1.data"
  local coverage2="$COVERAGE_DIR/coverage2.data"

  cat >"$coverage1" <<EOF
test_one|file1.bats|PASS|1.0
test_two|file1.bats|PASS|2.0
EOF

  cat >"$coverage2" <<EOF
test_three|file2.bats|PASS|1.5
test_four|file2.bats|FAIL|0.8
EOF

  run merge_coverage_data "$coverage1" "$coverage2" "$COVERAGE_FILE"

  [ "$status" -eq 0 ]
  [ -f "$COVERAGE_FILE" ]

  # Verify merged data
  run wc -l <"$COVERAGE_FILE"
  [ "$output" -eq 4 ]

  run grep "test_one" "$COVERAGE_FILE"
  [ "$status" -eq 0 ]

  run grep "test_four" "$COVERAGE_FILE"
  [ "$status" -eq 0 ]
}

@test "export_coverage_metrics() exports metrics for CI/CD" {
  # Create test coverage data
  cat >"$COVERAGE_FILE" <<EOF
test_one|test_file.bats|PASS|1.0
test_two|test_file.bats|PASS|2.0
test_three|test_file.bats|FAIL|0.5
EOF

  local metrics_file="$COVERAGE_DIR/metrics.env"
  run export_coverage_metrics "$metrics_file"

  [ "$status" -eq 0 ]
  [ -f "$metrics_file" ]

  # Verify exported metrics
  run grep "COVERAGE_PERCENTAGE=" "$metrics_file"
  [ "$status" -eq 0 ]

  run grep "TOTAL_TESTS=" "$metrics_file"
  [ "$status" -eq 0 ]

  run grep "PASSED_TESTS=" "$metrics_file"
  [ "$status" -eq 0 ]

  run grep "FAILED_TESTS=" "$metrics_file"
  [ "$status" -eq 0 ]
}

@test "coverage tracking integrates with test execution" {
  # Test integration with actual test execution
  local test_script="$TEST_TEMP_DIR/sample_test.bats"
  cat >"$test_script" <<'EOF'
#!/usr/bin/env bats
load "../lib/common.bash"
load "../lib/coverage.bash"

@test "sample test that passes" {
    record_test_execution "$BATS_TEST_NAME" "$BATS_TEST_FILENAME" "PASS" "1.0"
    [ 1 -eq 1 ]
}
EOF

  # Execute the test
  run bats "$test_script"

  [ "$status" -eq 0 ]

  # Verify coverage was recorded
  [ -f "$COVERAGE_FILE" ]
  run grep "sample test that passes" "$COVERAGE_FILE"
  [ "$status" -eq 0 ]
}
