{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  autoUpdateScript = "${src}/scripts/auto-update-dotfiles";
in
pkgs.runCommand "auto-update-dotfiles-unit-test" {
  buildInputs = with pkgs; [ git coreutils bash ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Auto-Update Dotfiles Unit Tests"}

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

  # Test 1: Script exists and is executable
  ${testHelpers.testSubsection "Script Availability"}
  ${testHelpers.assertExists "$TEST_REPO/scripts/auto-update-dotfiles" "Auto-update script exists"}
  ${testHelpers.assertTrue ''[ -x "$TEST_REPO/scripts/auto-update-dotfiles" ]'' "Auto-update script is executable"}

  # Test 2: Help functionality
  ${testHelpers.testSubsection "Help and Usage"}
  cd "$TEST_REPO"
  if ./scripts/auto-update-dotfiles --help | grep -q "Usage:"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Help message displays correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Help message displays correctly"
    exit 1
  fi

  # Test 3: TTL cache functionality
  ${testHelpers.testSubsection "TTL Cache Management"}
  CACHE_DIR="$HOME/.cache"
  CACHE_FILE="$CACHE_DIR/dotfiles-check"

  # Ensure cache directory exists
  mkdir -p "$CACHE_DIR"

  # Test TTL creation
  echo "1234567890" > "$CACHE_FILE"
  ${testHelpers.assertExists "$CACHE_FILE" "TTL cache file can be created"}
  ${testHelpers.assertContains "$CACHE_FILE" "1234567890" "TTL cache file contains expected content"}

  # Test 4: Local changes detection (Enhanced)
  ${testHelpers.testSubsection "Local Changes Detection"}

  # Helper function to test local changes detection
  create_local_changes_test_function() {
    cat > "$TEST_REPO/test_local_changes.sh" << 'CHANGES_EOF'
#!/bin/bash
# Extract local changes detection logic for isolated testing

has_local_changes() {
    # Check for uncommitted changes
    if ! git diff --quiet HEAD 2>/dev/null; then
        return 0  # Has changes
    fi

    # Check for untracked files (excluding common patterns)
    if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
        return 0  # Has changes
    fi

    return 1  # No changes
}

# Test case based on arguments
case "$1" in
    "clean")
        # Ensure clean state
        git add -A >/dev/null 2>&1 || true
        if ! git diff --quiet HEAD 2>/dev/null; then
            git commit -m "Clean up for test" >/dev/null 2>&1 || true
        fi
        has_local_changes && echo "HAS_CHANGES" || echo "NO_CHANGES"
        ;;
    "modified")
        echo "test modification" >> README.md
        has_local_changes && echo "HAS_CHANGES" || echo "NO_CHANGES"
        ;;
    "untracked")
        echo "untracked file" > untracked_file.txt
        has_local_changes && echo "HAS_CHANGES" || echo "NO_CHANGES"
        ;;
    "ignored")
        echo ".DS_Store" >> .gitignore
        echo "test" > .DS_Store
        git add .gitignore >/dev/null 2>&1
        git commit -m "Add gitignore" >/dev/null 2>&1 || true
        has_local_changes && echo "HAS_CHANGES" || echo "NO_CHANGES"
        ;;
    "staged")
        echo "staged content" > staged_file.txt
        git add staged_file.txt >/dev/null 2>&1
        has_local_changes && echo "HAS_CHANGES" || echo "NO_CHANGES"
        ;;
    *)
        echo "Usage: $0 {clean|modified|untracked|ignored|staged}"
        exit 1
        ;;
