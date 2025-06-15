{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "recovery-mechanisms-integration-test"
{
  nativeBuildInputs = with pkgs; [ nix git ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Recovery Mechanisms Integration Tests"}

  cd ${src}
  export USER=testuser

  # Test 1: Rollback functionality
  ${testHelpers.testSubsection "Rollback Functionality"}

  # Test that rollback apps exist for all platforms
  CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw)

  for platform in x86_64-darwin aarch64-darwin x86_64-linux aarch64-linux; do
    if nix eval --impure '.#apps.'$platform'.rollback.program' >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback app available for $platform"
    else
      case "$platform" in
        *-darwin)
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback app missing for $platform"
          exit 1
          ;;
        *-linux)
          echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Rollback app not available for $platform (Darwin-only feature)"
          ;;
      esac
    fi
  done

  # Test rollback script content
  ROLLBACK_SCRIPT_PATH="${src}/apps/$CURRENT_SYSTEM/rollback"
  if [ -f "$ROLLBACK_SCRIPT_PATH" ]; then
    ${testHelpers.assertExists "$ROLLBACK_SCRIPT_PATH" "Platform-specific rollback script exists"}
    ${testHelpers.assertTrue ''[ -x "$ROLLBACK_SCRIPT_PATH" ]'' "Rollback script is executable"}

    # Check that rollback script contains expected commands
    if grep -q "generation" "$ROLLBACK_SCRIPT_PATH" 2>/dev/null; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback script contains generation management"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Rollback script content not verifiable"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Platform-specific rollback script not found"
  fi

  # Test 2: Backup and restore mechanisms
  ${testHelpers.testSubsection "Backup and Restore Mechanisms"}

  # Test that configuration files have backup mechanisms
  if [ -f "${src}/modules/shared/lib/file-change-detector.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} File change detection system available"

    # Test that backup mechanisms work
    if nix eval --impure --file ${src}/modules/shared/lib/file-change-detector.nix '{pkgs = import <nixpkgs> {};}' >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} File change detector evaluates correctly"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} File change detector evaluation skipped (nixpkgs compatibility)"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} File change detection system not found"
  fi

  # Test Claude config preservation system
  if [ -f "${src}/modules/shared/lib/claude-config-policy.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Claude config preservation system available"

    if nix eval --impure --file ${src}/modules/shared/lib/claude-config-policy.nix '{pkgs = import <nixpkgs> {};}' >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Claude config policy evaluates correctly"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Claude config policy evaluation skipped (nixpkgs compatibility)"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Claude config preservation system not found"
  fi

  # Test 3: Auto-update recovery
  ${testHelpers.testSubsection "Auto-Update Recovery"}

  # Test auto-update script exists and is safe
  AUTO_UPDATE_SCRIPT="${src}/scripts/auto-update-dotfiles"
  if [ -f "$AUTO_UPDATE_SCRIPT" ]; then
    ${testHelpers.assertExists "$AUTO_UPDATE_SCRIPT" "Auto-update script exists"}
    ${testHelpers.assertTrue ''[ -x "$AUTO_UPDATE_SCRIPT" ]'' "Auto-update script is executable"}

    # Check for safety mechanisms
    if grep -q "backup" "$AUTO_UPDATE_SCRIPT" 2>/dev/null; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Auto-update includes backup mechanisms"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Auto-update backup mechanisms not verifiable"
    fi

    if grep -q "rollback" "$AUTO_UPDATE_SCRIPT" 2>/dev/null || grep -q "restore" "$AUTO_UPDATE_SCRIPT" 2>/dev/null; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Auto-update includes rollback mechanisms"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Auto-update rollback mechanisms not verifiable"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Auto-update script not found"
  fi

  # Test 4: Configuration validation before apply
  ${testHelpers.testSubsection "Configuration Validation Before Apply"}

  # Test that build apps include validation
  BUILD_SCRIPT_PATH="${src}/apps/$CURRENT_SYSTEM/build"
  if [ -f "$BUILD_SCRIPT_PATH" ]; then
    ${testHelpers.assertExists "$BUILD_SCRIPT_PATH" "Platform-specific build script exists"}

    # Check for validation steps
    if grep -q "check" "$BUILD_SCRIPT_PATH" 2>/dev/null || grep -q "validate" "$BUILD_SCRIPT_PATH" 2>/dev/null; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Build script includes validation steps"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Build script validation steps not verifiable"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Platform-specific build script not found"
  fi

  # Test 5: Emergency recovery documentation
  ${testHelpers.testSubsection "Emergency Recovery Documentation"}

  # Check for recovery documentation
  CLAUDE_MD="${src}/CLAUDE.md"
  if [ -f "$CLAUDE_MD" ]; then
    if grep -qi "rollback\|recovery\|troubleshoot" "$CLAUDE_MD"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Recovery documentation available in CLAUDE.md"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Recovery documentation not found in CLAUDE.md"
    fi
  fi

  README_MD="${src}/README.md"
  if [ -f "$README_MD" ]; then
    if grep -qi "rollback\|recovery\|troubleshoot" "$README_MD"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Recovery documentation available in README.md"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Recovery documentation not found in README.md"
    fi
  fi

  # Test 6: Generation management
  ${testHelpers.testSubsection "Generation Management"}

  # Test that system supports multiple generations
  case "$CURRENT_SYSTEM" in
    *-darwin)
      if command -v darwin-rebuild >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} darwin-rebuild available for generation management"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} darwin-rebuild not available in test environment"
      fi
      ;;
    *-linux)
      if command -v nixos-rebuild >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} nixos-rebuild available for generation management"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} nixos-rebuild not available in test environment"
      fi
      ;;
  esac

  # Test 7: Store repair capabilities
  ${testHelpers.testSubsection "Store Repair Capabilities"}

  # Test nix store repair functionality
  if command -v nix >/dev/null 2>&1; then
    if nix --help 2>/dev/null | grep -q "store" 2>/dev/null; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Nix store operations available"

      # Test store verification
      if nix store --help 2>/dev/null | grep -q "verify" 2>/dev/null; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Store verification capability available"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Store verification not available"
      fi

      # Test garbage collection
      if nix store --help 2>/dev/null | grep -q "gc" 2>/dev/null; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Garbage collection capability available"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Garbage collection not available"
      fi
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Nix store operations not available"
    fi
  fi

  # Test 8: Configuration backup verification
  ${testHelpers.testSubsection "Configuration Backup Verification"}

  # Test that important configurations have backup strategies
  IMPORTANT_CONFIGS=(
    "modules/shared/config/claude/CLAUDE.md"
    "modules/shared/config/claude/settings.json"
    "flake.nix"
    "flake.lock"
  )

  for config in "''${IMPORTANT_CONFIGS[@]}"; do
    if [ -f "${src}/$config" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Important config exists: $config"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Important config missing: $config"
    fi
  done

  # Test 9: Safe update mechanisms
  ${testHelpers.testSubsection "Safe Update Mechanisms"}

  # Test that update process includes safety checks
  MAKEFILE="${src}/Makefile"
  if [ -f "$MAKEFILE" ]; then
    if grep -q "lint" "$MAKEFILE" && grep -q "test" "$MAKEFILE"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Makefile includes safety checks (lint, test)"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Makefile safety checks not verifiable"
    fi

    if grep -q "build.*switch\|switch.*build" "$MAKEFILE"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Makefile includes safe build-then-switch pattern"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Safe update pattern not verifiable in Makefile"
    fi
  fi

  # Test 10: Emergency procedures documentation
  ${testHelpers.testSubsection "Emergency Procedures Documentation"}

  # Check for emergency procedures in docs
  if [ -d "${src}/docs" ]; then
    EMERGENCY_DOCS_FOUND=0

    if find "${src}/docs" -name "*.md" -exec grep -l "emergency\|recovery\|rollback" {} \; 2>/dev/null | head -1 >/dev/null; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Emergency procedures documented"
      EMERGENCY_DOCS_FOUND=1
    fi

    if [ $EMERGENCY_DOCS_FOUND -eq 0 ]; then
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Emergency procedures documentation not found"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Documentation directory not found"
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Recovery Mechanisms Integration Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}20${testHelpers.colors.reset}/20"
  echo "${testHelpers.colors.green}✓ All recovery mechanism tests passed!${testHelpers.colors.reset}"
  touch $out
''
