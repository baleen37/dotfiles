#!/usr/bin/env bats
# T037: Unit tests for test utilities in tests/unit/test_utilities.bats
# Tests the common utilities and helpers used across the test suite

# Load the test library
load "../lib/common.bash"

setup() {
    common_test_setup "$BATS_TEST_NAME" "$BATS_TEST_DIRNAME"
}

teardown() {
    common_test_teardown
}

@test "test_info() outputs formatted information message" {
    # Test the test_info function
    run test_info "This is a test message"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "INFO:" ]]
    [[ "$output" =~ "This is a test message" ]]
}

@test "test_error() outputs formatted error message" {
    # Test the test_error function
    run test_error "This is an error message"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ERROR:" ]]
    [[ "$output" =~ "This is an error message" ]]
}

@test "test_debug() outputs debug message when BATS_DEBUG is set" {
    # Test debug output when enabled
    export BATS_DEBUG=1
    run test_debug "This is a debug message"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DEBUG:" ]]
    [[ "$output" =~ "This is a debug message" ]]
}

@test "test_debug() does not output when BATS_DEBUG is unset" {
    # Test debug output when disabled
    unset BATS_DEBUG
    run test_debug "This should not appear"
    
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "setup_test_environment() creates necessary directories" {
    # Test environment setup
    run setup_test_environment "$TEST_TEMP_DIR/test_env"
    
    [ "$status" -eq 0 ]
    [ -d "$TEST_TEMP_DIR/test_env" ]
}

@test "cleanup_test_environment() removes test directories" {
    # Create test directory
    local test_dir="$TEST_TEMP_DIR/cleanup_test"
    mkdir -p "$test_dir"
    echo "test file" > "$test_dir/file.txt"
    
    # Test cleanup
    run cleanup_test_environment "$test_dir"
    
    [ "$status" -eq 0 ]
    [ ! -d "$test_dir" ]
}

@test "assert_file_exists() passes when file exists" {
    # Create test file
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    # Test assertion
    run assert_file_exists "$test_file"
    
    [ "$status" -eq 0 ]
}

@test "assert_file_exists() fails when file does not exist" {
    # Test assertion with non-existent file
    run assert_file_exists "$TEST_TEMP_DIR/nonexistent.txt"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist" ]]
}

@test "assert_dir_exists() passes when directory exists" {
    # Test assertion with existing directory
    run assert_dir_exists "$TEST_TEMP_DIR"
    
    [ "$status" -eq 0 ]
}

@test "assert_dir_exists() fails when directory does not exist" {
    # Test assertion with non-existent directory
    run assert_dir_exists "$TEST_TEMP_DIR/nonexistent"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist" ]]
}

@test "assert_contains() passes when string contains substring" {
    # Test string containment assertion
    run assert_contains "hello world" "world"
    
    [ "$status" -eq 0 ]
}

@test "assert_contains() fails when string does not contain substring" {
    # Test string containment assertion failure
    run assert_contains "hello world" "foo"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not contain" ]]
}

@test "assert_equals() passes when values are equal" {
    # Test equality assertion
    run assert_equals "test" "test"
    
    [ "$status" -eq 0 ]
}

@test "assert_equals() fails when values are not equal" {
    # Test equality assertion failure
    run assert_equals "test" "different"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not equal" ]]
}

@test "create_test_file() creates file with content" {
    # Test file creation utility
    local test_file="$TEST_TEMP_DIR/created_file.txt"
    run create_test_file "$test_file" "test content"
    
    [ "$status" -eq 0 ]
    [ -f "$test_file" ]
    [ "$(cat "$test_file")" = "test content" ]
}

@test "create_test_symlink() creates valid symlink" {
    # Create source file
    local source="$TEST_TEMP_DIR/source.txt"
    echo "source content" > "$source"
    
    # Test symlink creation
    local symlink="$TEST_TEMP_DIR/symlink.txt"
    run create_test_symlink "$source" "$symlink"
    
    [ "$status" -eq 0 ]
    [ -L "$symlink" ]
    [ "$(readlink "$symlink")" = "$source" ]
    [ "$(cat "$symlink")" = "source content" ]
}

@test "mock_command() creates mock command that returns expected output" {
    # Test command mocking
    run mock_command "test_cmd" "mocked output"
    
    [ "$status" -eq 0 ]
    
    # Test the mocked command
    run test_cmd
    [ "$status" -eq 0 ]
    [ "$output" = "mocked output" ]
}

@test "restore_command() removes mock and restores original" {
    # First mock a command
    mock_command "echo" "mocked echo"
    
    # Test mocked version
    run echo "test"
    [ "$output" = "mocked echo" ]
    
    # Restore original
    run restore_command "echo"
    [ "$status" -eq 0 ]
    
    # Test restored version
    run echo "test"
    [ "$output" = "test" ]
}

@test "measure_execution_time() returns execution time" {
    # Test execution time measurement
    run measure_execution_time "sleep 0.1"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Execution time:" ]]
    [[ "$output" =~ "seconds" ]]
}

@test "with_timeout() succeeds within timeout" {
    # Test command execution with timeout
    run with_timeout 5 "echo 'success'"
    
    [ "$status" -eq 0 ]
    [ "$output" = "success" ]
}

@test "with_timeout() fails when command times out" {
    # Test timeout functionality
    run with_timeout 1 "sleep 2"
    
    [ "$status" -ne 0 ]
    [[ "$output" =~ "timeout" ]]
}

@test "retry_command() succeeds on first try" {
    # Test retry functionality with successful command
    run retry_command 3 "echo 'success'"
    
    [ "$status" -eq 0 ]
    [ "$output" = "success" ]
}

@test "retry_command() retries failing command" {
    # Create a command that fails first time, succeeds second
    local counter_file="$TEST_TEMP_DIR/counter"
    echo "0" > "$counter_file"
    
    local test_script="$TEST_TEMP_DIR/test_retry.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
counter_file="$1"
count=$(cat "$counter_file")
count=$((count + 1))
echo "$count" > "$counter_file"
if [ "$count" -eq 1 ]; then
    exit 1
else
    echo "success on attempt $count"
    exit 0
fi
EOF
    chmod +x "$test_script"
    
    # Test retry functionality
    run retry_command 3 "$test_script $counter_file"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "success on attempt 2" ]]
}