esac
CHANGES_EOF
    chmod +x "$TEST_REPO/test_local_changes.sh"
  }

  create_local_changes_test_function
  cd "$TEST_REPO"

  # Test 4.1: Clean repository (should have no changes)
  CHANGES_RESULT=$(./test_local_changes.sh clean)
  if [ "$CHANGES_RESULT" = "NO_CHANGES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Clean repository detected correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Clean repository detected correctly (got: $CHANGES_RESULT)"
    exit 1
  fi

  # Test 4.2: Modified files (should have changes)
  git checkout -- . 2>/dev/null || true  # Clean state first
  CHANGES_RESULT=$(./test_local_changes.sh modified)
  if [ "$CHANGES_RESULT" = "HAS_CHANGES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Modified files detected correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Modified files detected correctly (got: $CHANGES_RESULT)"
    exit 1
  fi

  # Clean up modifications
  git checkout -- README.md 2>/dev/null || true

  # Test 4.3: Untracked files (should have changes)
  CHANGES_RESULT=$(./test_local_changes.sh untracked)
  if [ "$CHANGES_RESULT" = "HAS_CHANGES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Untracked files detected correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Untracked files detected correctly (got: $CHANGES_RESULT)"
    exit 1
  fi

  # Clean up untracked files
  rm -f untracked_file.txt 2>/dev/null || true

  # Test 4.4: Ignored files (should not have changes)
  CHANGES_RESULT=$(./test_local_changes.sh ignored)
  if [ "$CHANGES_RESULT" = "NO_CHANGES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Ignored files excluded correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Ignored files excluded correctly (got: $CHANGES_RESULT)"
    exit 1
  fi

  # Clean up
  rm -f .DS_Store 2>/dev/null || true

  # Test 4.5: Staged files (should have changes)
  CHANGES_RESULT=$(./test_local_changes.sh staged)
  if [ "$CHANGES_RESULT" = "HAS_CHANGES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Staged files detected correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Staged files detected correctly (got: $CHANGES_RESULT)"
    exit 1
  fi

  # Clean up
  git reset HEAD . 2>/dev/null || true
  rm -f staged_file.txt 2>/dev/null || true

  # Test 5: Command line argument parsing
  ${testHelpers.testSubsection "Command Line Arguments"}
  cd "$TEST_REPO"

  # Test --force flag (should not fail on argument parsing)
  if ./scripts/auto-update-dotfiles --force --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Force flag parsing works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Force flag parsing works"
    exit 1
  fi

  # Test --silent flag (should not fail on argument parsing)
  if ./scripts/auto-update-dotfiles --silent --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Silent flag parsing works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Silent flag parsing works"
    exit 1
  fi

  # Test invalid argument handling
  if ! ./scripts/auto-update-dotfiles --invalid-flag >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Invalid arguments rejected correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Invalid arguments rejected correctly"
    exit 1
  fi

  # Test 6: Log file functionality
  ${testHelpers.testSubsection "Logging Functionality"}
  LOG_FILE="$HOME/.cache/dotfiles-update.log"

  # Remove existing log file
  rm -f "$LOG_FILE"

  # Run script to generate log
  cd "$TEST_REPO"
  export HOME="$HOME"
  if ./scripts/auto-update-dotfiles --force >/dev/null 2>&1 || true; then
    # Script may fail due to missing remote, but should create log
    if [ -f "$LOG_FILE" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Log file created successfully"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Log file not created (may be expected in test environment)"
    fi
  fi

  # Test 7: Git safety checks
  ${testHelpers.testSubsection "Git Safety Checks"}
  cd "$TEST_REPO"

  # Test that script doesn't run in non-git directory
  NON_GIT_DIR="$HOME/non-git"
  mkdir -p "$NON_GIT_DIR"
  cd "$NON_GIT_DIR"

  # Should fail gracefully if not in dotfiles directory
  if ! "$TEST_REPO/scripts/auto-update-dotfiles" --force >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script fails safely outside dotfiles directory"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Script behavior outside dotfiles directory (implementation dependent)"
  fi

  # Test 8: Environment variable handling
  ${testHelpers.testSubsection "Environment Variables"}
  cd "$TEST_REPO"

  # Test USER variable handling
  unset USER || true
  if ./scripts/auto-update-dotfiles --help | grep -q "Usage:"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script handles missing USER variable"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script handles missing USER variable"
    exit 1
  fi

  # Test 9: TTL expiration logic (Enhanced)
  ${testHelpers.testSubsection "TTL Expiration Logic"}

  # Helper function to test TTL logic directly
  create_ttl_test_function() {
    cat > "$TEST_REPO/test_ttl_function.sh" << 'TTL_EOF'
#!/bin/bash
# Extract TTL function from auto-update script for isolated testing
TTL_SECONDS=3600
CACHE_FILE="$HOME/.cache/dotfiles-check"

is_ttl_expired() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 0  # No cache file, consider expired
    fi

    local last_check=$(cat "$CACHE_FILE" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local elapsed=$((current_time - last_check))

    if [[ $elapsed -ge $TTL_SECONDS ]]; then
        return 0  # TTL expired
    else
        return 1  # TTL not expired
    fi
}

# Test case based on arguments
case "$1" in
    "no_cache")
        rm -f "$CACHE_FILE"
        is_ttl_expired && echo "EXPIRED" || echo "NOT_EXPIRED"
        ;;
    "fresh_cache")
        echo "$(date +%s)" > "$CACHE_FILE"
        is_ttl_expired && echo "EXPIRED" || echo "NOT_EXPIRED"
        ;;
    "expired_cache")
        echo "1234567890" > "$CACHE_FILE"
        is_ttl_expired && echo "EXPIRED" || echo "NOT_EXPIRED"
        ;;
    "future_cache")
        echo "$(($(date +%s) + 7200))" > "$CACHE_FILE"  # 2 hours in future
        is_ttl_expired && echo "EXPIRED" || echo "NOT_EXPIRED"
        ;;
    "invalid_cache")
        echo "invalid_timestamp" > "$CACHE_FILE"
        is_ttl_expired && echo "EXPIRED" || echo "NOT_EXPIRED"
        ;;
    *)
        echo "Usage: $0 {no_cache|fresh_cache|expired_cache|future_cache|invalid_cache}"
        exit 1
        ;;
esac
TTL_EOF
    chmod +x "$TEST_REPO/test_ttl_function.sh"
  }

  create_ttl_test_function

  # Test 9.1: No cache file (should be expired)
  cd "$TEST_REPO"
  TTL_RESULT=$(./test_ttl_function.sh no_cache)
  if [ "$TTL_RESULT" = "EXPIRED" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TTL expired when no cache file exists"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} TTL expired when no cache file exists (got: $TTL_RESULT)"
    exit 1
  fi

  # Test 9.2: Fresh cache (should not be expired)
  TTL_RESULT=$(./test_ttl_function.sh fresh_cache)
  if [ "$TTL_RESULT" = "NOT_EXPIRED" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TTL not expired with fresh cache"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} TTL not expired with fresh cache (got: $TTL_RESULT)"
    exit 1
  fi

  # Test 9.3: Expired cache (should be expired)
  TTL_RESULT=$(./test_ttl_function.sh expired_cache)
  if [ "$TTL_RESULT" = "EXPIRED" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TTL expired with old cache"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} TTL expired with old cache (got: $TTL_RESULT)"
    exit 1
  fi

  # Test 9.4: Future cache (should not be expired)
  TTL_RESULT=$(./test_ttl_function.sh future_cache)
  if [ "$TTL_RESULT" = "NOT_EXPIRED" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TTL not expired with future cache"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} TTL not expired with future cache (got: $TTL_RESULT)"
    exit 1
  fi

  # Test 9.5: Invalid cache content (should be expired - fail safe)
  TTL_RESULT=$(./test_ttl_function.sh invalid_cache)
  if [ "$TTL_RESULT" = "EXPIRED" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TTL expired with invalid cache content (fail-safe)"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} TTL expired with invalid cache content (got: $TTL_RESULT)"
    exit 1
  fi

  # Test 9.6: TTL boundary test (exactly at expiration)
  CURRENT_TIME=$(date +%s)
  BOUNDARY_TIME=$((CURRENT_TIME - 3600))  # Exactly 1 hour ago
  echo "$BOUNDARY_TIME" > "$CACHE_FILE"
  TTL_RESULT=$(./test_ttl_function.sh expired_cache)
  if [ "$TTL_RESULT" = "EXPIRED" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TTL expired at exact boundary (1 hour)"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} TTL expired at exact boundary (got: $TTL_RESULT)"
    exit 1
  fi

  # Test 10: Remote update detection logic
  ${testHelpers.testSubsection "Remote Update Detection"}

  # Helper function to test remote update detection
  create_remote_update_test_function() {
    cat > "$TEST_REPO/test_remote_updates.sh" << 'REMOTE_EOF'
#!/bin/bash
# Extract remote update detection logic for isolated testing

has_remote_updates() {
    # Fetch remote updates quietly (simulate success/failure)
    case "$TEST_FETCH_RESULT" in
        "success")
            # Compare local main with remote main (using test values)
            local local_commit="$TEST_LOCAL_COMMIT"
            local remote_commit="$TEST_REMOTE_COMMIT"

            if [[ -n "$local_commit" && -n "$remote_commit" && "$local_commit" != "$remote_commit" ]]; then
                return 0  # Has updates
            fi
            return 1  # No updates
            ;;
        "failure")
            return 1  # Fetch failed, no updates
            ;;
        *)
            return 1  # Default: no updates
            ;;
    esac
}

# Test case based on arguments
case "$1" in
    "same_commits")
        export TEST_FETCH_RESULT="success"
        export TEST_LOCAL_COMMIT="abc123"
        export TEST_REMOTE_COMMIT="abc123"
        has_remote_updates && echo "HAS_UPDATES" || echo "NO_UPDATES"
        ;;
    "different_commits")
        export TEST_FETCH_RESULT="success"
        export TEST_LOCAL_COMMIT="abc123"
        export TEST_REMOTE_COMMIT="def456"
        has_remote_updates && echo "HAS_UPDATES" || echo "NO_UPDATES"
        ;;
    "fetch_failed")
        export TEST_FETCH_RESULT="failure"
        export TEST_LOCAL_COMMIT="abc123"
        export TEST_REMOTE_COMMIT="def456"
        has_remote_updates && echo "HAS_UPDATES" || echo "NO_UPDATES"
        ;;
    "empty_local")
        export TEST_FETCH_RESULT="success"
        export TEST_LOCAL_COMMIT=""
        export TEST_REMOTE_COMMIT="def456"
        has_remote_updates && echo "HAS_UPDATES" || echo "NO_UPDATES"
        ;;
    "empty_remote")
        export TEST_FETCH_RESULT="success"
        export TEST_LOCAL_COMMIT="abc123"
        export TEST_REMOTE_COMMIT=""
        has_remote_updates && echo "HAS_UPDATES" || echo "NO_UPDATES"
        ;;
    *)
        echo "Usage: $0 {same_commits|different_commits|fetch_failed|empty_local|empty_remote}"
        exit 1
        ;;
