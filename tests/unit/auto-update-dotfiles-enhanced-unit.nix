{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  autoUpdateScript = "${src}/scripts/auto-update-dotfiles";
in
pkgs.runCommand "auto-update-dotfiles-enhanced-unit-test"
{
  buildInputs = with pkgs; [ git coreutils bash ];
} ''
    ${testHelpers.setupTestEnv}

    ${testHelpers.testSection "Auto-Update Dotfiles Enhanced Unit Tests"}

    # Create test git repository
    TEST_REPO="$HOME/test-dotfiles"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"

    # Initialize git repo
    git init --initial-branch=main
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create initial commit
    echo "# Test Dotfiles" > README.md
    git add README.md
    git commit -m "Initial commit"

    # Copy auto-update script to test location
    mkdir -p "$TEST_REPO/scripts"
    cp "${autoUpdateScript}" "$TEST_REPO/scripts/auto-update-dotfiles"
    chmod +x "$TEST_REPO/scripts/auto-update-dotfiles"

    # Test 1: Sudo Permission Handling (TDD - This should FAIL initially)
    ${testHelpers.testSubsection "Sudo Permission Handling"}

    create_sudo_test_function() {
      cat > "$TEST_REPO/test_sudo_handling.sh" << 'SUDO_EOF'
#!/bin/bash
# Test sudo permission handling in auto-update script

# Mock sudo command that fails without proper setup
mock_build_switch() {
    case "$1" in
        "with_sudo")
            # Simulate successful sudo execution
            echo "SUDO_SUCCESS"
            ;;
        "without_sudo")
            # Simulate failed execution without sudo
            echo "PERMISSION_DENIED" >&2
            return 1
            ;;
        "check_sudo_availability")
            # Check if sudo is available and configured
            if command -v sudo >/dev/null 2>&1; then
                echo "SUDO_AVAILABLE"
            else
                echo "SUDO_NOT_AVAILABLE"
            fi
            ;;
        *)
            echo "Usage: mock_build_switch {with_sudo|without_sudo|check_sudo_availability}"
            return 1
            ;;
    esac
}

# Extract build-switch execution logic from auto-update script
perform_build_switch_test() {
    local test_scenario="$1"

    case "$test_scenario" in
        "permission_check")
            # Test if script checks for sudo requirements before execution
            # This should FAIL initially as the script doesn't check sudo requirements
            if grep -q "sudo.*build-switch\|check.*sudo\|require.*sudo\|command.*sudo" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "SUDO_CHECK_EXISTS"
            else
                echo "SUDO_CHECK_MISSING"
            fi
            ;;
        "error_recovery")
            # Test if script gracefully handles sudo failures
            # This should FAIL initially as there's no proper error recovery
            mock_build_switch "without_sudo" 2>/dev/null || echo "SUDO_FAILURE_DETECTED"
            ;;
        *)
            echo "Usage: perform_build_switch_test {permission_check|error_recovery}"
            return 1
            ;;
    esac
}

TEST_REPO="$TEST_REPO" perform_build_switch_test "$1"
SUDO_EOF
      chmod +x "$TEST_REPO/test_sudo_handling.sh"
    }

    create_sudo_test_function
    cd "$TEST_REPO"

    # Test 1.1: Script should check for sudo requirements (EXPECTED TO FAIL)
    SUDO_RESULT=$(./test_sudo_handling.sh permission_check)
    if [ "$SUDO_RESULT" = "SUDO_CHECK_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script properly checks sudo requirements"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks sudo requirement checks (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 2: Branch State Recovery (TDD - This should FAIL initially)
    ${testHelpers.testSubsection "Branch State Recovery"}

    create_branch_recovery_test_function() {
      cat > "$TEST_REPO/test_branch_recovery.sh" << 'BRANCH_EOF'
#!/bin/bash
# Test branch state recovery in auto-update script

# Create a feature branch for testing
git checkout -b feature/test-branch 2>/dev/null

# Mock auto-update logic that switches to main
simulate_auto_update() {
    local original_branch=$(git branch --show-current)
    echo "ORIGINAL_BRANCH: $original_branch"

    # Switch to main (simulating auto-update behavior)
    git checkout main --quiet 2>/dev/null
    echo "SWITCHED_TO: $(git branch --show-current)"

    # Check if script has logic to restore original branch
    # This should FAIL initially as the script doesn't restore the original branch
    if grep -q "git checkout.*original\|restore.*branch\|return.*branch\|ORIGINAL_BRANCH\|cleanup.*branch" "$TEST_REPO/scripts/auto-update-dotfiles"; then
        echo "BRANCH_RECOVERY_EXISTS"
        # Mock restoration
        git checkout "$original_branch" --quiet 2>/dev/null
        echo "RESTORED_TO: $(git branch --show-current)"
    else
        echo "BRANCH_RECOVERY_MISSING"
        echo "FINAL_BRANCH: $(git branch --show-current)"
    fi
}

case "$1" in
    "test_recovery")
        simulate_auto_update
        ;;
    "check_current_branch")
        echo "CURRENT_BRANCH: $(git branch --show-current)"
        ;;
    *)
        echo "Usage: $0 {test_recovery|check_current_branch}"
        exit 1
        ;;
