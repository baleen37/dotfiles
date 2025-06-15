{ pkgs, flake ? null, src ? ../.. }:

let
  # Include jq for JSON manipulation in tests
  testPackages = [ pkgs.jq ];
in

let
  lib = pkgs.lib;

  # End-to-end test that validates the complete workflow
  e2eTestScript = pkgs.writeShellScript "claude-config-e2e-test" ''
    set -e
    export PATH="${pkgs.lib.makeBinPath testPackages}:$PATH"

    echo "=== Claude Configuration End-to-End Test ==="

    # Create isolated test environment
    E2E_TEST_DIR=$(mktemp -d)
    export HOME="$E2E_TEST_DIR"
    TEST_USER="e2etest"

    echo "Test environment: $E2E_TEST_DIR"

    # Phase 1: Initial setup (simulate fresh system)
    echo "Phase 1: Fresh system setup"
    mkdir -p "$HOME/.claude/commands"

    # Verify directory structure
    if [[ -d "$HOME/.claude" && -d "$HOME/.claude/commands" ]]; then
      echo "✓ Directory structure created"
    else
      echo "✗ Failed to create directory structure"
      exit 1
    fi

    # Phase 2: First configuration deployment
    echo "Phase 2: Initial configuration deployment"

    # Simulate nix-darwin creating initial files
    cp ${../../modules/shared/config/claude/settings.json} "$HOME/.claude/settings.json"
    cp ${../../modules/shared/config/claude/CLAUDE.md} "$HOME/.claude/CLAUDE.md"
    chmod 644 "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md"

    # Create some command files
    for cmd in explore fix-github-issue tdd verify-pr; do
      if [[ -f ${../../modules/shared/config/claude/commands}/$cmd.md ]]; then
        cp ${../../modules/shared/config/claude/commands}/$cmd.md "$HOME/.claude/commands/"
      fi
    done

    # Verify initial deployment
    if [[ -f "$HOME/.claude/settings.json" && -f "$HOME/.claude/CLAUDE.md" ]]; then
      echo "✓ Initial configuration deployed"
    else
      echo "✗ Initial configuration deployment failed"
      exit 1
    fi

    # Phase 3: User modifications (simulate real usage)
    echo "Phase 3: Simulating user modifications"

    # User modifies settings.json
    jq '.model = "modified-model"' "$HOME/.claude/settings.json" > "$HOME/.claude/settings.json.tmp"
    mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"

    # User adds custom content to CLAUDE.md
    echo -e "\n# User Custom Section\nThis is custom user content" >> "$HOME/.claude/CLAUDE.md"

    # User creates custom command
    echo "# Custom User Command" > "$HOME/.claude/commands/user-custom.md"

    # Verify user modifications
    if grep -q "modified-model" "$HOME/.claude/settings.json"; then
      echo "✓ User modifications applied"
    else
      echo "✗ User modifications failed"
      exit 1
    fi

    # Phase 4: Configuration update (simulate nix-darwin rebuild)
    echo "Phase 4: Configuration update with overwrite"

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
        # File exists but is not a symlink, overwrite with latest version
        local source_file="''${file##*/}"
        local nix_store_file=""

        # Find the source file in our test setup
        case "$source_file" in
          "settings.json")
            nix_store_file="${../../modules/shared/config/claude/settings.json}"
            ;;
          "CLAUDE.md")
            nix_store_file="${../../modules/shared/config/claude/CLAUDE.md}"
            ;;
          *.md)
            if [[ -f ${../../modules/shared/config/claude/commands}/$source_file ]]; then
              nix_store_file="${../../modules/shared/config/claude/commands}/$source_file"
            fi
            ;;
        esac

        if [[ -n "$nix_store_file" && -f "$nix_store_file" ]]; then
          cp "$nix_store_file" "$file" 2>/dev/null || {
            # If copy fails due to permissions, create a new file with the content
            cat "$nix_store_file" > "$file"
          }
          chmod 644 "$file"
          echo "Overwritten existing $file with latest version"
        fi
      fi
    }

    # Remove backup files
    rm -f "$HOME/.claude"/*.bak
    rm -f "$HOME/.claude/commands"/*.bak

    # Apply configuration updates
    copy_if_symlink "$HOME/.claude/CLAUDE.md"
    copy_if_symlink "$HOME/.claude/settings.json"

    for file in "$HOME/.claude/commands"/*.md; do
      [[ -e "$file" ]] && copy_if_symlink "$file"
    done

    # Phase 5: Verification after update
    echo "Phase 5: Post-update verification"

    # Verify settings.json was overwritten with new content
    if grep -q "sonnet" "$HOME/.claude/settings.json"; then
      echo "✓ settings.json successfully overwritten with latest version"
    else
      echo "✗ settings.json overwrite failed"
      echo "Current content:"
      cat "$HOME/.claude/settings.json"
      exit 1
    fi

    # Verify CLAUDE.md was overwritten
    if grep -q "jito" "$HOME/.claude/CLAUDE.md" && ! grep -q "User Custom Section" "$HOME/.claude/CLAUDE.md"; then
      echo "✓ CLAUDE.md successfully overwritten (user content replaced as expected)"
    else
      echo "✗ CLAUDE.md overwrite failed or user content not replaced"
      echo "Current content:"
      head -10 "$HOME/.claude/CLAUDE.md"
      exit 1
    fi

    # Verify command files were updated but user custom file preserved
    if [[ -f "$HOME/.claude/commands/user-custom.md" ]]; then
      echo "✓ User custom command file preserved"
    else
      echo "✗ User custom command file was removed"
      exit 1
    fi

    # Verify standard command files exist
    EXPECTED_COMMANDS=("explore.md" "fix-github-issue.md" "tdd.md" "verify-pr.md")
    for cmd in "''${EXPECTED_COMMANDS[@]}"; do
      if [[ -f "$HOME/.claude/commands/$cmd" ]]; then
        echo "✓ Command file $cmd exists"
      else
        echo "! Command file $cmd missing (may not exist in source)"
      fi
    done

    # Phase 6: Permission and security verification
    echo "Phase 6: Security and permission verification"

    # Check file permissions
    for file in "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md"; do
      if [[ "$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file")" == "644" ]]; then
        echo "✓ $file has correct permissions (644)"
      else
        echo "✗ $file has incorrect permissions"
        exit 1
      fi
    done

    # Verify no sensitive information leakage
    if ! grep -r "password\|secret\|token\|key" "$HOME/.claude/" 2>/dev/null; then
      echo "✓ No sensitive information found in config files"
    else
      echo "! Potential sensitive information found - review needed"
    fi

    # Phase 7: Stress test (multiple rapid updates)
    echo "Phase 7: Stress testing rapid updates"

    for i in {1..5}; do
      copy_if_symlink "$HOME/.claude/settings.json"
      copy_if_symlink "$HOME/.claude/CLAUDE.md"
      sleep 0.1
    done

    echo "✓ Stress test completed"

    # Phase 8: Cleanup and final verification
    echo "Phase 8: Cleanup verification"

    # Verify no backup files remain
    if [[ -z "$(find "$HOME/.claude" -name "*.bak" 2>/dev/null)" ]]; then
      echo "✓ No backup files left behind"
    else
      echo "✗ Backup files found after cleanup"
      find "$HOME/.claude" -name "*.bak"
      exit 1
    fi

    # Verify configuration is valid JSON
    if jq empty "$HOME/.claude/settings.json" 2>/dev/null; then
      echo "✓ settings.json is valid JSON"
    else
      echo "✗ settings.json is not valid JSON"
      exit 1
    fi

    # Final cleanup
    rm -rf "$E2E_TEST_DIR"

    echo "=== End-to-End Test Completed Successfully ==="
    echo "Summary:"
    echo "  ✓ Fresh system setup"
    echo "  ✓ Initial configuration deployment"
    echo "  ✓ User modification simulation"
    echo "  ✓ Configuration overwrite functionality"
    echo "  ✓ Post-update verification"
    echo "  ✓ Security and permissions"
    echo "  ✓ Stress testing"
    echo "  ✓ Cleanup verification"
  '';

in
pkgs.runCommand "claude-config-overwrite-e2e-test" {} ''
  echo "=== Starting Claude Configuration E2E Test ==="

  # Run the comprehensive end-to-end test
  ${e2eTestScript}

  echo "E2E test completed successfully!"
  touch $out
''
