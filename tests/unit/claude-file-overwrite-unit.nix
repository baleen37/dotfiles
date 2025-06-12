{ pkgs, src ? ../.. }:

let

  # Mock environment for testing

  # Test the overwrite functionality
  testOverwriteScript = pkgs.writeShellScript "test-overwrite" ''
    set -e

    # Create test directory
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/.claude/commands"

    # Create existing files to test overwrite
    echo "old content" > "$TEST_DIR/.claude/settings.json"
    echo "old claude content" > "$TEST_DIR/.claude/CLAUDE.md"
    echo "old command" > "$TEST_DIR/.claude/commands/test.md"

    # Create mock nix store files (newer content)
    MOCK_NIX_STORE=$(mktemp -d)
    echo "new settings content" > "$MOCK_NIX_STORE/settings.json"
    echo "new claude content" > "$MOCK_NIX_STORE/CLAUDE.md"
    echo "new command content" > "$MOCK_NIX_STORE/test.md"

    # Function to copy symlink to real file with overwrite support
    copy_if_symlink() {
      local file="$1"
      if [[ -L "$file" ]]; then
        local target=$(readlink "$file")
        if [[ -n "$target" && -f "$target" ]]; then
          rm "$file"
          cp "$target" "$file"
          chmod 644 "$file"
          echo "Copied $file from symlink"
        fi
      elif [[ -f "$file" ]]; then
        # File exists but is not a symlink, check if we have a newer version to overwrite
        local source_file="''${file##*/}"
        local nix_store_file="$MOCK_NIX_STORE/$source_file"
        if [[ -n "$nix_store_file" && -f "$nix_store_file" ]]; then
          cp "$nix_store_file" "$file"
          chmod 644 "$file"
          echo "Overwritten existing $file with latest version"
        fi
      fi
    }

    # Test overwrite functionality
    echo "=== Testing File Overwrite Functionality ==="

    # Test settings.json overwrite
    copy_if_symlink "$TEST_DIR/.claude/settings.json"
    if grep -q "new settings content" "$TEST_DIR/.claude/settings.json"; then
      echo "✓ settings.json overwrite successful"
    else
      echo "✗ settings.json overwrite failed"
      exit 1
    fi

    # Test CLAUDE.md overwrite
    copy_if_symlink "$TEST_DIR/.claude/CLAUDE.md"
    if grep -q "new claude content" "$TEST_DIR/.claude/CLAUDE.md"; then
      echo "✓ CLAUDE.md overwrite successful"
    else
      echo "✗ CLAUDE.md overwrite failed"
      exit 1
    fi

    # Test command file overwrite
    copy_if_symlink "$TEST_DIR/.claude/commands/test.md"
    if grep -q "new command content" "$TEST_DIR/.claude/commands/test.md"; then
      echo "✓ command file overwrite successful"
    else
      echo "✗ command file overwrite failed"
      exit 1
    fi

    # Test permissions
    if [[ "$(stat -c %a "$TEST_DIR/.claude/settings.json" 2>/dev/null || stat -f %A "$TEST_DIR/.claude/settings.json")" == "644" ]]; then
      echo "✓ File permissions set correctly"
    else
      echo "✗ File permissions incorrect"
      exit 1
    fi

    # Cleanup
    rm -rf "$TEST_DIR" "$MOCK_NIX_STORE"

    echo "All overwrite tests passed!"
  '';

in
pkgs.runCommand "claude-file-overwrite-unit-test" { } ''
  echo "=== Claude File Overwrite Unit Test ==="

  # Run the overwrite functionality test
  ${testOverwriteScript}

  echo "Unit test completed successfully!"
  touch $out
''
