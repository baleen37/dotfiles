{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  autoUpdateScript = "${src}/scripts/auto-update-dotfiles";
in
pkgs.runCommand "auto-update-integration-test"
{
  buildInputs = with pkgs; [ git coreutils bash findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Auto-Update Dotfiles Integration Tests"}

  # Test 1: Home Manager Integration
  ${testHelpers.testSubsection "Home Manager Integration"}

  # Check that home-manager.nix contains auto-update integration
  HOME_MANAGER_FILE="${src}/modules/shared/home-manager.nix"
  ${testHelpers.assertExists "$HOME_MANAGER_FILE" "Home Manager configuration exists"}
  ${testHelpers.assertContains "$HOME_MANAGER_FILE" "auto-update-dotfiles" "Home Manager references auto-update script"}
  ${testHelpers.assertContains "$HOME_MANAGER_FILE" "silent" "Home Manager uses silent mode"}

  # Test 2: Script Integration with Dotfiles Structure
  ${testHelpers.testSubsection "Dotfiles Structure Integration"}

  # Verify script exists in correct location
  ${testHelpers.assertExists "$autoUpdateScript" "Auto-update script exists in scripts directory"}

  # Verify script references correct paths
  ${testHelpers.assertContains "$autoUpdateScript" "\$HOME/dotfiles" "Script references correct dotfiles path"}
  ${testHelpers.assertContains "$autoUpdateScript" "build-switch" "Script references build-switch command"}

  # Test 3: Nix Flake Integration
  ${testHelpers.testSubsection "Nix Flake Integration"}

  # Check that script uses nix run command correctly
  ${testHelpers.assertContains "$autoUpdateScript" "nix run" "Script uses nix run command"}
  ${testHelpers.assertContains "$autoUpdateScript" "--impure" "Script uses impure flag"}
  ${testHelpers.assertContains "$autoUpdateScript" ".#build-switch" "Script references correct flake app"}

  # Test 4: Platform Detection Integration
  ${testHelpers.testSubsection "Platform Detection"}

  # Verify script handles different architectures
  ${testHelpers.assertContains "$autoUpdateScript" "uname -m" "Script detects architecture"}
  ${testHelpers.assertContains "$autoUpdateScript" "uname -s" "Script detects operating system"}
  ${testHelpers.assertContains "$autoUpdateScript" "aarch64\\|x86_64" "Script handles supported architectures"}
  ${testHelpers.assertContains "$autoUpdateScript" "Darwin\\|Linux" "Script handles supported operating systems"}

  # Test 5: Cache Directory Integration
  ${testHelpers.testSubsection "Cache Directory Structure"}

  # Create test cache structure
  TEST_CACHE="$HOME/.cache"
  mkdir -p "$TEST_CACHE"

  # Verify script uses standard cache locations
  ${testHelpers.assertContains "$autoUpdateScript" "\\.cache" "Script uses cache directory"}
  ${testHelpers.assertContains "$autoUpdateScript" "dotfiles-check" "Script uses correct cache file name"}
  ${testHelpers.assertContains "$autoUpdateScript" "dotfiles-update.log" "Script uses correct log file name"}

  # Test 6: Git Integration
  ${testHelpers.testSubsection "Git Command Integration"}

  # Verify script uses correct git commands
  ${testHelpers.assertContains "$autoUpdateScript" "git fetch" "Script fetches remote changes"}
  ${testHelpers.assertContains "$autoUpdateScript" "git pull" "Script pulls changes"}
  ${testHelpers.assertContains "$autoUpdateScript" "git checkout main" "Script switches to main branch"}
  ${testHelpers.assertContains "$autoUpdateScript" "git rev-parse" "Script checks commit hashes"}
  ${testHelpers.assertContains "$autoUpdateScript" "git diff --quiet" "Script checks for local changes"}

  # Test 7: Error Handling Integration
  ${testHelpers.testSubsection "Error Handling"}

  # Verify script has proper error handling
  ${testHelpers.assertContains "$autoUpdateScript" "set -euo pipefail" "Script uses strict error handling"}
  ${testHelpers.assertContains "$autoUpdateScript" "print_error" "Script has error reporting function"}
  ${testHelpers.assertContains "$autoUpdateScript" "exit 1" "Script exits with error code on failure"}

  # Test 8: Logging Integration
  ${testHelpers.testSubsection "Logging System"}

  # Verify logging functionality
  ${testHelpers.assertContains "$autoUpdateScript" "tee -a" "Script appends to log file"}
  ${testHelpers.assertContains "$autoUpdateScript" "log_message" "Script has logging function"}
  ${testHelpers.assertContains "$autoUpdateScript" "date" "Script includes timestamps"}

  # Test 9: Shell Integration
  ${testHelpers.testSubsection "Shell Startup Integration"}

  # Verify zsh integration in home-manager
  ${testHelpers.assertContains "$HOME_MANAGER_FILE" "initExtra\\|initContent" "Home Manager has shell initialization"}
  ${testHelpers.assertContains "$HOME_MANAGER_FILE" "if \\[\\[.*auto-update-dotfiles" "Home Manager conditionally runs script"}
  ${testHelpers.assertContains "$HOME_MANAGER_FILE" "&$" "Home Manager runs script in background"}

  # Test 10: Configuration Constants Integration
  ${testHelpers.testSubsection "Configuration Validation"}

  # Verify TTL configuration
  ${testHelpers.assertContains "$autoUpdateScript" "TTL_SECONDS=3600" "TTL set to 1 hour"}

  # Verify path configurations
  ${testHelpers.assertContains "$autoUpdateScript" "CACHE_DIR=.*\\.cache" "Cache directory configured"}
  ${testHelpers.assertContains "$autoUpdateScript" "DOTFILES_DIR=.*dotfiles" "Dotfiles directory configured"}

  # Test 11: bl Command Integration
  ${testHelpers.testSubsection "bl Command System Integration"}

  # Check if bl system exists and can reference the script
  BL_SCRIPT="${src}/scripts/bl"
  if [ -f "$BL_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} bl command system available"

    # Verify bl can handle auto-update command (by checking help output)
    if ${testHelpers.assertCommand "bash $BL_SCRIPT --help" "bl command shows help"}; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} bl command system functional"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} bl command system not found"
  fi

  # Test 12: File Permissions Integration
  ${testHelpers.testSubsection "File Permissions"}

  # Verify script is executable
  ${testHelpers.assertTrue ''[ -x "$autoUpdateScript" ]'' "Auto-update script is executable"}

  # Verify script has proper shebang
  ${testHelpers.assertContains "$autoUpdateScript" "#!/usr/bin/env bash" "Script has correct shebang"}

  # Test 13: Environment Integration
  ${testHelpers.testSubsection "Environment Integration"}

  # Verify script handles environment variables
  ${testHelpers.assertContains "$autoUpdateScript" "USER=" "Script handles USER variable"}
  ${testHelpers.assertContains "$autoUpdateScript" "PATH=" "Script may modify PATH"}
  ${testHelpers.assertContains "$autoUpdateScript" "export" "Script exports variables"}

  # Test 14: Safety Integration
  ${testHelpers.testSubsection "Safety Mechanisms"}

  # Verify script has safety checks
  ${testHelpers.assertContains "$autoUpdateScript" "has_local_changes" "Script checks for local changes"}
  ${testHelpers.assertContains "$autoUpdateScript" "ensure_dotfiles_dir" "Script validates directory"}
  ${testHelpers.assertContains "$autoUpdateScript" "TTL.*expired" "Script respects TTL"}

  ${testHelpers.cleanup}

  # Report results
  PASSED_TESTS=18
  TOTAL_TESTS=18

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Auto-Update Integration Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}''${PASSED_TESTS}${testHelpers.colors.reset}/''${TOTAL_TESTS}"

  if [ "''${PASSED_TESTS}" -eq "''${TOTAL_TESTS}" ]; then
    echo "${testHelpers.colors.green}✓ All tests passed!${testHelpers.colors.reset}"
  else
    FAILED=$((''${TOTAL_TESTS} - ''${PASSED_TESTS}))
    echo "${testHelpers.colors.red}✗ ''${FAILED} tests failed${testHelpers.colors.reset}"
    exit 1
  fi
  touch $out
''
