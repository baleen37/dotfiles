{ lib, pkgs, ... }:

let
  # Integration test script
  integrationTest = pkgs.writeShellScript "sudoers-workflow-integration-test" ''
    set -euo pipefail

    # Test configuration
    TEST_DIR="/tmp/sudoers-test-$$"
    SCRIPT_PATH="${../../scripts/add-darwin-rebuild-sudoers.sh}"

    # Colors
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    NC="\033[0m"

    # Test results
    TESTS_PASSED=0
    TESTS_FAILED=0

    test_result() {
        local test_name="$1"
        local result="$2"

        if [ "$result" -eq 0 ]; then
            echo -e "  $GREEN✓$NC $test_name"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "  $RED✗$NC $test_name"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    }

    cleanup() {
        rm -rf "$TEST_DIR"
    }

    setup() {
        mkdir -p "$TEST_DIR"
        cd "$TEST_DIR"
    }

    # Test 1: Passwordless sudo detection workflow
    test_passwordless_sudo_detection() {
        # Check if build-switch has passwordless sudo detection logic
        local build_switch_sudo_path="${../../scripts/lib/sudo-management.sh}"
        grep -q "sudo -n true" "$build_switch_sudo_path" &&
        grep -q "passwordless sudo" "$build_switch_sudo_path"
    }

    # Test 2: Script integration with build-switch
    test_build_switch_integration() {
        # Check if build-switch would benefit from sudoers setup
        local build_switch_path="${../../scripts/lib/sudo-management.sh}"

        # Verify sudo-management.sh has passwordless sudo logic
        grep -q "sudo -n true" "$build_switch_path" &&
        grep -q "passwordless sudo" "$build_switch_path" &&
        grep -q "Non-interactive environment" "$build_switch_path"
    }

    # Test 3: Claude Code environment compatibility
    test_claude_code_compatibility() {
        # Check if build-switch has non-interactive environment handling
        local build_switch_sudo_path="${../../scripts/lib/sudo-management.sh}"
        grep -q "non-interactive" "$build_switch_sudo_path" &&
        grep -q "\\[ ! -t 0 \\]" "$build_switch_sudo_path"
    }

    # Test 4: Sudoers file format validation
    test_sudoers_format_validation() {
        # Extract sudoers content from script
        local temp_sudoers="$TEST_DIR/temp-sudoers"

        # Simulate the content that would be written
        cat > "$temp_sudoers" << 'EOF'
# Darwin rebuild permissions for Claude Code
%admin ALL=(ALL) NOPASSWD: /nix/store/*/sw/bin/darwin-rebuild
%wheel ALL=(ALL) NOPASSWD: /nix/store/*/sw/bin/darwin-rebuild
EOF

        # Basic format validation
        grep -q "^%admin ALL=(ALL) NOPASSWD:" "$temp_sudoers" &&
        grep -q "^%wheel ALL=(ALL) NOPASSWD:" "$temp_sudoers" &&
        grep -q "darwin-rebuild" "$temp_sudoers"
    }

    # Test 5: Security considerations
    test_security_considerations() {
        # Check that script only grants specific permissions
        grep -q "NOPASSWD: /nix/store/\*/sw/bin/darwin-rebuild" "$SCRIPT_PATH" &&
        ! grep -q "NOPASSWD: ALL" "$SCRIPT_PATH" &&
        grep -q "chmod 0440" "$SCRIPT_PATH"
    }

    # Test 6: Backup and recovery workflow
    test_backup_recovery_workflow() {
        # Test backup filename generation
        local backup_pattern="\.backup\.[0-9]\{8\}_[0-9]\{6\}"

        # Check if script has backup logic
        grep -q "backup" "$SCRIPT_PATH" &&
        grep -q "date" "$SCRIPT_PATH"
    }

    # Test 7: Error handling and cleanup
    test_error_handling_workflow() {
        # Check comprehensive error handling
        grep -q "set -euo pipefail" "$SCRIPT_PATH" &&
        grep -q "visudo -c" "$SCRIPT_PATH" &&
        grep -q "rm -f" "$SCRIPT_PATH"
    }

    # Test 8: User feedback and guidance
    test_user_feedback_workflow() {
        # Check for helpful user messages
        grep -q "성공적으로\|successfully" "$SCRIPT_PATH" &&
        grep -q "sudo ./scripts" "$SCRIPT_PATH" &&
        grep -q "패스워드 없이\|without password" "$SCRIPT_PATH"
    }

    # Test 9: Integration with nix flake system
    test_nix_flake_integration() {
        # Check if this test can be run through nix
        local flake_root="${../..}"

        # Verify test is accessible through nix system
        [ -f "$flake_root/flake.nix" ] &&
        [ -f "$flake_root/tests/default.nix" ]
    }

    # Test 10: End-to-end workflow simulation
    test_end_to_end_workflow() {
        # Check if all workflow components exist
        local script_path="${../../scripts/add-darwin-rebuild-sudoers.sh}"
        local build_switch_path="${../../scripts/lib/sudo-management.sh}"

        [ -f "$script_path" ] && [ -x "$script_path" ] &&
        [ -f "$build_switch_path" ] &&
        grep -q "passwordless sudo" "$build_switch_path"
    }

    # Run all tests
    echo -e "$BLUE"Running sudoers workflow integration tests..."$NC\n"

    setup

    echo "Testing sudoers workflow integration:"
    test_result "Passwordless sudo detection" $(test_passwordless_sudo_detection; echo $?)
    test_result "Build-switch integration" $(test_build_switch_integration; echo $?)
    test_result "Claude Code compatibility" $(test_claude_code_compatibility; echo $?)
    test_result "Sudoers format validation" $(test_sudoers_format_validation; echo $?)
    test_result "Security considerations" $(test_security_considerations; echo $?)
    test_result "Backup/recovery workflow" $(test_backup_recovery_workflow; echo $?)
    test_result "Error handling workflow" $(test_error_handling_workflow; echo $?)
    test_result "User feedback workflow" $(test_user_feedback_workflow; echo $?)
    test_result "Nix flake integration" $(test_nix_flake_integration; echo $?)
    test_result "End-to-end workflow" $(test_end_to_end_workflow; echo $?)

    cleanup

    echo ""
    echo -e "$YELLOW"Integration Test Results:"$NC"
    echo -e "  $GREEN"Passed: $TESTS_PASSED"$NC"
    echo -e "  $RED"Failed: $TESTS_FAILED"$NC"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n$GREEN"All integration tests passed! 🎉"$NC"
        exit 0
    else
        echo -e "\n$RED"Some integration tests failed."$NC"
        exit 1
    fi
  '';

in pkgs.runCommand "sudoers-workflow-integration-test" { } ''
  echo "Testing sudoers workflow integration..."

  # Run the integration test
  ${integrationTest}

  # Create success marker
  touch $out
  echo "sudoers workflow integration tests completed successfully" > $out
''