esac
BRANCH_EOF
      chmod +x "$TEST_REPO/test_branch_recovery.sh"
    }

    create_branch_recovery_test_function
    cd "$TEST_REPO"

    # Test 2.1: Script should restore original branch after update (EXPECTED TO FAIL)
    BRANCH_RESULT=$(./test_branch_recovery.sh test_recovery)
    if echo "$BRANCH_RESULT" | grep -q "BRANCH_RECOVERY_EXISTS"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script properly restores original branch"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks branch recovery logic (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 3: Network Retry Logic (TDD - This should FAIL initially)
    ${testHelpers.testSubsection "Network Retry Logic"}

    create_network_retry_test_function() {
      cat > "$TEST_REPO/test_network_retry.sh" << 'NETWORK_EOF'
#!/bin/bash
# Test network retry logic in auto-update script

# Test network failure scenarios
test_network_retry() {
    local test_scenario="$1"

    case "$test_scenario" in
        "check_retry_logic")
            # Check if script has retry logic for git fetch failures
            # This should FAIL initially as the script doesn't have retry logic
            if grep -q "retry\|attempt\|for.*in.*{1\|while.*fail\|MAX_RETRY_ATTEMPTS\|retry.*logic" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "RETRY_LOGIC_EXISTS"
            else
                echo "RETRY_LOGIC_MISSING"
            fi
            ;;
        "check_timeout_handling")
            # Check if script has timeout handling
            # This should FAIL initially as the script doesn't handle timeouts
            if grep -q "timeout\|--timeout\|TIMEOUT\|NETWORK_TIMEOUT" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "TIMEOUT_HANDLING_EXISTS"
            else
                echo "TIMEOUT_HANDLING_MISSING"
            fi
            ;;
        "check_fallback_strategy")
            # Check if script has fallback strategies for network failures
            # This should FAIL initially as the script doesn't have fallback strategies
            if grep -q "fallback\|alternative\|backup.*remote" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "FALLBACK_STRATEGY_EXISTS"
            else
                echo "FALLBACK_STRATEGY_MISSING"
            fi
            ;;
        *)
            echo "Usage: test_network_retry {check_retry_logic|check_timeout_handling|check_fallback_strategy}"
            return 1
            ;;
    esac
}

