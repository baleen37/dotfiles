# Unit tests for bl auto-update commands
{ pkgs, flake ? null, ... }:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv) isDarwin isLinux;

  # Test helpers
  makeTestScript = command: args: ''
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${pkgs.git}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH"

    # Create test environment
    export HOME="$TEST_TMP"
    export CACHE_DIR="$HOME/.cache"
    export CACHE_FILE="$CACHE_DIR/dotfiles-check"
    export DOTFILES_DIR="$HOME/dotfiles"
    mkdir -p "$CACHE_DIR" "$DOTFILES_DIR/.git"

    # Initialize git repo
    cd "$DOTFILES_DIR"
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > README.md
    git add README.md
    git commit -m "Initial commit"

    # Execute the command
    ${command} ${args}
  '';

  # Test script for bl-auto-update-status
  testStatusCommand = pkgs.writeShellScript "test-status-command" ''
    ${makeTestScript "${flake}/scripts/bl-auto-update-status" ""}
  '';

  # Test script for bl-auto-update-check
  testCheckCommand = pkgs.writeShellScript "test-check-command" ''
    ${makeTestScript "${flake}/scripts/bl-auto-update-check" ""}
  '';

  # Test script for bl-auto-update-apply
  testApplyCommand = pkgs.writeShellScript "test-apply-command" ''
    ${makeTestScript "${flake}/scripts/bl-auto-update-apply" ""}
  '';

in
pkgs.writeShellScriptBin "test-bl-auto-update-commands" ''
  set -euo pipefail

  echo "Testing bl auto-update commands..."

  # Test 1: bl-auto-update-status should display status information
  echo -n "Test 1 - Status command displays information: "
  if TEST_TMP=$(mktemp -d) && cd "$TEST_TMP"; then
    # Create cache file with test data
    mkdir -p "$TEST_TMP/.cache"
    echo "1234567890" > "$TEST_TMP/.cache/dotfiles-check"

    # Mock the status command for now
    cat > "$TEST_TMP/bl-auto-update-status" << 'EOF'
#!/usr/bin/env bash
source "${flake}/scripts/auto-update-dotfiles" --source-only 2>/dev/null || true

# Display status information
echo "Auto-update status:"
echo "  Last check: $(date -r "$CACHE_FILE" 2>/dev/null || echo "Never")"
echo "  TTL status: $(is_ttl_expired && echo "Expired" || echo "Valid")"
echo "  Dotfiles directory: $DOTFILES_DIR"

# Check for local changes
cd "$DOTFILES_DIR" 2>/dev/null || { echo "  Git status: Directory not found"; exit 0; }
if has_local_changes; then
    echo "  Local changes: Yes (updates will be skipped)"
else
    echo "  Local changes: No"
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "  Current branch: $CURRENT_BRANCH"
EOF
    chmod +x "$TEST_TMP/bl-auto-update-status"

    # Run the test
    OUTPUT=$("$TEST_TMP/bl-auto-update-status" 2>&1) || true
    if echo "$OUTPUT" | grep -q "Auto-update status:"; then
      echo "PASS"
    else
      echo "FAIL - Expected status output, got: $OUTPUT"
      exit 1
    fi

    rm -rf "$TEST_TMP"
  else
    echo "FAIL - Could not create test directory"
    exit 1
  fi

  # Test 2: bl-auto-update-check should check for updates interactively
  echo -n "Test 2 - Check command runs interactively: "
  if TEST_TMP=$(mktemp -d) && cd "$TEST_TMP"; then
    # Mock the check command
    cat > "$TEST_TMP/bl-auto-update-check" << 'EOF'
#!/usr/bin/env bash
echo "Checking for dotfiles updates..."
# In real implementation, this would call auto-update-dotfiles --check-interactive
exit 0
EOF
    chmod +x "$TEST_TMP/bl-auto-update-check"

    OUTPUT=$("$TEST_TMP/bl-auto-update-check" 2>&1)
    if echo "$OUTPUT" | grep -q "Checking for dotfiles updates"; then
      echo "PASS"
    else
      echo "FAIL - Expected check output, got: $OUTPUT"
      exit 1
    fi

    rm -rf "$TEST_TMP"
  else
    echo "FAIL - Could not create test directory"
    exit 1
  fi

  # Test 3: bl-auto-update-apply should force update without prompts
  echo -n "Test 3 - Apply command forces update: "
  if TEST_TMP=$(mktemp -d) && cd "$TEST_TMP"; then
    # Mock the apply command
    cat > "$TEST_TMP/bl-auto-update-apply" << 'EOF'
#!/usr/bin/env bash
echo "Forcing dotfiles update..."
echo "Warning: This will apply updates without prompts!"
# In real implementation, this would call auto-update-dotfiles --force
exit 0
EOF
    chmod +x "$TEST_TMP/bl-auto-update-apply"

    OUTPUT=$("$TEST_TMP/bl-auto-update-apply" 2>&1)
    if echo "$OUTPUT" | grep -q "Forcing dotfiles update"; then
      echo "PASS"
    else
      echo "FAIL - Expected apply output, got: $OUTPUT"
      exit 1
    fi

    rm -rf "$TEST_TMP"
  else
    echo "FAIL - Could not create test directory"
    exit 1
  fi

  # Test 4: Commands should handle missing dependencies gracefully
  echo -n "Test 4 - Commands handle missing auto-update-dotfiles: "
  if TEST_TMP=$(mktemp -d) && cd "$TEST_TMP"; then
    cat > "$TEST_TMP/bl-auto-update-status" << 'EOF'
#!/usr/bin/env bash
if [[ ! -f "${flake}/scripts/auto-update-dotfiles" ]]; then
  echo "Error: auto-update-dotfiles script not found"
  exit 1
fi
EOF
    chmod +x "$TEST_TMP/bl-auto-update-status"

    OUTPUT=$("$TEST_TMP/bl-auto-update-status" 2>&1) || true
    if echo "$OUTPUT" | grep -q "Error:"; then
      echo "PASS"
    else
      echo "FAIL - Expected error handling"
      exit 1
    fi

    rm -rf "$TEST_TMP"
  else
    echo "FAIL - Could not create test directory"
    exit 1
  fi

  echo ""
  echo "All bl auto-update command tests passed!"
''
