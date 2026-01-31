# Unit Test Template
#
# This is a template for writing unit tests.
# Copy this file to tests/unit/<feature>-test.nix and modify.
#
# Unit tests should:
# - Be fast (2-5 seconds execution time)
# - Test isolated functions and modules
# - Use helpers from tests/lib/test-helpers.nix
# - Follow the platform filtering pattern for platform-specific code
#
# Quick Start:
# 1. Copy this file: cp tests/unit/test-template.nix tests/unit/my-feature-test.nix
# 2. Edit the test configuration below
# 3. Run: make test
# 4. Run specific test: nix build '.#checks.<platform>.unit-my-feature' --impure

{
  inputs,
  system,
  # Standard parameters - all test files should include these
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  nixtest ? { },
  ...
}:

let
  # Import test helpers
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import additional helper libraries as needed
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };

  # ===== TEST DATA SETUP =====
  # Define test data and fixtures here

  # Example: Load configuration under test
  # myConfig = import ../../users/shared/my-feature.nix {
  #   inherit pkgs lib inputs;
  #   config = { };
  # };

  # Example: Load library under test
  # myLibrary = import ../../lib/my-library.nix;

in
{
  # ===== PLATFORM FILTERING =====
  # Specify which platforms this test should run on
  # - ["any"]: Run on all platforms (default)
  # - ["darwin"]: macOS only
  # - ["linux"]: Linux only
  # - ["darwin" "linux"]: Both macOS and Linux
  platforms = ["any"];

  # ===== TEST SUITE =====
  # Return the test suite value
  value = helpers.testSuite "my-feature" [
    # ===== BASIC ASSERTIONS =====
    # Use helpers.assertTest for simple conditions

    (helpers.assertTest "basic-example" (
      true  # Replace with actual test condition
    ) "This test should pass")

    # ===== ATTRIBUTE TESTS =====
    # Use assertions.assertAttrExists to check attributes

    # (assertions.assertAttrExists "has-required-attr" myConfig "someAttr" null)

    # ===== VALUE TESTS =====
    # Use assertions.assertAttrEquals to check specific values

    # (assertions.assertAttrEquals "attr-value" myConfig "someAttr" "expectedValue" null)

    # ===== LIST TESTS =====
    # Use assertions.assertListContains to check list membership

    # (assertions.assertListContains "has-required-item" myList "requiredItem" null)

    # ===== STRING TESTS =====
    # Use assertions.assertStringContains for substring checks

    # (assertions.assertStringContains "has-substring" myString "substring" null)

    # ===== FILE TESTS =====
    # Use helpers.assertFileExists to check file readability

    # (helpers.assertFileExists "config-file" myDerivation ".config/file.conf")

    # ===== PATTERN TESTS =====
    # Use patterns.testPackagesInstalled for package checks

    # (patterns.testPackagesInstalled "my-packages" myConfig [
    #   "git"
    #   "vim"
    #   "tmux"
    # ])

    # ===== COMPLEX TESTS =====
    # Combine multiple assertions for complex scenarios

    # (helpers.assertTest "complex-condition" (
    #   myConfig.enable == true
    #   && myConfig ? settings
    #   && builtins.length myConfig.settings > 0
    # ) "Complex condition should be true")

    # ===== PROPERTY-BASED TESTS =====
    # Use helpers.propertyTest to test invariants

    # (helpers.propertyTest "commutative-operation"
    #   (x: x + 1 == 1 + x)
    #   [1 2 3 4 5 0 -1]
    # )

    # Add more tests below...
  ];
}
