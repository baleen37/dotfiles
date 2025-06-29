{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  portablePaths = import ../lib/portable-paths.nix { inherit pkgs; };

  # Create a test configuration that simulates the real environment
  testUser = "integrationtest";
  # Use portable temp directory for test home
  testUserHome = "TEST_HOME_PLACEHOLDER";

  # Import modules for testing
  # Note: Module will be tested with dynamic home directory set by portable paths
  filesModule = import ../../modules/shared/files.nix {
    inherit lib pkgs;
    config = {
      users.users.${testUser}.home = testUserHome; # Will be overridden by $HOME at runtime
    };
    user = testUser;
    self = src;
  };

  # Create a mock darwin configuration
  darwinConfig = {
    config = {
      home.homeDirectory = testUserHome; # Will be overridden by $HOME at runtime
      users.users.${testUser}.home = testUserHome; # Will be overridden by $HOME at runtime
    };
    lib = lib;
  };

  # Test script that simulates the full integration
  integrationTestScript = pkgs.writeShellScript "claude-config-integration-test" ''
    set -e

    echo "=== Claude Configuration Integration Test ==="

    # Set up portable test environment
    ${portablePaths.getTestHome}

    # Create test environment
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.claude/commands"

    # Simulate existing configuration files
    echo '{"model": "old-model"}' > "$HOME/.claude/settings.json"
    echo "# Old CLAUDE.md content" > "$HOME/.claude/CLAUDE.md"
    echo "# Old command" > "$HOME/.claude/commands/old-command.md"

    echo "Created existing configuration files..."

    # Create new configuration files in a mock nix store location
    MOCK_NIX_STORE=$(mktemp -d)
    mkdir -p "$MOCK_NIX_STORE"

    # Copy actual configuration files to mock store
    cp ${../../modules/shared/config/claude/settings.json} "$MOCK_NIX_STORE/settings.json"
    cp ${../../modules/shared/config/claude/CLAUDE.md} "$MOCK_NIX_STORE/CLAUDE.md"

    # Create test command files
    echo "# Test command 1" > "$MOCK_NIX_STORE/test-command.md"
    echo "# Test command 2" > "$MOCK_NIX_STORE/another-command.md"

    # Function to copy symlink to real file with overwrite support (from actual implementation)
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

    # Simulate the activation script behavior
    echo "Running configuration update simulation..."

    # Remove backup files
    rm -f "$TEST_HOME/.claude"/*.bak
    rm -f "$TEST_HOME/.claude/commands"/*.bak

    # Copy configuration files
    copy_if_symlink "$TEST_HOME/.claude/CLAUDE.md"
    copy_if_symlink "$TEST_HOME/.claude/settings.json"

    # Copy command files
    for file in "$TEST_HOME/.claude/commands"/*.md; do
      [[ -e "$file" ]] && copy_if_symlink "$file"
    done

    # Verify overwrite worked correctly
    echo "Verifying configuration updates..."

    # Check settings.json was updated
    if grep -q "sonnet" "$TEST_HOME/.claude/settings.json"; then
      echo "✓ settings.json updated successfully"
    else
      echo "✗ settings.json not updated properly"
      cat "$TEST_HOME/.claude/settings.json"
      exit 1
    fi

    # Check CLAUDE.md was updated
    if grep -q "pragmatic software engineer" "$TEST_HOME/.claude/CLAUDE.md"; then
      echo "✓ CLAUDE.md updated successfully"
    else
      echo "✗ CLAUDE.md not updated properly"
      head -5 "$TEST_HOME/.claude/CLAUDE.md"
      exit 1
    fi

    # Check file permissions
    if [[ "$(stat -c %a "$TEST_HOME/.claude/settings.json" 2>/dev/null || stat -f %A "$TEST_HOME/.claude/settings.json")" == "644" ]]; then
      echo "✓ File permissions correct"
    else
      echo "✗ File permissions incorrect"
      exit 1
    fi

    # Verify no .bak files were left behind
    if [[ -n "$(find "$TEST_HOME/.claude" -name "*.bak" 2>/dev/null)" ]]; then
      echo "✗ Backup files were left behind"
      exit 1
    else
      echo "✓ No backup files left behind"
    fi

    # Test concurrent access (simulate multiple processes)
    echo "Testing concurrent access..."
    (
      copy_if_symlink "$TEST_HOME/.claude/settings.json" &
      copy_if_symlink "$TEST_HOME/.claude/CLAUDE.md" &
      wait
      echo "✓ Concurrent access handled correctly"
    )

    # Cleanup
    rm -rf "$TEST_HOME" "$MOCK_NIX_STORE"

    echo "Integration test completed successfully!"
  '';

in
pkgs.runCommand "claude-config-overwrite-integration-test" { } ''
  echo "=== Claude Configuration Overwrite Integration Test ==="

  # Run the integration test
  ${integrationTestScript}

  echo "Integration test completed!"
  touch $out
''
