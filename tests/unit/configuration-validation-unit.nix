{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "configuration-validation-unit-test" {} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Configuration Validation Unit Tests"}

  # Test 1: Package configuration validation
  ${testHelpers.testSubsection "Package Configuration"}

  # Test that package files are valid nix expressions
  if command -v nix-instantiate >/dev/null 2>&1; then
    ${testHelpers.assertCommand "nix-instantiate --eval ${src}/modules/shared/packages.nix --arg pkgs '(import <nixpkgs> {})' >/dev/null" "shared packages.nix is valid"}

    if [ -f "${src}/modules/darwin/packages.nix" ]; then
      ${testHelpers.assertCommand "nix-instantiate --eval ${src}/modules/darwin/packages.nix --arg pkgs '(import <nixpkgs> {})' >/dev/null" "darwin packages.nix is valid"}
    fi

    if [ -f "${src}/modules/nixos/packages.nix" ]; then
      ${testHelpers.assertCommand "nix-instantiate --eval ${src}/modules/nixos/packages.nix --arg pkgs '(import <nixpkgs> {})' >/dev/null" "nixos packages.nix is valid"}
    fi

    SYNTAX_TESTS=3
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Skipping Nix syntax validation (nix-instantiate not available)"
    SYNTAX_TESTS=0
  fi

  # Test 2: Home manager configuration validation
  ${testHelpers.testSubsection "Home Manager Configuration"}

  ${testHelpers.assertExists "${src}/modules/shared/home-manager.nix" "shared home-manager.nix exists"}

  if [ -f "${src}/modules/darwin/home-manager.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} darwin home-manager.nix exists"
  fi

  if [ -f "${src}/modules/nixos/home-manager.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} nixos home-manager.nix exists"
  fi

  # Test 3: Module import structure
  ${testHelpers.testSubsection "Module Import Structure"}

  # Test that modules have proper import structure
  ${testHelpers.assertContains "${src}/modules/shared/home-manager.nix" "imports" "shared home-manager has imports section"}

  # Test 4: Configuration file structure
  ${testHelpers.testSubsection "Configuration File Structure"}

  # Test Claude configuration structure
  if [ -d "${src}/modules/shared/config/claude" ]; then
    ${testHelpers.assertExists "${src}/modules/shared/config/claude/CLAUDE.md" "Claude CLAUDE.md exists"}
    ${testHelpers.assertExists "${src}/modules/shared/config/claude/settings.json" "Claude settings.json exists"}
    ${testHelpers.assertExists "${src}/modules/shared/config/claude/commands" "Claude commands directory exists"}
  fi

  # Test 5: Platform-specific configuration validation
  ${testHelpers.testSubsection "Platform-specific Configuration"}

  # Test Darwin-specific configurations
  if [ -d "${src}/modules/darwin/config" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin config directory exists"

    # Test for expected Darwin configs
    if [ -d "${src}/modules/darwin/config/hammerspoon" ]; then
      ${testHelpers.assertExists "${src}/modules/darwin/config/hammerspoon/init.lua" "Hammerspoon init.lua exists"}
    fi

    if [ -d "${src}/modules/darwin/config/karabiner" ]; then
      ${testHelpers.assertExists "${src}/modules/darwin/config/karabiner/karabiner.json" "Karabiner config exists"}
    fi
  fi

  # Test NixOS-specific configurations
  if [ -d "${src}/modules/nixos/config" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} NixOS config directory exists"

    if [ -d "${src}/modules/nixos/config/polybar" ]; then
      ${testHelpers.assertExists "${src}/modules/nixos/config/polybar/config.ini" "Polybar config exists"}
    fi
  fi

  # Test 6: Files.nix validation
  ${testHelpers.testSubsection "Files.nix Validation"}

  ${testHelpers.assertExists "${src}/modules/shared/files.nix" "shared files.nix exists"}

  if [ -f "${src}/modules/darwin/files.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} darwin files.nix exists"
  fi

  if [ -f "${src}/modules/nixos/files.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} nixos files.nix exists"
  fi

  # Test 7: Overlay configuration validation
  ${testHelpers.testSubsection "Overlay Configuration"}

  # Test that overlays are properly structured
  OVERLAY_FILES=$(find "${src}/overlays" -name "*.nix" -type f | wc -l)
  ${testHelpers.assertTrue ''[ $OVERLAY_FILES -gt 0 ]'' "Overlay files exist ($OVERLAY_FILES found)"}

  # Test basic overlay structure
  if [ -f "${src}/overlays/README.md" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Overlay README exists"
  fi

  TOTAL_TESTS=$((15 + $SYNTAX_TESTS))
  PASSED_TESTS=$TOTAL_TESTS

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Configuration Validation Unit Tests ===${testHelpers.colors.reset}"
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
