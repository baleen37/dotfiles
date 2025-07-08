{ lib, pkgs, ... }:

let
  # Test script path
  testScript = pkgs.writeShellScript "test-sudoers-script" ''
    set -euo pipefail

    # Test configuration
    TEST_SUDOERS_FILE="/tmp/test-darwin-rebuild"
    SCRIPT_PATH="${../../scripts/add-darwin-rebuild-sudoers.sh}"

    # Colors for output
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    NC="\033[0m"

    # Test result tracking
    TESTS_PASSED=0
    TESTS_FAILED=0

    # Helper functions
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
        rm -f "$TEST_SUDOERS_FILE"
        rm -f "$TEST_SUDOERS_FILE.backup."*
    }

    # Test 1: Script exists and is executable
    test_script_exists() {
        [ -f "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]
    }

    # Test 2: Script has proper shebang
    test_script_shebang() {
        head -n1 "$SCRIPT_PATH" | grep -q "#!/bin/bash"
    }

    # Test 3: Script contains expected sudoers content
    test_script_content() {
        grep -q "darwin-rebuild" "$SCRIPT_PATH" &&
        grep -q "%admin ALL=(ALL) NOPASSWD:" "$SCRIPT_PATH" &&
        grep -q "%wheel ALL=(ALL) NOPASSWD:" "$SCRIPT_PATH"
    }

    # Test 4: Script validates root privileges
    test_root_check() {
        # Check if script contains root privilege validation
        grep -q "EUID.*-ne.*0" "$SCRIPT_PATH" &&
        grep -q "sudo.*실행해야\|sudo.*execution" "$SCRIPT_PATH"
    }

    # Test 5: Script has backup functionality
    test_backup_logic() {
        grep -q "backup" "$SCRIPT_PATH" &&
        grep -q "date" "$SCRIPT_PATH"
    }

    # Test 6: Script has syntax validation
    test_syntax_validation() {
        grep -q "visudo -c" "$SCRIPT_PATH"
    }

    # Test 7: Script has proper error handling
    test_error_handling() {
        grep -q "set -euo pipefail" "$SCRIPT_PATH" &&
        grep -q "exit 1" "$SCRIPT_PATH"
    }

    # Test 8: Script creates correct file permissions
    test_permissions_logic() {
        grep -q "chmod 0440" "$SCRIPT_PATH"
    }

    # Test 9: Script has proper cleanup on failure
    test_cleanup_logic() {
        grep -q "rm -f" "$SCRIPT_PATH"
    }

    # Test 10: Script provides user feedback
    test_user_feedback() {
        grep -q "echo" "$SCRIPT_PATH" &&
        grep -q "✅\|성공" "$SCRIPT_PATH"
    }

    # Mock sudoers content validation
    test_sudoers_content_format() {
        # Check if script contains proper sudoers content structure
        grep -q "SUDOERS_CONTENT=" "$SCRIPT_PATH" &&
        grep -q "Claude Code" "$SCRIPT_PATH" &&
        grep -q "%admin.*NOPASSWD.*darwin-rebuild" "$SCRIPT_PATH" &&
        grep -q "%wheel.*NOPASSWD.*darwin-rebuild" "$SCRIPT_PATH"
    }

    # Run all tests
    echo -e "$YELLOW"Running sudoers script tests..."$NC\n"

    cleanup

    echo "Testing script structure and content:"
    test_result "Script exists and is executable" $(test_script_exists; echo $?)
    test_result "Script has proper shebang" $(test_script_shebang; echo $?)
    test_result "Script contains expected content" $(test_script_content; echo $?)
    test_result "Script validates root privileges" $(test_root_check; echo $?)
    test_result "Script has backup functionality" $(test_backup_logic; echo $?)
    test_result "Script has syntax validation" $(test_syntax_validation; echo $?)
    test_result "Script has proper error handling" $(test_error_handling; echo $?)
    test_result "Script creates correct permissions" $(test_permissions_logic; echo $?)
    test_result "Script has cleanup on failure" $(test_cleanup_logic; echo $?)
    test_result "Script provides user feedback" $(test_user_feedback; echo $?)
    test_result "Sudoers content format is correct" $(test_sudoers_content_format; echo $?)

    cleanup

    echo ""
    echo -e "$YELLOW"Test Results:"$NC"
    echo -e "  $GREEN"Passed: $TESTS_PASSED"$NC"
    echo -e "  $RED"Failed: $TESTS_FAILED"$NC"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n$GREEN"All tests passed! 🎉"$NC"
        exit 0
    else
        echo -e "\n$RED"Some tests failed. Please check the script."$NC"
        exit 1
    fi
  '';

in pkgs.runCommand "sudoers-script-test" { } ''
  echo "Testing sudoers script functionality..."

  # Run the test script
  ${testScript}

  # Create success marker
  touch $out
  echo "sudoers script tests completed successfully" > $out
''
