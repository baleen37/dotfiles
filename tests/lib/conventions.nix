# Test Conventions and Standard Patterns
#
# This document defines the standard patterns for writing tests in this codebase.
# All tests should follow these conventions for consistency and maintainability.

{
  lib,
  pkgs,
}:

rec {
  # ==============================================================================
  # STANDARD TEST STRUCTURE
  # ==============================================================================

  # All test files must use one of these two standard structures:

  # Pattern 1: Platform-filtered test (recommended for most tests)
  # ---------------------------------------------------------------
  # This pattern allows tests to run on specific platforms only.
  #
  # {
  #   platforms = ["any"];  # or ["darwin"] or ["linux"] or ["darwin" "linux"]
  #   value = helpers.testSuite "test-name" [
  #     (helpers.assertTest "test-1" condition "message")
  #     (helpers.assertTest "test-2" condition "message")
  #   ];
  # }
  #
  # Platform values:
  # - ["any"]: Runs on all platforms
  # - ["darwin"]: macOS only
  # - ["linux"]: Linux only
  # - ["darwin" "linux"]: Both macOS and Linux

  # Pattern 2: Direct test suite (for platform-agnostic tests)
  # -----------------------------------------------------------
  # This pattern runs on all platforms without filtering.
  #
  # helpers.testSuite "test-name" [
  #   (helpers.assertTest "test-1" condition "message")
  #   (helpers.assertTest "test-2" condition "message")
  # ]

  # ==============================================================================
  # STANDARD HELPER IMPORT PATTERN
  # ==============================================================================

  # All test files must import helpers using this standard pattern:
  #
  # let
  #   helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  # in
  # # test structure here
  #
  # Note: Always use the variable name "helpers" (not "testHelpers", "h", etc.)

  # ==============================================================================
  # STANDARD TEST FILE HEADER
  # ==============================================================================

  # All test files must start with this standard header:
  #
  # # Single-line description of what is being tested
  # #
  # # Optional: More detailed description
  # # Optional: Even more details
  # { inputs, system, pkgs, lib, self, nixtest ? {}, ... }:
  #
  # Notes:
  # - First line is a concise description
  # - Blank comment line follows
  # - Additional comments provide context if needed
  # - Function parameters must include: inputs, system, pkgs, lib, self
  # - nixtest ? {} is required for compatibility
  # - ... pattern to accept additional parameters

  # ==============================================================================
  # NAMING CONVENTIONS
  # ==============================================================================

  # Test file names:
  # - Unit tests: tests/unit/<feature>-test.nix
  # - Integration tests: tests/integration/<feature>-test.nix
  # - Always end with -test.nix suffix

  # Test suite names:
  # - Use lowercase with hyphens: "git-configuration", "vim-settings"
  # - Should match the feature being tested
  # - Passed to helpers.testSuite as first argument

  # Individual test names:
  # - Use lowercase with hyphens: "git-enabled", "vim-plugins-exist"
  # - Should describe what is being tested
  # - Format: "<feature>-<aspect>-<expectation>"
  # - Passed to helpers.assertTest as first argument

  # Helper function names in let bindings:
  # - Use camelCase: hasPluginByName, mkConfigTest
  # - Should describe what they do
  # - Helper functions that create tests should start with "mk"

  # ==============================================================================
  # STANDARD ASSERTION PATTERNS
  # ==============================================================================

  # Basic assertion:
  # (helpers.assertTest "test-name" condition "failure message")

  # Assertion with details:
  # (helpers.assertTestWithDetails "test-name" expected actual "message")

  # File existence:
  # (helpers.assertFileExists "test-name" derivation "path/to/file")

  # Attribute existence:
  # (helpers.assertHasAttr "test-name" "attrName" attributeSet)

  # String contains:
  # (helpers.assertContains "test-name" "needle" "haystack")

  # Multiple related settings (bulk assertion):
  # (helpers.assertSettings "group-name" settings {
  #   key1 = expectedValue1;
  #   key2 = expectedValue2;
  # })

  # ==============================================================================
  # ANTI-PATTERNS TO AVOID
  # ==============================================================================

  # DON'T: Use direct pkgs.runCommand for tests
  # pkgs.runCommand "test-name" { } "echo 'pass'; touch $out"
  #
  # INSTEAD: Use helpers.testSuite
  # helpers.testSuite "test-name" [
  #   (helpers.assertTest "test-1" true "should pass")
  # ]

  # DON'T: Use variable names other than "helpers"
  # let h = import ../lib/test-helpers.nix { inherit pkgs lib; };
  #
  # INSTEAD: Always use "helpers"
  # let helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # DON'T: Mix test styles in the same file
  # { platforms = ["any"]; value = ... }
  # helpers.testSuite "other" [...]
  #
  # INSTEAD: Be consistent - either use platform filtering everywhere
  # or use direct testSuite everywhere

  # DON'T: Use nested attribute sets for tests (unless it's a legacy pattern)
  # {
  #   platforms = ["any"];
  #   value = {
  #     test1 = helpers.assertTest "test1" ...;
  #     test2 = helpers.assertTest "test2" ...;
  #   };
  # }
  #
  # INSTEAD: Use helpers.testSuite with a list of tests
  # {
  #   platforms = ["any"];
  #   value = helpers.testSuite "feature" [
  #     (helpers.assertTest "test1" ...)
  #     (helpers.assertTest "test2" ...)
  #   ];
  # }

  # ==============================================================================
  # EXAMPLE: STANDARD TEST FILE
  # ==============================================================================

  # # Feature Configuration Test
  # #
  # # Tests the feature configuration in users/shared/feature.nix
  # # Verifies that settings are properly configured.
  # { inputs, system, pkgs, lib, self, nixtest ? {}, ... }:
  #
  # let
  #   helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  #
  #   featureConfig = import ../../users/shared/feature.nix {
  #     inherit pkgs lib;
  #     config = { };
  #   };
  #
  # in
  # {
  #   platforms = ["any"];
  #   value = helpers.testSuite "feature" [
  #     (helpers.assertTest "feature-enabled" (
  #       featureConfig.programs.feature.enable == true
  #     ) "Feature should be enabled")
  #
  #     (helpers.assertTest "feature-has-settings" (
  #       featureConfig.programs.feature ? settings
  #     ) "Feature should have settings configured")
  #   ];
  # }

  # ==============================================================================
  # MIGRATION GUIDE
  # ==============================================================================

  # Converting legacy test format to standard format:
  #
  # Legacy format (nested attribute set):
  # {
  #   platforms = ["any"];
  #   value = {
  #     test1 = helpers.assertTest "test1" condition "message";
  #     test2 = helpers.assertTest "test2" condition "message";
  #   };
  # }
  #
  # Standard format (testSuite with list):
  # {
  #   platforms = ["any"];
  #   value = helpers.testSuite "feature-name" [
  #     (helpers.assertTest "test1" condition "message")
  #     (helpers.assertTest "test2" condition "message")
  #   ];
  # }

  # Converting direct pkgs.runCommand to testSuite:
  #
  # Legacy format:
  # pkgs.runCommand "test-name" { } ''
  #   echo "Test 1"
  #   [ condition ] || exit 1
  #   echo "Test 2"
  #   [ condition ] || exit 1
  #   touch $out
  # ''
  #
  # Standard format:
  # helpers.testSuite "test-name" [
  #   (helpers.assertTest "test-1" condition "Test 1 failed")
  #   (helpers.assertTest "test-2" condition "Test 2 failed")
  # ]
}
