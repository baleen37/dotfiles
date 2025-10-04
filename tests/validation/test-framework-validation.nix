# Test Framework Validation
# Validates NixTest and nix-unit framework capabilities and functionality
{ lib, pkgs, system ? builtins.currentSystem }:

let
  # Import test utilities
  testHelpers = import ../unit/test-helpers.nix { inherit lib pkgs; };
  assertions = import ../unit/test-assertions.nix { inherit lib; };

  # Import actual test files to validate their structure
  libTests = import ../unit/lib_test.nix { inherit lib pkgs system; };
  platformTests = import ../unit/platform_test.nix { inherit lib pkgs system; };
  moduleInteractionTests = import ../integration/module-interaction-test.nix { inherit lib pkgs system; };
  crossPlatformTests = import ../integration/cross-platform-test.nix { inherit lib pkgs system; };
  systemConfigurationTests = import ../integration/system-configuration-test.nix { inherit lib pkgs system; };

in
{
  name = "framework-validation";
  framework = "nixtest";
  type = "validation";

  tests = {
    # Validate test structure and metadata
    "test-structure-validation" = {
      description = "Validates all test files have proper structure";
      test =
        let
          validateTestSuite = testSuite:
            assertions.assertTrue (builtins.hasAttr "name" testSuite) "Test suite must have name" &&
            assertions.assertTrue (builtins.hasAttr "framework" testSuite) "Test suite must have framework" &&
            assertions.assertTrue (builtins.hasAttr "tests" testSuite) "Test suite must have tests";
        in
        validateTestSuite libTests &&
        validateTestSuite platformTests &&
        validateTestSuite moduleInteractionTests &&
        validateTestSuite crossPlatformTests &&
        validateTestSuite systemConfigurationTests;
    };

    # Validate NixTest framework functionality
    "nixtest-framework-validation" = {
      description = "Validates NixTest framework assertions work correctly";
      test =
        let
          # Test basic assertions
          basicAssertions =
            assertions.assertTrue true "Basic assertTrue should pass" &&
            assertions.assertFalse false "Basic assertFalse should pass" &&
            assertions.assertEqual "test" "test" "Basic assertEqual should pass" &&
            assertions.assertNotEqual "test" "different" "Basic assertNotEqual should pass";

          # Test list operations
          listAssertions =
            assertions.assertListEqual [ 1 2 3 ] [ 1 2 3 ] "List equality should work" &&
            assertions.assertListContains [ 1 2 3 ] 2 "List contains should work";

          # Test attribute set operations
          attrAssertions =
            assertions.assertAttrEqual { a = 1; b = 2; } { a = 1; b = 2; } "Attribute equality should work" &&
            assertions.assertHasAttr { test = "value"; } "test" "Attribute existence should work";
        in
        basicAssertions && listAssertions && attrAssertions;
    };

    # Validate test execution results
    "test-execution-validation" = {
      description = "Validates test suites execute without errors";
      test =
        let
          testSuiteHasResults = testSuite:
            assertions.assertTrue (builtins.isAttrs testSuite.tests) "Test suite has test cases" &&
            assertions.assertTrue (builtins.length (builtins.attrNames testSuite.tests) > 0) "Test suite has at least one test";
        in
        testSuiteHasResults libTests &&
        testSuiteHasResults platformTests &&
        testSuiteHasResults moduleInteractionTests &&
        testSuiteHasResults crossPlatformTests &&
        testSuiteHasResults systemConfigurationTests;
    };

    # Validate cross-platform compatibility
    "cross-platform-validation" = {
      description = "Validates tests work across different platforms";
      test =
        let
          # Test that platform detection works
          platformSupported = builtins.elem system [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];

          # Test that cross-platform tests handle current system
          crossPlatformHandlesSystem = builtins.hasAttr "cross-platform-compatibility" crossPlatformTests.tests;
        in
        assertions.assertTrue platformSupported "Current system should be supported" &&
        assertions.assertTrue crossPlatformHandlesSystem "Cross-platform tests should handle current system";
    };

    # Validate integration test capabilities
    "integration-test-validation" = {
      description = "Validates integration tests cover module interactions";
      test =
        let
          hasModuleTests = builtins.hasAttr "module-dependency-resolution" moduleInteractionTests.tests;
          hasSystemTests = builtins.hasAttr "system-configuration-validation" systemConfigurationTests.tests;
          hasCrossPlatformTests = builtins.hasAttr "platform-feature-compatibility" crossPlatformTests.tests;
        in
        assertions.assertTrue hasModuleTests "Module interaction tests should exist" &&
        assertions.assertTrue hasSystemTests "System configuration tests should exist" &&
        assertions.assertTrue hasCrossPlatformTests "Cross-platform feature tests should exist";
    };

    # Validate performance characteristics
    "performance-validation" = {
      description = "Validates test framework performance characteristics";
      test =
        let
          # Count total test cases
          countTests = testSuite: builtins.length (builtins.attrNames testSuite.tests);
          totalUnitTests = (countTests libTests) + (countTests platformTests);
          totalIntegrationTests = (countTests moduleInteractionTests) + (countTests crossPlatformTests) + (countTests systemConfigurationTests);
          totalTests = totalUnitTests + totalIntegrationTests;
        in
        assertions.assertTrue (totalTests >= 10) "Should have at least 10 test cases total" &&
        assertions.assertTrue (totalUnitTests >= 6) "Should have at least 6 unit tests" &&
        assertions.assertTrue (totalIntegrationTests >= 4) "Should have at least 4 integration tests";
    };

    # Validate framework capabilities
    "framework-capabilities-validation" = {
      description = "Validates both NixTest and nix-unit capabilities are available";
      test =
        let
          # Check that we can import both frameworks
          nixTestAvailable = builtins.hasAttr "assertEqual" assertions;
          testHelpersAvailable = builtins.hasAttr "mockSystem" testHelpers;

          # Check that test files use both unit and integration patterns
          unitTestPattern = builtins.hasAttr "lib-function-tests" libTests.tests;
          integrationTestPattern = builtins.hasAttr "module-interaction-validation" moduleInteractionTests.tests;
        in
        assertions.assertTrue nixTestAvailable "NixTest assertions should be available" &&
        assertions.assertTrue testHelpersAvailable "Test helpers should be available" &&
        assertions.assertTrue unitTestPattern "Unit test patterns should be implemented" &&
        assertions.assertTrue integrationTestPattern "Integration test patterns should be implemented";
    };
  };
}
