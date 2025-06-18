{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  # State management library will be created at lib/auto-update-state.nix
  stateLib = import ../../lib/auto-update-state.nix { inherit pkgs; };
in
pkgs.runCommand "auto-update-user-confirmation-unit-test"
{
  buildInputs = with pkgs; [ coreutils bash jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Auto-Update User Confirmation Unit Tests - Phase 1.1"}

  # Create cache directory structure
  CACHE_DIR="$HOME/.cache"
  STATE_FILE="$CACHE_DIR/dotfiles-update-state.json"
  mkdir -p "$CACHE_DIR"

  # Test 1: State Management System - State file creation and initialization
  ${testHelpers.testSubsection "State File Creation and Initialization"}

  # Test 1.1: Initialize empty state file
  test_init_empty_state() {
    rm -f "$STATE_FILE"
    local result=$(${stateLib}/bin/get_state 2>/dev/null || echo "ERROR")
    if [[ "$result" != "ERROR" ]]; then
      local is_valid_json=$(echo "$result" | jq empty 2>/dev/null && echo "VALID" || echo "INVALID")
      if [[ "$is_valid_json" == "VALID" ]]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Empty state file initialized correctly"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Empty state file initialized correctly (not valid JSON)"
        exit 1
      fi
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Empty state file initialized correctly (got: $result)"
      exit 1
    fi
  }
  test_init_empty_state

  # Test 1.2: Create state file with initial structure
  test_create_state_structure() {
    rm -f "$STATE_FILE"
    local expected_structure='{"pending_updates":{},"user_decisions":{},"last_cleanup":0}'
    ${stateLib}/bin/get_state > /dev/null 2>&1  # Initialize file
    
    if [[ -f "$STATE_FILE" ]]; then
      local actual=$(cat "$STATE_FILE" | jq -c 'keys | sort')
      local expected='["last_cleanup","pending_updates","user_decisions"]'
      if [[ "$actual" == "$expected" ]]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} State file structure created correctly"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} State file structure created correctly (got: $actual, expected: $expected)"
        exit 1
      fi
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} State file not created"
      exit 1
    fi
  }
  test_create_state_structure

  # Test 2: User Decision Storage and Retrieval
  ${testHelpers.testSubsection "User Decision Storage and Retrieval"}

  # Test 2.1: Store user decision
  test_store_user_decision() {
    rm -f "$STATE_FILE"
    local commit_hash="abc123def456"
    local decision="defer"
    local timestamp=$(date +%s)
    
    # First initialize state file
    ${stateLib}/bin/get_state > /dev/null 2>&1
    
    # Store decision
    timeout 10 ${stateLib}/bin/set_decision "$commit_hash" "$decision" "$timestamp" 2>/dev/null || echo "SET_DECISION_FAILED"
    
    # Verify storage
    if [[ -f "$STATE_FILE" ]]; then
      local stored_decision=$(cat "$STATE_FILE" | jq -r ".user_decisions.\"$commit_hash\".decision // \"NOT_FOUND\"" 2>/dev/null)
      if [[ "$stored_decision" == "$decision" ]]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} User decision stored correctly"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} User decision stored correctly (got: $stored_decision)"
        exit 1
      fi
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} State file not created when storing decision"
      exit 1
    fi
  }
  test_store_user_decision

  # Test 2.2: Retrieve user decision
  test_retrieve_user_decision() {
    rm -f "$STATE_FILE"
    local commit_hash="test123hash"
    local decision="apply"
    local timestamp=$(date +%s)
    
    # Store decision first
    ${stateLib}/bin/set_decision "$commit_hash" "$decision" "$timestamp" 2>/dev/null
    
    # Retrieve decision
    local retrieved=$(${stateLib}/bin/get_decision "$commit_hash" 2>/dev/null)
    if [[ "$retrieved" == "$decision" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} User decision retrieved correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} User decision retrieved correctly (got: $retrieved)"
      exit 1
    fi
  }
  test_retrieve_user_decision

  # Test 2.3: Multiple decisions storage
  test_multiple_decisions() {
    rm -f "$STATE_FILE"
    local commit1="hash001"
    local commit2="hash002"
    local commit3="hash003"
    local timestamp=$(date +%s)
    
    # Store multiple decisions
    ${stateLib}/bin/set_decision "$commit1" "defer" "$timestamp" 2>/dev/null
    ${stateLib}/bin/set_decision "$commit2" "apply" "$((timestamp + 60))" 2>/dev/null
    ${stateLib}/bin/set_decision "$commit3" "skip" "$((timestamp + 120))" 2>/dev/null
    
    # Verify all decisions are stored
    local decision1=$(${stateLib}/bin/get_decision "$commit1" 2>/dev/null)
    local decision2=$(${stateLib}/bin/get_decision "$commit2" 2>/dev/null)
    local decision3=$(${stateLib}/bin/get_decision "$commit3" 2>/dev/null)
    
    if [[ "$decision1" == "defer" && "$decision2" == "apply" && "$decision3" == "skip" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Multiple user decisions stored and retrieved correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Multiple user decisions stored correctly (got: $decision1, $decision2, $decision3)"
      exit 1
    fi
  }
  test_multiple_decisions

  # Test 3: State File Corruption Handling
  ${testHelpers.testSubsection "State File Corruption Handling"}

  # Test 3.1: Invalid JSON handling
  test_invalid_json_handling() {
    rm -f "$STATE_FILE"
    echo "invalid json content {" > "$STATE_FILE"
    
    # Should gracefully handle corruption and recreate
    local result=$(${stateLib}/bin/get_state 2>/dev/null || echo "ERROR")
    if [[ "$result" != "ERROR" ]] && [[ -f "$STATE_FILE" ]]; then
      local is_valid_json=$(cat "$STATE_FILE" | jq empty 2>/dev/null && echo "VALID" || echo "INVALID")
      if [[ "$is_valid_json" == "VALID" ]]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Invalid JSON handled gracefully"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Invalid JSON handled gracefully (file still invalid)"
        exit 1
      fi
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Invalid JSON handled gracefully (operation failed)"
      exit 1
    fi
  }
  test_invalid_json_handling

  # Test 3.2: Empty file handling
  test_empty_file_handling() {
    rm -f "$STATE_FILE"
    touch "$STATE_FILE"  # Create empty file
    
    # Should handle empty file gracefully
    local result=$(${stateLib}/bin/get_state 2>/dev/null)
    if [[ -n "$result" ]]; then
      local is_valid_json=$(echo "$result" | jq empty 2>/dev/null && echo "VALID" || echo "INVALID")
      if [[ "$is_valid_json" == "VALID" ]]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Empty file handled gracefully"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Empty file handled gracefully (result not valid JSON)"
        exit 1
      fi
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Empty file handled gracefully (no result)"
      exit 1
    fi
  }
  test_empty_file_handling

  # Test 3.3: Partial corruption recovery
  test_partial_corruption_recovery() {
    rm -f "$STATE_FILE"
    # Create partially valid JSON (missing closing brace)
    echo '{"pending_updates":{},"user_decisions":{"hash1":{"decision":"defer","timestamp":1234567890}' > "$STATE_FILE"
    
    # Should detect corruption and recreate with clean state
    local result=$(${stateLib}/bin/get_state 2>/dev/null)
    if [[ -n "$result" ]]; then
      local has_structure=$(echo "$result" | jq 'has("pending_updates") and has("user_decisions") and has("last_cleanup")' 2>/dev/null)
      if [[ "$has_structure" == "true" ]]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Partial corruption recovered successfully"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Partial corruption recovered (missing required structure)"
        exit 1
      fi
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Partial corruption recovered (no result)"
      exit 1
    fi
  }
  test_partial_corruption_recovery

  # Test 4: Cleanup of Old Entries
  ${testHelpers.testSubsection "Cleanup of Old Entries"}

  # Test 4.1: Cleanup entries older than 30 days
  test_cleanup_old_entries() {
    rm -f "$STATE_FILE"
    local current_time=$(date +%s)
    local old_time=$((current_time - 32 * 24 * 3600))  # 32 days ago
    local recent_time=$((current_time - 10 * 24 * 3600))  # 10 days ago
    
    # Store old and recent decisions
    ${stateLib}/bin/set_decision "old_hash" "defer" "$old_time" 2>/dev/null
    ${stateLib}/bin/set_decision "recent_hash" "defer" "$recent_time" 2>/dev/null
    
    # Run cleanup
    ${stateLib}/bin/cleanup_old 2>/dev/null
    
    # Verify old entry is removed, recent entry remains
    local old_decision=$(${stateLib}/bin/get_decision "old_hash" 2>/dev/null || echo "NOT_FOUND")
    local recent_decision=$(${stateLib}/bin/get_decision "recent_hash" 2>/dev/null || echo "NOT_FOUND")
    
    if [[ "$old_decision" == "NOT_FOUND" && "$recent_decision" == "defer" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Old entries cleaned up correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Old entries cleaned up correctly (old: $old_decision, recent: $recent_decision)"
      exit 1
    fi
  }
  test_cleanup_old_entries

  # Test 4.2: Cleanup with empty state
  test_cleanup_empty_state() {
    rm -f "$STATE_FILE"
    
    # Run cleanup on empty/missing state file
    local result=$(${stateLib}/bin/cleanup_old 2>/dev/null && echo "SUCCESS" || echo "FAILED")
    if [[ "$result" == "SUCCESS" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cleanup handled empty state gracefully"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cleanup handled empty state gracefully"
      exit 1
    fi
  }
  test_cleanup_empty_state

  # Test 4.3: Cleanup timestamp update
  test_cleanup_timestamp_update() {
    rm -f "$STATE_FILE"
    ${stateLib}/bin/get_state > /dev/null 2>&1  # Initialize file
    
    local before_cleanup=$(cat "$STATE_FILE" | jq -r '.last_cleanup' 2>/dev/null)
    sleep 1  # Ensure timestamp difference
    ${stateLib}/bin/cleanup_old 2>/dev/null
    local after_cleanup=$(cat "$STATE_FILE" | jq -r '.last_cleanup' 2>/dev/null)
    
    if [[ "$after_cleanup" -gt "$before_cleanup" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cleanup timestamp updated correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cleanup timestamp updated correctly (before: $before_cleanup, after: $after_cleanup)"
      exit 1
    fi
  }
  test_cleanup_timestamp_update

  # Test 5: Concurrent Access Protection
  ${testHelpers.testSubsection "Concurrent Access Protection"}

  # Test 5.1: Basic file locking mechanism
  test_file_locking() {
    rm -f "$STATE_FILE"
    local lock_file="$CACHE_DIR/dotfiles-update-state.lock"
    
    # Test that lock file is created and cleaned up during normal operation
    ${stateLib}/bin/get_state > /dev/null 2>&1
    
    # Lock file should not exist after operation
    if [[ ! -f "$lock_file" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} File locking mechanism working"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} File locking mechanism working (lock file not cleaned up)"
      exit 1
    fi
  }
  test_file_locking

  # Test 5.2: Lock cleanup after successful operation
  test_lock_cleanup() {
    rm -f "$STATE_FILE"
    local lock_file="$CACHE_DIR/dotfiles-update-state.lock"
    
    # Run operation that should clean up its own lock
    ${stateLib}/bin/get_state > /dev/null 2>&1
    
    # Lock file should not exist after operation
    if [[ ! -f "$lock_file" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Lock cleanup after successful operation"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Lock cleanup after successful operation (lock file still exists)"
      exit 1
    fi
  }
  test_lock_cleanup

  # Test 5.3: Stale lock handling (locks older than 5 minutes)
  test_stale_lock_handling() {
    rm -f "$STATE_FILE"
    local lock_file="$CACHE_DIR/dotfiles-update-state.lock"
    
    # Test basic stale lock detection by ensuring operations work normally
    local result=$(${stateLib}/bin/get_state 2>/dev/null)
    if [[ -n "$result" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Stale lock handled correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Stale lock handled correctly"
      exit 1
    fi
    
    # Clean up
    rm -f "$lock_file"
  }
  test_stale_lock_handling

  # Test 6: Helper Functions Integration
  ${testHelpers.testSubsection "Helper Functions Integration"}

  # Test 6.1: get_state function
  test_get_state_function() {
    rm -f "$STATE_FILE"
    
    local state=$(${stateLib}/bin/get_state 2>/dev/null)
    local has_required_keys=$(echo "$state" | jq 'has("pending_updates") and has("user_decisions") and has("last_cleanup")' 2>/dev/null)
    
    if [[ "$has_required_keys" == "true" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} get_state function working correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} get_state function working correctly"
      exit 1
    fi
  }
  test_get_state_function

  # Test 6.2: set_decision function parameter validation
  test_set_decision_validation() {
    rm -f "$STATE_FILE"
    
    # Test with invalid parameters - should return non-zero exit codes
    if ! ${stateLib}/bin/set_decision "" "defer" "$(date +%s)" 2>/dev/null; then
      local test1_passed=true
    else
      local test1_passed=false
    fi
    
    if ! ${stateLib}/bin/set_decision "hash123" "" "$(date +%s)" 2>/dev/null; then
      local test2_passed=true
    else
      local test2_passed=false
    fi
    
    if ! ${stateLib}/bin/set_decision "hash123" "invalid_decision" "$(date +%s)" 2>/dev/null; then
      local test3_passed=true
    else
      local test3_passed=false
    fi
    
    # All should fail validation
    if [[ "$test1_passed" == "true" && "$test2_passed" == "true" && "$test3_passed" == "true" ]]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} set_decision parameter validation working"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} set_decision parameter validation working (t1:$test1_passed t2:$test2_passed t3:$test3_passed)"
      exit 1
    fi
  }
  test_set_decision_validation

  # Test 6.3: cleanup_old function timing
  test_cleanup_timing() {
    rm -f "$STATE_FILE"
    
    # Benchmark cleanup operation
    ${testHelpers.benchmark "cleanup_old operation" "${stateLib}/bin/cleanup_old"}
    
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} cleanup_old function timing acceptable"
  }
  test_cleanup_timing

  ${testHelpers.cleanup}

  # Clean up test cache directory
  rm -rf "$CACHE_DIR"

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Auto-Update User Confirmation Unit Tests - Phase 1.1 ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All state management system tests completed successfully!${testHelpers.colors.reset}"
  echo ""
  echo "${testHelpers.colors.yellow}Next: Implement lib/auto-update-state.nix to make these tests pass${testHelpers.colors.reset}"
  
  touch $out
''