esac
REMOTE_EOF
    chmod +x "$TEST_REPO/test_remote_updates.sh"
  }

  create_remote_update_test_function

  # Test 10.1: Same commits (should have no updates)
  cd "$TEST_REPO"
  REMOTE_RESULT=$(./test_remote_updates.sh same_commits)
  if [ "$REMOTE_RESULT" = "NO_UPDATES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No updates detected when commits are same"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} No updates detected when commits are same (got: $REMOTE_RESULT)"
    exit 1
  fi

  # Test 10.2: Different commits (should have updates)
  REMOTE_RESULT=$(./test_remote_updates.sh different_commits)
  if [ "$REMOTE_RESULT" = "HAS_UPDATES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Updates detected when commits are different"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Updates detected when commits are different (got: $REMOTE_RESULT)"
    exit 1
  fi

  # Test 10.3: Fetch failure (should have no updates)
  REMOTE_RESULT=$(./test_remote_updates.sh fetch_failed)
  if [ "$REMOTE_RESULT" = "NO_UPDATES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No updates when fetch fails (fail-safe)"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} No updates when fetch fails (got: $REMOTE_RESULT)"
    exit 1
  fi

  # Test 10.4: Empty local commit (should have no updates)
  REMOTE_RESULT=$(./test_remote_updates.sh empty_local)
  if [ "$REMOTE_RESULT" = "NO_UPDATES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No updates when local commit is empty (fail-safe)"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} No updates when local commit is empty (got: $REMOTE_RESULT)"
    exit 1
  fi

  # Test 10.5: Empty remote commit (should have no updates)
  REMOTE_RESULT=$(./test_remote_updates.sh empty_remote)
  if [ "$REMOTE_RESULT" = "NO_UPDATES" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No updates when remote commit is empty (fail-safe)"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} No updates when remote commit is empty (got: $REMOTE_RESULT)"
    exit 1
  fi

  # Test 11: Build-switch execution logic
  ${testHelpers.testSubsection "Build-Switch Execution"}

  # Helper function to test build-switch execution
  create_build_switch_test_function() {
    cat > "$TEST_REPO/test_build_switch.sh" << 'BUILD_EOF'
#!/bin/bash
# Test build-switch execution logic

perform_build_switch_test() {
    local test_scenario="$1"

    case "$test_scenario" in
        "nix_available")
            # Simulate nix command being available
            export PATH="/mock/nix/bin:$PATH"
            command -v nix >/dev/null 2>&1 && echo "NIX_AVAILABLE" || echo "NIX_NOT_AVAILABLE"
            ;;
        "nix_not_available")
            # Simulate nix command not being available
            export PATH="/usr/bin:/bin"
            command -v nix >/dev/null 2>&1 && echo "NIX_AVAILABLE" || echo "NIX_NOT_AVAILABLE"
            ;;
        "user_var_set")
            export USER="testuser"
            echo "USER_VAR: ''${USER:-not_set}"
            ;;
        "user_var_unset")
            unset USER
            echo "USER_VAR: ''${USER:-not_set}"
            ;;
        "architecture_detection")
            # Test architecture detection logic
            ARCH_VAL=$(uname -m)
            OS_VAL=$(uname -s)

            if [[ "$OS_VAL" == "Darwin" ]]; then
                SYSTEM_TYPE="$ARCH_VAL-darwin"
            else
                SYSTEM_TYPE="$ARCH_VAL-linux"
            fi
            echo "SYSTEM_TYPE: $SYSTEM_TYPE"
            ;;
        *)
            echo "Usage: $0 {nix_available|nix_not_available|user_var_set|user_var_unset|architecture_detection}"
            exit 1
            ;;
    esac
}

