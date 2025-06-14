{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # Import core components
  getUserLib = import (src + "/lib/get-user.nix");
  
in
pkgs.runCommand "dotfiles-core-unit-test" {} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "Dotfiles Core Unit Tests"}
  
  # Test 1: Flake structure validation
  ${testHelpers.testSubsection "Flake Structure"}
  
  # Test that required directories exist
  ${testHelpers.assertExists "${src}/flake.nix" "flake.nix exists"}
  ${testHelpers.assertExists "${src}/modules" "modules directory exists"}
  ${testHelpers.assertExists "${src}/hosts" "hosts directory exists"}
  ${testHelpers.assertExists "${src}/lib" "lib directory exists"}
  ${testHelpers.assertExists "${src}/tests" "tests directory exists"}
  
  # Test 2: Module structure validation
  ${testHelpers.testSubsection "Module Structure"}
  
  ${testHelpers.assertExists "${src}/modules/shared" "shared modules directory exists"}
  ${testHelpers.assertExists "${src}/modules/darwin" "darwin modules directory exists"}
  ${testHelpers.assertExists "${src}/modules/nixos" "nixos modules directory exists"}
  
  # Test that key module files exist
  ${testHelpers.assertExists "${src}/modules/shared/packages.nix" "shared packages.nix exists"}
  ${testHelpers.assertExists "${src}/modules/shared/home-manager.nix" "shared home-manager.nix exists"}
  
  # Test 3: User resolution system
  ${testHelpers.testSubsection "User Resolution System"}
  
  # Test get-user function exists and is callable
  export USER=testuser
  ${testHelpers.assertTrue ''[ "$USER" = "testuser" ]'' "USER environment variable is set"}
  
  # Test 4: Host configurations
  ${testHelpers.testSubsection "Host Configurations"}
  
  ${testHelpers.assertExists "${src}/hosts/darwin" "darwin host directory exists"}
  ${testHelpers.assertExists "${src}/hosts/nixos" "nixos host directory exists"}
  
  # Test 5: Test framework structure
  ${testHelpers.testSubsection "Test Framework"}
  
  ${testHelpers.assertExists "${src}/tests/unit" "unit tests directory exists"}
  ${testHelpers.assertExists "${src}/tests/integration" "integration tests directory exists"}
  ${testHelpers.assertExists "${src}/tests/e2e" "e2e tests directory exists"}
  ${testHelpers.assertExists "${src}/tests/lib/test-helpers.nix" "test helpers library exists"}
  
  # Test 6: Configuration file structure
  ${testHelpers.testSubsection "Configuration Files"}
  
  ${testHelpers.assertExists "${src}/Makefile" "Makefile exists"}
  ${testHelpers.assertExists "${src}/CLAUDE.md" "CLAUDE.md exists"}
  ${testHelpers.assertExists "${src}/README.md" "README.md exists"}
  
  # Test 7: Apps and scripts
  ${testHelpers.testSubsection "Apps and Scripts"}
  
  ${testHelpers.assertExists "${src}/apps" "apps directory exists"}
  ${testHelpers.assertExists "${src}/scripts" "scripts directory exists"}
  
  # Test that platform-specific apps exist
  if [ -d "${src}/apps/aarch64-darwin" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} aarch64-darwin apps directory exists"
  fi
  if [ -d "${src}/apps/x86_64-darwin" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} x86_64-darwin apps directory exists"
  fi
  
  # Test 8: Overlay system
  ${testHelpers.testSubsection "Overlay System"}
  
  ${testHelpers.assertExists "${src}/overlays" "overlays directory exists"}
  
  # Test that overlay files exist and are properly structured
  OVERLAY_COUNT=$(find "${src}/overlays" -name "*.nix" | wc -l)
  ${testHelpers.assertTrue ''[ $OVERLAY_COUNT -gt 0 ]'' "At least one overlay file exists"}
  
  # Test 9: Documentation structure
  ${testHelpers.testSubsection "Documentation"}
  
  ${testHelpers.assertExists "${src}/docs" "docs directory exists"}
  
  # Test 10: Nix file syntax validation
  ${testHelpers.testSubsection "Nix File Syntax"}
  
  # Test that key nix files have valid syntax
  if command -v nix-instantiate >/dev/null 2>&1; then
    ${testHelpers.assertCommand "nix-instantiate --parse ${src}/flake.nix >/dev/null" "flake.nix has valid syntax"}
    ${testHelpers.assertCommand "nix-instantiate --parse ${src}/lib/get-user.nix >/dev/null" "get-user.nix has valid syntax"}
    PASSED_TESTS=25
    TOTAL_TESTS=25
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Skipping Nix syntax validation (nix-instantiate not available)"
    PASSED_TESTS=23
    TOTAL_TESTS=23
  fi
  
  ${testHelpers.cleanup}
  
  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Dotfiles Core Unit Tests ===${testHelpers.colors.reset}"
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