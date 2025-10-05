# Test for lib/test-system.nix after BATS removal refactoring
# Validates that the test system works correctly with only native Nix testing

{
  pkgs ? import <nixpkgs> { },
}:

let
  testSystem = import ../../lib/test-system.nix {
    inherit pkgs;
    nixpkgs = pkgs;
  };
in
pkgs.lib.runTests {
  testMkTestApp = {
    expr = builtins.typeOf (
      testSystem.mkTestApp {
        name = "test-example";
        system = "x86_64-linux";
        command = "echo test";
      }
    );
    expected = "set";
  };

  testMkTestAppsStructure = {
    expr = builtins.attrNames (testSystem.mkTestApps "x86_64-linux");
    expected = [
      "test"
      "test-core"
      "test-integration"
      "test-list"
      "test-perf"
      "test-smoke"
      "test-unit"
      "test-workflow"
    ];
  };

  testRunSuiteExists = {
    expr = builtins.typeOf testSystem.runSuite;
    expected = "lambda";
  };

  testTestCategoriesComplete = {
    expr = builtins.sort builtins.lessThan (builtins.attrNames testSystem.testCategories);
    expected = [
      "all"
      "core"
      "integration"
      "performance"
      "smoke"
    ];
  };

  testNoUndefinedFunctions = {
    # Verify that runTest is no longer exported (was removed)
    expr = builtins.hasAttr "runTest" testSystem;
    expected = false;
  };

  testTestUtilsExported = {
    expr = builtins.all (name: builtins.hasAttr name testSystem) [
      "mkTestReporter"
      "mkTestDiscovery"
      "mkEnhancedTestRunner"
      "mkTestSuite"
    ];
    expected = true;
  };

  testConfigStructure = {
    expr = builtins.attrNames testSystem.testConfig;
    expected = [
      "defaultTimeout"
      "discoveryPatterns"
      "parallelSettings"
      "reportingOptions"
    ];
  };

  testMetadataComplete = {
    expr = {
      hasVersion = builtins.hasAttr "version" testSystem;
      hasDescription = builtins.hasAttr "description" testSystem;
      hasSupportedTypes = builtins.hasAttr "supportedTestTypes" testSystem;
    };
    expected = {
      hasVersion = true;
      hasDescription = true;
      hasSupportedTypes = true;
    };
  };
}