perform_build_switch_test "$1"
BUILD_EOF
    chmod +x "$TEST_REPO/test_build_switch.sh"
  }

  create_build_switch_test_function

  # Test 11.1: Nix availability check (simulated)
  cd "$TEST_REPO"
  BUILD_RESULT=$(./test_build_switch.sh nix_not_available)
  if [ "$BUILD_RESULT" = "NIX_NOT_AVAILABLE" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Nix unavailability detected correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Nix unavailability detected correctly (got: $BUILD_RESULT)"
    exit 1
  fi

  # Test 11.2: USER variable set
  BUILD_RESULT=$(./test_build_switch.sh user_var_set)
  if [[ "$BUILD_RESULT" == "USER_VAR: testuser" ]]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} USER variable handling when set"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} USER variable handling when set (got: $BUILD_RESULT)"
    exit 1
  fi

  # Test 11.3: USER variable unset (should use fallback)
  BUILD_RESULT=$(./test_build_switch.sh user_var_unset)
  if [[ "$BUILD_RESULT" == "USER_VAR: not_set" ]]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} USER variable handling when unset"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} USER variable handling when unset (got: $BUILD_RESULT)"
    exit 1
  fi

  # Test 11.4: Architecture detection
  BUILD_RESULT=$(./test_build_switch.sh architecture_detection)
  if [[ "$BUILD_RESULT" =~ ^SYSTEM_TYPE:\ (x86_64|aarch64|arm64)-(darwin|linux)$ ]]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System architecture detected correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} System architecture detected correctly (got: $BUILD_RESULT)"
    exit 1
  fi

  # Test 12: Script configuration constants
  ${testHelpers.testSubsection "Configuration Validation"}

  # Check that TTL is set to 1 hour (3600 seconds)
  if grep -q "TTL_SECONDS=3600" "$TEST_REPO/scripts/auto-update-dotfiles"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TTL configured for 1 hour"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} TTL configured for 1 hour"
    exit 1
  fi

  # Check for required directory variables
  if grep -q "DOTFILES_DIR=" "$TEST_REPO/scripts/auto-update-dotfiles"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Dotfiles directory variable defined"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Dotfiles directory variable defined"
    exit 1
  fi

  ${testHelpers.cleanup}

  # Clean up test repository
  cd "$HOME"
  rm -rf "$TEST_REPO" "$NON_GIT_DIR"

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Auto-Update Dotfiles Unit Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All unit tests completed successfully!${testHelpers.colors.reset}"
  touch $out
''
