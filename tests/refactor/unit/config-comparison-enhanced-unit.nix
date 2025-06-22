{ pkgs, flake ? null, src }:
let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "config-comparison-enhanced-unit-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Configuration Comparison Enhanced Unit Tests"}

  # Test 1: Configuration difference detection
  ${testHelpers.testSubsection "Configuration Difference Detection"}

  # Test that config comparison library exists (will fail initially - TDD Red)
  CONFIG_COMPARE_LIB="${src}/tests/refactor/lib/config-compare-enhanced.nix"
  if [ -f "$CONFIG_COMPARE_LIB" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Enhanced config comparison library exists"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Enhanced config comparison library missing (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 2: Package list comparison functionality
  ${testHelpers.testSubsection "Package List Comparison"}

  # Test that package comparison function works
  if nix-instantiate --eval --expr 'let lib = import ${src}/tests/refactor/lib/config-compare-enhanced.nix { pkgs = import <nixpkgs> {}; }; in lib.comparePackageLists [] []' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Package list comparison function works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Package list comparison function failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 3: System settings comparison functionality
  ${testHelpers.testSubsection "System Settings Comparison"}

  # Test that system settings comparison function works
  if nix-instantiate --eval --expr 'let lib = import ${src}/tests/refactor/lib/config-compare-enhanced.nix { pkgs = import <nixpkgs> {}; }; in lib.compareSystemSettings {} {}' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System settings comparison function works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} System settings comparison function failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 4: Home-manager output comparison functionality
  ${testHelpers.testSubsection "Home Manager Output Comparison"}

  # Test that home-manager comparison function works
  if nix-instantiate --eval --expr 'let lib = import ${src}/tests/refactor/lib/config-compare-enhanced.nix { pkgs = import <nixpkgs> {}; }; in lib.compareHomeManagerConfigs {} {}' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Home-manager comparison function works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Home-manager comparison function failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 5: Configuration equivalence checking
  ${testHelpers.testSubsection "Configuration Equivalence Checking"}

  # Test that full configuration equivalence check works
  if nix-instantiate --eval --expr 'let lib = import ${src}/tests/refactor/lib/config-compare-enhanced.nix { pkgs = import <nixpkgs> {}; }; in lib.checkConfigEquivalence {} {}' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Configuration equivalence check works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Configuration equivalence check failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 6: Difference reporting functionality
  ${testHelpers.testSubsection "Difference Reporting"}

  # Test that difference reporting function works
  if nix-instantiate --eval --expr 'let lib = import ${src}/tests/refactor/lib/config-compare-enhanced.nix { pkgs = import <nixpkgs> {}; }; in lib.generateDifferenceReport {} {}' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Difference reporting function works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Difference reporting function failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 7: Ignore pattern functionality
  ${testHelpers.testSubsection "Ignore Pattern Handling"}

  # Test that ignore patterns work (timestamps, etc.)
  if nix-instantiate --eval --expr 'let lib = import ${src}/tests/refactor/lib/config-compare-enhanced.nix { pkgs = import <nixpkgs> {}; }; in lib.applyIgnorePatterns ["timestamps" "version-info"] {}' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Ignore pattern functionality works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Ignore pattern functionality failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 8: Platform-specific difference handling
  ${testHelpers.testSubsection "Platform-Specific Handling"}

  # Test that platform-specific differences are handled
  if nix-instantiate --eval --expr 'let lib = import ${src}/tests/refactor/lib/config-compare-enhanced.nix { pkgs = import <nixpkgs> {}; }; in lib.comparePlatformConfigs "darwin" {} {}' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Platform-specific comparison works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Platform-specific comparison failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Configuration Comparison Enhanced Unit Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}8${testHelpers.colors.reset}/8"
  echo "${testHelpers.colors.green}✓ All enhanced configuration comparison tests passed!${testHelpers.colors.reset}"
  touch $out
''
