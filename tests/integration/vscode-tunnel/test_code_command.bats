#!/usr/bin/env bats
# T008: Code command execution test
# Tests `code` command functionality through VSCode tunnel

load "test_helper_systemd.bats"

setup() {
    setup_systemd_test
    source "${BATS_TEST_DIRNAME}/test_environment_setup.sh"
    setup_mock_nixos_environment
}

teardown() {
    cleanup_systemd_test
    cleanup_mock_nixos_environment
}

@test "code command should be available after service starts" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Code command should be available in PATH
    assert_command_exists "code"
}

@test "code command should connect to tunnel instance" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Test code command execution
    timeout 10 code --help >/dev/null 2>&1 || {
        echo "Expected code command to respond within 10 seconds" >&2
        return 1
    }
}

@test "code command should open files in remote VSCode" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Create test file
    local test_file="/tmp/vscode-tunnel-test.txt"
    echo "Test content" > "${test_file}"

    # Open file with code command
    timeout 10 code "${test_file}" &
    local code_pid=$!

    # Wait briefly for command to process
    sleep 2

    # Command should complete successfully
    wait ${code_pid} || {
        echo "Expected code command to execute successfully" >&2
        return 1
    }

    # Clean up
    rm -f "${test_file}"
}

@test "code command should open directories in remote VSCode" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Create test directory
    local test_dir="/tmp/vscode-tunnel-test-dir"
    mkdir -p "${test_dir}"
    echo "Test file" > "${test_dir}/test.txt"

    # Open directory with code command
    timeout 10 code "${test_dir}" &
    local code_pid=$!

    # Wait briefly for command to process
    sleep 2

    # Command should complete successfully
    wait ${code_pid} || {
        echo "Expected code command to open directory successfully" >&2
        return 1
    }

    # Clean up
    rm -rf "${test_dir}"
}

@test "code command should work from SSH sessions" {
    # This test MUST FAIL until implementation is complete
    skip_if_ci "SSH testing requires special setup"

    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Simulate SSH session by setting SSH environment variables
    export SSH_TTY="/dev/pts/0"
    export SSH_CONNECTION="192.168.1.100 52234 192.168.1.1 22"

    # Code command should still work in SSH context
    timeout 10 code --help >/dev/null 2>&1 || {
        echo "Expected code command to work in SSH session" >&2
        return 1
    }

    unset SSH_TTY SSH_CONNECTION
}

@test "code command should handle multiple simultaneous invocations" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Create multiple test files
    local test_files=()
    for i in {1..3}; do
        local test_file="/tmp/vscode-tunnel-test-${i}.txt"
        echo "Test content ${i}" > "${test_file}"
        test_files+=("${test_file}")
    done

    # Launch multiple code commands simultaneously
    local pids=()
    for file in "${test_files[@]}"; do
        timeout 10 code "${file}" &
        pids+=($!)
    done

    # Wait for all commands to complete
    local failed=0
    for pid in "${pids[@]}"; do
        wait ${pid} || ((failed++))
    done

    [[ ${failed} -eq 0 ]] || {
        echo "Expected all code commands to succeed, ${failed} failed" >&2
        return 1
    }

    # Clean up
    rm -f "${test_files[@]}"
}

@test "code command should provide useful error messages" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Try code command before tunnel is established (should fail gracefully)
    local error_output
    error_output=$(code --non-existent-flag 2>&1 || true)

    [[ -n "${error_output}" ]] || {
        echo "Expected error message from code command with invalid flag" >&2
        return 1
    }

    # Error message should be informative
    echo "${error_output}" | grep -qE "(usage|help|option|flag)" || {
        echo "Expected informative error message, got: ${error_output}" >&2
        return 1
    }
}

@test "code command should handle non-existent files gracefully" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    local non_existent_file="/tmp/this-file-does-not-exist-$(date +%s).txt"

    # Code command should handle non-existent file gracefully
    timeout 10 code "${non_existent_file}" &
    local code_pid=$!

    # Wait for command to process
    sleep 2

    # Command should complete (VSCode will create new file)
    wait ${code_pid} || {
        echo "Expected code command to handle non-existent file gracefully" >&2
        return 1
    }
}

@test "code command should respect VSCode CLI flags" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Test --version flag
    local version_output
    version_output=$(timeout 10 code --version 2>/dev/null)

    [[ -n "${version_output}" ]] || {
        echo "Expected code --version to produce output" >&2
        return 1
    }

    # Version output should contain version number
    echo "${version_output}" | grep -qE "[0-9]+\.[0-9]+\.[0-9]+" || {
        echo "Expected version number in output: ${version_output}" >&2
        return 1
    }
}

@test "code command should work with relative paths" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Create test file in current directory
    local test_file="vscode-tunnel-test-relative.txt"
    echo "Relative path test" > "${test_file}"

    # Open file with relative path
    timeout 10 code "${test_file}" &
    local code_pid=$!

    # Wait for command to process
    sleep 2

    # Command should complete successfully
    wait ${code_pid} || {
        echo "Expected code command to work with relative paths" >&2
        return 1
    }

    # Clean up
    rm -f "${test_file}"
}

@test "code command should inherit current working directory" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for tunnel establishment
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

    # Create test directory and change to it
    local test_dir="/tmp/vscode-tunnel-cwd-test"
    mkdir -p "${test_dir}"
    cd "${test_dir}"

    # Create test file
    echo "CWD test" > "test.txt"

    # Open current directory
    timeout 10 code . &
    local code_pid=$!

    # Wait for command to process
    sleep 2

    # Command should complete successfully
    wait ${code_pid} || {
        echo "Expected code command to work with current directory" >&2
        return 1
    }

    # Return to original directory and clean up
    cd - >/dev/null
    rm -rf "${test_dir}"
}