test_network_retry "$1"
NETWORK_EOF
      chmod +x "$TEST_REPO/test_network_retry.sh"
    }

    create_network_retry_test_function
    cd "$TEST_REPO"

    # Test 3.1: Script should have retry logic for network failures (EXPECTED TO FAIL)
    NETWORK_RESULT=$(./test_network_retry.sh check_retry_logic)
    if [ "$NETWORK_RESULT" = "RETRY_LOGIC_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script has network retry logic"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks network retry logic (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 3.2: Script should handle timeouts (EXPECTED TO FAIL)
    TIMEOUT_RESULT=$(./test_network_retry.sh check_timeout_handling)
    if [ "$TIMEOUT_RESULT" = "TIMEOUT_HANDLING_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script has timeout handling"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks timeout handling (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 4: Silent Mode Error Handling (TDD - This should FAIL initially)
    ${testHelpers.testSubsection "Silent Mode Error Handling"}

    create_silent_mode_test_function() {
      cat > "$TEST_REPO/test_silent_mode.sh" << 'SILENT_EOF'
#!/bin/bash
# Test silent mode error handling in auto-update script

test_silent_mode_errors() {
    local test_scenario="$1"

    case "$test_scenario" in
        "check_error_logging")
            # Check if script logs errors even in silent mode
            # This should FAIL initially as the script may not log errors properly in silent mode
            if grep -q "silent.*log\|log.*silent\|2>>\|CRITICAL.*silent\|exec.*LOG_FILE" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "SILENT_ERROR_LOGGING_EXISTS"
            else
                echo "SILENT_ERROR_LOGGING_MISSING"
            fi
            ;;
        "check_critical_error_notification")
            # Check if script notifies about critical errors even in silent mode
            # This should FAIL initially as the script may suppress all output in silent mode
            if grep -A 10 -B 10 "silent_mode.*true" "$TEST_REPO/scripts/auto-update-dotfiles" | grep -q "critical\|important\|notify"; then
                echo "CRITICAL_ERROR_NOTIFICATION_EXISTS"
            else
                echo "CRITICAL_ERROR_NOTIFICATION_MISSING"
            fi
            ;;
        "check_background_error_handling")
            # Check if script properly handles errors when running in background
            # This should FAIL initially as background execution may lose error context
            if grep -q "background.*error\|&.*error\|\$!.*error" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "BACKGROUND_ERROR_HANDLING_EXISTS"
            else
                echo "BACKGROUND_ERROR_HANDLING_MISSING"
            fi
            ;;
        *)
            echo "Usage: test_silent_mode_errors {check_error_logging|check_critical_error_notification|check_background_error_handling}"
            return 1
            ;;
    esac
}

test_silent_mode_errors "$1"
SILENT_EOF
      chmod +x "$TEST_REPO/test_silent_mode.sh"
    }

    create_silent_mode_test_function
    cd "$TEST_REPO"

    # Test 4.1: Script should log errors even in silent mode (EXPECTED TO FAIL)
    SILENT_RESULT=$(./test_silent_mode.sh check_error_logging)
    if [ "$SILENT_RESULT" = "SILENT_ERROR_LOGGING_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script logs errors in silent mode"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks silent mode error logging (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 4.2: Script should handle critical errors in silent mode (EXPECTED TO FAIL)
    CRITICAL_RESULT=$(./test_silent_mode.sh check_critical_error_notification)
    if [ "$CRITICAL_RESULT" = "CRITICAL_ERROR_NOTIFICATION_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script handles critical errors in silent mode"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks critical error handling in silent mode (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 5: Lock File Management (TDD - This should FAIL initially)
    ${testHelpers.testSubsection "Lock File Management"}

    create_lock_file_test_function() {
      cat > "$TEST_REPO/test_lock_file.sh" << 'LOCK_EOF'
#!/bin/bash
# Test lock file management in auto-update script

test_lock_file_management() {
    local test_scenario="$1"

    case "$test_scenario" in
        "check_lock_file_creation")
            # Check if script creates lock file to prevent concurrent executions
            # This should FAIL initially as the script doesn't use lock files
            if grep -q "lock.*file\|\.lock\|flock\|lockfile\|LOCK_FILE\|acquire_lock" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "LOCK_FILE_CREATION_EXISTS"
            else
                echo "LOCK_FILE_CREATION_MISSING"
            fi
            ;;
        "check_lock_file_cleanup")
            # Check if script properly cleans up lock files
            # This should FAIL initially as the script doesn't manage lock files
            if grep -q "trap.*rm.*lock\|cleanup.*lock\|rm.*\.lock" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "LOCK_FILE_CLEANUP_EXISTS"
            else
                echo "LOCK_FILE_CLEANUP_MISSING"
            fi
            ;;
        "check_concurrent_execution_prevention")
            # Check if script prevents concurrent executions
            # This should FAIL initially as the script doesn't prevent concurrent executions
            if grep -q "already.*running\|concurrent\|process.*check\|pidof\|prevent.*concurrent\|acquire_lock" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "CONCURRENT_PREVENTION_EXISTS"
            else
                echo "CONCURRENT_PREVENTION_MISSING"
            fi
            ;;
        *)
            echo "Usage: test_lock_file_management {check_lock_file_creation|check_lock_file_cleanup|check_concurrent_execution_prevention}"
            return 1
            ;;
    esac
}

test_lock_file_management "$1"
LOCK_EOF
      chmod +x "$TEST_REPO/test_lock_file.sh"
    }

    create_lock_file_test_function
    cd "$TEST_REPO"

    # Test 5.1: Script should use lock files (EXPECTED TO FAIL)
    LOCK_RESULT=$(./test_lock_file.sh check_lock_file_creation)
    if [ "$LOCK_RESULT" = "LOCK_FILE_CREATION_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script uses lock files"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks lock file management (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 5.2: Script should prevent concurrent executions (EXPECTED TO FAIL)
    CONCURRENT_RESULT=$(./test_lock_file.sh check_concurrent_execution_prevention)
    if [ "$CONCURRENT_RESULT" = "CONCURRENT_PREVENTION_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script prevents concurrent executions"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks concurrent execution prevention (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 6: Rollback Capability (TDD - This should FAIL initially)
    ${testHelpers.testSubsection "Rollback Capability"}

    create_rollback_test_function() {
      cat > "$TEST_REPO/test_rollback.sh" << 'ROLLBACK_EOF'
#!/bin/bash
# Test rollback capability in auto-update script

test_rollback_capability() {
    local test_scenario="$1"

    case "$test_scenario" in
        "check_backup_creation")
            # Check if script creates backup before update
            # This should FAIL initially as the script doesn't create backups
            if grep -q "backup\|\.bak\|snapshot\|save.*state\|create_backup\|BACKUP_DIR" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "BACKUP_CREATION_EXISTS"
            else
                echo "BACKUP_CREATION_MISSING"
            fi
            ;;
        "check_rollback_on_failure")
            # Check if script has rollback mechanism on failure
            # This should FAIL initially as the script doesn't have rollback capability
            if grep -q "rollback\|revert\|restore.*previous\|undo\|rollback_on_failure" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "ROLLBACK_ON_FAILURE_EXISTS"
            else
                echo "ROLLBACK_ON_FAILURE_MISSING"
            fi
            ;;
        "check_state_validation")
            # Check if script validates system state after update
            # This should FAIL initially as the script doesn't validate state
            if grep -q "validate\|verify.*state\|check.*system\|test.*config\|validate_system_state" "$TEST_REPO/scripts/auto-update-dotfiles"; then
                echo "STATE_VALIDATION_EXISTS"
            else
                echo "STATE_VALIDATION_MISSING"
            fi
            ;;
        *)
            echo "Usage: test_rollback_capability {check_backup_creation|check_rollback_on_failure|check_state_validation}"
            return 1
            ;;
    esac
}

test_rollback_capability "$1"
ROLLBACK_EOF
      chmod +x "$TEST_REPO/test_rollback.sh"
    }

    create_rollback_test_function
    cd "$TEST_REPO"

    # Test 6.1: Script should create backups (EXPECTED TO FAIL)
    BACKUP_RESULT=$(./test_rollback.sh check_backup_creation)
    if [ "$BACKUP_RESULT" = "BACKUP_CREATION_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script creates backups"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks backup creation (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    # Test 6.2: Script should have rollback capability (EXPECTED TO FAIL)
    ROLLBACK_RESULT=$(./test_rollback.sh check_rollback_on_failure)
    if [ "$ROLLBACK_RESULT" = "ROLLBACK_ON_FAILURE_EXISTS" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script has rollback capability"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script lacks rollback capability (EXPECTED FAILURE - TDD)"
      # This is expected to fail - TDD approach
    fi

    ${testHelpers.cleanup}

    # Clean up test repository
    cd "$HOME"
    rm -rf "$TEST_REPO"

    echo ""
    echo "${testHelpers.colors.blue}=== TDD Test Results: Enhanced Auto-Update Tests ===${testHelpers.colors.reset}"
    echo "${testHelpers.colors.yellow}⚠ Expected Failures (TDD Approach):${testHelpers.colors.reset}"
    echo "${testHelpers.colors.red}  - Sudo requirement checks${testHelpers.colors.reset}"
    echo "${testHelpers.colors.red}  - Branch state recovery${testHelpers.colors.reset}"
    echo "${testHelpers.colors.red}  - Network retry logic${testHelpers.colors.reset}"
    echo "${testHelpers.colors.red}  - Silent mode error handling${testHelpers.colors.reset}"
    echo "${testHelpers.colors.red}  - Lock file management${testHelpers.colors.reset}"
    echo "${testHelpers.colors.red}  - Rollback capability${testHelpers.colors.reset}"
    echo ""
    echo "${testHelpers.colors.blue}These failures identify areas for improvement in the auto-update script.${testHelpers.colors.reset}"
    touch $out
''
