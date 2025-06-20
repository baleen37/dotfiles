# Integration test for bl auto-update commands workflow
{ pkgs, flake ? null, ... }:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv) isDarwin isLinux;

  # Create a test environment with mock git repository
  testEnv = pkgs.writeShellScriptBin "test-bl-auto-update-workflow" ''
    set -euo pipefail

    echo "Testing bl auto-update workflow integration..."

    # Set up test environment
    export TEST_TMP=$(mktemp -d)
    export HOME="$TEST_TMP"
    export DOTFILES_DIR="$HOME/dotfiles"
    export CACHE_DIR="$HOME/.cache"
    export BL_DIR="$HOME/.bl/commands"
    export PATH="${pkgs.git}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH"

    # Clean up on exit
    trap "rm -rf $TEST_TMP" EXIT

    # Create directories
    mkdir -p "$DOTFILES_DIR/.git" "$CACHE_DIR" "$BL_DIR"

    # Initialize git repository
    cd "$DOTFILES_DIR"
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    git remote add origin https://github.com/test/dotfiles.git

    # Create initial commit
    echo "# Test Dotfiles" > README.md
    git add README.md
    git commit -m "Initial commit"

    # Copy bl commands
    for cmd in ${flake}/scripts/bl-auto-update-*; do
      if [[ -f "$cmd" ]]; then
        cmd_name=$(basename "$cmd" | sed 's/^bl-//')
        cp "$cmd" "$BL_DIR/$cmd_name"
        chmod +x "$BL_DIR/$cmd_name"
      fi
    done

    # Copy bl script
    cp ${flake}/scripts/bl "$HOME/.bl/bl"
    chmod +x "$HOME/.bl/bl"
    export PATH="$HOME/.bl:$PATH"

    # Copy auto-update-dotfiles script
    cp ${flake}/scripts/auto-update-dotfiles "$DOTFILES_DIR/scripts/"
    mkdir -p "$DOTFILES_DIR/scripts"
    cp ${flake}/scripts/auto-update-dotfiles "$DOTFILES_DIR/scripts/"
    chmod +x "$DOTFILES_DIR/scripts/auto-update-dotfiles"

    # Test 1: Status command should work
    echo -n "Test 1 - Status command: "
    OUTPUT=$(bl auto-update-status 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Auto-Update Status"; then
      echo "PASS"
    else
      echo "FAIL - Expected status output, got: $OUTPUT"
      exit 1
    fi

    # Test 2: Status should show never checked
    echo -n "Test 2 - Status shows never checked: "
    if echo "$OUTPUT" | grep -q "Last check: Never"; then
      echo "PASS"
    else
      echo "FAIL - Expected 'Never' in output"
      exit 1
    fi

    # Test 3: Check command should work (but find no updates)
    echo -n "Test 3 - Check command: "
    # Mock the check to avoid network calls
    cat > "$DOTFILES_DIR/scripts/auto-update-dotfiles" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "--check-on-start" ]]; then
  echo "Checking for updates..."
  echo "No updates available."
  exit 0
fi
# Source-only mode for other scripts
if [[ "$1" == "--source-only" ]]; then
  has_local_changes() { return 1; }
  is_ttl_expired() { return 0; }
  return 0
fi
EOF
    chmod +x "$DOTFILES_DIR/scripts/auto-update-dotfiles"

    OUTPUT=$(bl auto-update-check 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Checking for"; then
      echo "PASS"
    else
      echo "FAIL - Expected check output, got: $OUTPUT"
      exit 1
    fi

    # Test 4: Apply command should prompt for confirmation
    echo -n "Test 4 - Apply command prompts: "
    # Provide 'n' as input to cancel
    OUTPUT=$(echo "n" | bl auto-update-apply 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Update cancelled"; then
      echo "PASS"
    else
      echo "FAIL - Expected cancellation message, got: $OUTPUT"
      exit 1
    fi

    # Test 5: Commands should be listed in bl
    echo -n "Test 5 - Commands listed in bl: "
    OUTPUT=$(bl list 2>&1)
    if echo "$OUTPUT" | grep -q "auto-update-status" && \
       echo "$OUTPUT" | grep -q "auto-update-check" && \
       echo "$OUTPUT" | grep -q "auto-update-apply"; then
      echo "PASS"
    else
      echo "FAIL - Expected all three commands in list"
      exit 1
    fi

    # Test 6: Status should show dotfiles directory correctly
    echo -n "Test 6 - Status shows correct directory: "
    OUTPUT=$(bl auto-update-status 2>&1)
    if echo "$OUTPUT" | grep -q "$DOTFILES_DIR"; then
      echo "PASS"
    else
      echo "FAIL - Expected dotfiles directory in output"
      exit 1
    fi

    echo ""
    echo "All integration tests passed!"
  '';

in
testEnv
