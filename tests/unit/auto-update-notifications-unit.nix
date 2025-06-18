# Auto Update Notifications Unit Tests - Phase 1.2
#
# This file contains comprehensive unit tests for the notification file management system.
# Tests follow TDD approach: write failing tests first, then implement minimal functionality.

{ pkgs, config ? {}, ... }:

let
  # Import notification management library (to be created)
  notificationLib = import ../../lib/auto-update-notifications.nix { inherit pkgs; };

  # Import state management library from Phase 1.1
  stateLib = import ../../lib/auto-update-state.nix { inherit pkgs; };

  # Test utilities and constants
  testCommitHash = "abc123def456";
  testCommitHash2 = "789xyz012uvw";
  testCacheDir = "/tmp/dotfiles-test-cache-$$";
  testNotificationsDir = "${testCacheDir}/.cache/dotfiles-updates";
  testNotificationFile = "${testNotificationsDir}/pending-${testCommitHash}.json";

  # Test runner script
  runTests = pkgs.writeShellScript "auto-update-notifications-unit-tests" ''
    set -euo pipefail

    # Setup test environment
    export HOME="${testCacheDir}"
    export CACHE_DIR="${testCacheDir}"

    # Debug output
    echo "Test environment:"
    echo "  HOME: $HOME"
    echo "  CACHE_DIR: $CACHE_DIR"
    echo "  Notification dir: ${testNotificationsDir}"

    # Colors for test output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    PASSED=0
    FAILED=0

    log_test() {
        echo -e "  $1"
    }

    log_pass() {
        echo -e "  ''${GREEN}✓''${NC} $1"
        ((PASSED++))
    }

    log_fail() {
        echo -e "  ''${RED}✗''${NC} $1"
        ((FAILED++))
    }

    log_section() {
        echo -e "\n''${YELLOW}=== $1 ===''${NC}"
    }

    # Setup function - clean environment for each test
    setup() {
        rm -rf "${testCacheDir}" 2>/dev/null || true
        mkdir -p "${testCacheDir}"
        mkdir -p "${testNotificationsDir}"
    }

    # Teardown function
    teardown() {
        rm -rf "${testCacheDir}" 2>/dev/null || true
    }

    # Test 1: Notification File Creation
    log_section "Test 1: Notification File Creation"

    test_notification_file_creation() {
        setup

        # Test basic notification creation
        if ${notificationLib}/bin/create_notification "${testCommitHash}" "Test update message" "feat: add new feature"; then
            if [[ -f "${testNotificationFile}" ]]; then
                log_pass "Notification file created successfully"
            else
                log_fail "Notification file was not created"
                return 1
            fi
        else
            log_fail "create_notification command failed"
            return 1
        fi

        # Test notification file format
        local content=$(cat "${testNotificationFile}")
        if echo "$content" | jq empty 2>/dev/null; then
            log_pass "Notification file contains valid JSON"
        else
            log_fail "Notification file does not contain valid JSON"
            return 1
        fi

        # Test required fields
        local commit_hash=$(echo "$content" | jq -r '.commit_hash // empty')
        local timestamp=$(echo "$content" | jq -r '.timestamp // empty')
        local summary=$(echo "$content" | jq -r '.summary // empty')
        local message=$(echo "$content" | jq -r '.message // empty')

        if [[ "$commit_hash" == "${testCommitHash}" ]]; then
            log_pass "Commit hash field is correct"
        else
            log_fail "Commit hash field is missing or incorrect"
            return 1
        fi

        if [[ -n "$timestamp" ]] && [[ "$timestamp" =~ ^[0-9]+$ ]]; then
            log_pass "Timestamp field is valid"
        else
            log_fail "Timestamp field is missing or invalid"
            return 1
        fi

        if [[ "$summary" == "Test update message" ]]; then
            log_pass "Summary field is correct"
        else
            log_fail "Summary field is missing or incorrect"
            return 1
        fi

        if [[ "$message" == "feat: add new feature" ]]; then
            log_pass "Message field is correct"
        else
            log_fail "Message field is missing or incorrect"
            return 1
        fi

        teardown
    }

    # Test 2: Duplicate Prevention
    log_section "Test 2: Duplicate Notification Prevention"

    test_duplicate_prevention() {
        setup

        # Create initial notification
        ${notificationLib}/bin/create_notification "${testCommitHash}" "First message" "feat: first commit"
        local first_timestamp=$(cat "${testNotificationFile}" | jq -r '.timestamp')

        # Wait a moment to ensure timestamp would be different
        sleep 1

        # Try to create duplicate notification
        if ${notificationLib}/bin/create_notification "${testCommitHash}" "Second message" "feat: second commit"; then
            log_fail "Duplicate notification creation should have been prevented"
            return 1
        else
            log_pass "Duplicate notification creation was prevented"
        fi

        # Verify original notification is unchanged
        local current_timestamp=$(cat "${testNotificationFile}" | jq -r '.timestamp')
        local current_summary=$(cat "${testNotificationFile}" | jq -r '.summary')

        if [[ "$current_timestamp" == "$first_timestamp" ]]; then
            log_pass "Original notification timestamp preserved"
        else
            log_fail "Original notification was modified"
            return 1
        fi

        if [[ "$current_summary" == "First message" ]]; then
            log_pass "Original notification content preserved"
        else
            log_fail "Original notification content was changed"
            return 1
        fi

        teardown
    }

    # Test 3: Notification Cleanup
    log_section "Test 3: Notification Cleanup"

    test_notification_cleanup() {
        setup

        # Create multiple notifications
        ${notificationLib}/bin/create_notification "${testCommitHash}" "Message 1" "feat: commit 1"
        ${notificationLib}/bin/create_notification "${testCommitHash2}" "Message 2" "feat: commit 2"

        # Verify both files exist
        local file1="${testNotificationsDir}/pending-${testCommitHash}.json"
        local file2="${testNotificationsDir}/pending-${testCommitHash2}.json"

        if [[ -f "$file1" ]] && [[ -f "$file2" ]]; then
            log_pass "Multiple notification files created"
        else
            log_fail "Failed to create multiple notification files"
            return 1
        fi

        # Clean up specific notification
        if ${notificationLib}/bin/cleanup_notification "${testCommitHash}"; then
            log_pass "Cleanup command executed successfully"
        else
            log_fail "Cleanup command failed"
            return 1
        fi

        # Verify targeted cleanup
        if [[ ! -f "$file1" ]] && [[ -f "$file2" ]]; then
            log_pass "Specific notification was cleaned up"
        else
            log_fail "Cleanup did not work correctly"
            return 1
        fi

        teardown
    }

    # Test 4: Error Handling
    log_section "Test 4: Error Handling"

    test_error_handling() {
        setup

        # Test invalid parameters
        if ! ${notificationLib}/bin/create_notification "" "message" "commit"; then
            log_pass "Empty commit hash is rejected"
        else
            log_fail "Empty commit hash should be rejected"
        fi

        if ! ${notificationLib}/bin/create_notification "abc123" "" "commit"; then
            log_pass "Empty summary is rejected"
        else
            log_fail "Empty summary should be rejected"
        fi

        if ! ${notificationLib}/bin/create_notification "abc123" "message" ""; then
            log_pass "Empty message is rejected"
        else
            log_fail "Empty message should be rejected"
        fi

        # Test permission errors (simulate by creating read-only directory)
        mkdir -p "${testNotificationsDir}"
        chmod 444 "${testNotificationsDir}"

        if ! ${notificationLib}/bin/create_notification "test123" "test" "test" 2>/dev/null; then
            log_pass "Permission errors are handled gracefully"
        else
            log_fail "Permission errors should be handled"
        fi

        # Restore permissions for cleanup
        chmod 755 "${testNotificationsDir}"

        teardown
    }

    # Test 5: Integration with State Management
    log_section "Test 5: Integration with State Management"

    test_state_integration() {
        setup

        # Create notification and verify state integration
        ${notificationLib}/bin/create_notification "${testCommitHash}" "Integration test" "feat: state integration"

        # Check if pending update is tracked in state
        local state_content=$(${stateLib}/bin/get_state)
        local pending_updates=$(echo "$state_content" | jq -r '.pending_updates // {}')

        if echo "$pending_updates" | jq -e ".\"${testCommitHash}\"" >/dev/null 2>&1; then
            log_pass "Notification is tracked in state management"
        else
            log_fail "Notification is not tracked in state management"
            return 1
        fi

        # Test cleanup integration
        ${notificationLib}/bin/cleanup_notification "${testCommitHash}"

        # Verify state is updated after cleanup
        local updated_state=$(${stateLib}/bin/get_state)
        local updated_pending=$(echo "$updated_state" | jq -r '.pending_updates // {}')

        if ! echo "$updated_pending" | jq -e ".\"${testCommitHash}\"" >/dev/null 2>&1; then
            log_pass "State is updated after notification cleanup"
        else
            log_fail "State was not updated after cleanup"
            return 1
        fi

        teardown
    }

    # Test 6: Old Notification Cleanup
    log_section "Test 6: Old Notification Cleanup"

    test_old_notification_cleanup() {
        setup

        # Create old notification by manually creating file with old timestamp
        local old_timestamp=$(($(date +%s) - 31 * 24 * 3600)) # 31 days ago
        local old_notification='{"commit_hash":"old123","timestamp":'$old_timestamp',"summary":"Old update","message":"feat: old"}'
        local old_file="${testNotificationsDir}/pending-old123.json"
        echo "$old_notification" > "$old_file"

        # Create recent notification
        ${notificationLib}/bin/create_notification "${testCommitHash}" "Recent update" "feat: recent"

        # Run cleanup
        if ${notificationLib}/bin/cleanup_old_notifications 30; then
            log_pass "Old notification cleanup executed"
        else
            log_fail "Old notification cleanup failed"
            return 1
        fi

        # Verify old notification is removed and recent is kept
        if [[ ! -f "$old_file" ]] && [[ -f "${testNotificationFile}" ]]; then
            log_pass "Old notifications cleaned up, recent ones preserved"
        else
            log_fail "Old notification cleanup did not work correctly"
            return 1
        fi

        teardown
    }

    # Run all tests
    echo "Running Auto Update Notifications Unit Tests..."

    test_notification_file_creation
    test_duplicate_prevention
    test_notification_cleanup
    test_error_handling
    test_state_integration
    test_old_notification_cleanup

    # Summary
    echo
    if [[ $FAILED -eq 0 ]]; then
        echo -e "''${GREEN}All tests passed!''${NC} ($PASSED passed, $FAILED failed)"
        exit 0
    else
        echo -e "''${RED}Some tests failed.''${NC} ($PASSED passed, $FAILED failed)"
        exit 1
    fi
  '';

in
runTests
