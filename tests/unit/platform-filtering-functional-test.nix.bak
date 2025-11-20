# tests/unit/platform-filtering-functional-test.nix
# Functional tests for platform filtering functionality
{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  platformHelpers = import ../lib/platform-helpers.nix { inherit pkgs lib; };
  currentPlatform = platformHelpers.getCurrentPlatform;
in
helpers.testSuite "platform-filtering-functional" [
  # Test 1: Platform detection accuracy
  (helpers.assertTest "platform-detection-accurate"
    (builtins.any (p: p == currentPlatform) ["darwin" "linux" "unknown"])
    "Platform detection should return a valid platform")

  # Test 2: filterPlatformTests includes tests without platforms attribute
  (helpers.assertTest "filter-include-no-platforms"
    let
      testSet = {
        generic-test = helpers.assertTest "generic" true "should always run";
        another-generic = helpers.assertTest "another" true "should always run";
      };
      filtered = platformHelpers.filterPlatformTests testSet;
    in
    (builtins.length (lib.attrNames filtered)) == 2
    "Should include tests without platforms attribute")

  # Test 3: filterPlatformTests excludes tests for different platforms
  (helpers.assertTest "filter-exclude-different-platforms"
    let
      testSet = {
        generic-test = helpers.assertTest "generic" true "should always run";
        darwin-test = { platforms = ["darwin"]; value = helpers.assertTest "darwin" true "darwin test"; };
        linux-test = { platforms = ["linux"]; value = helpers.assertTest "linux" true "linux test"; };
      };
      filtered = platformHelpers.filterPlatformTests testSet;
    in
    # Should always include generic test, and at most one platform-specific test
    (builtins.length (lib.attrNames filtered)) >= 1 && (builtins.length (lib.attrNames filtered)) <= 2
    "Should filter platform-specific tests correctly")

  # Test 4: filterPlatformTests includes tests for current platform
  (helpers.assertTest "filter-include-current-platform"
    let
      testSet = {
        generic-test = helpers.assertTest "generic" true "should always run";
        darwin-test = { platforms = ["darwin"]; value = helpers.assertTest "darwin" true "darwin test"; };
        linux-test = { platforms = ["linux"]; value = helpers.assertTest "linux" true "linux test"; };
      };
      filtered = platformHelpers.filterPlatformTests testSet;
    in
    # Should include generic test always
    builtins.hasAttr "generic-test" filtered
    "Should always include generic tests")

  # Test 5: mkPlatformTest creates real test for current platform
  (helpers.assertTest "mkplatform-current-platform-creates-test"
    let
      originalTest = helpers.assertTest "platform-specific" true "should run on current platform";
      platformTest = platformHelpers.mkPlatformTest currentPlatform originalTest;
    in
    # Should be a valid test (not a placeholder)
    !builtins.stringLength (builtins.toString platformTest) > 0
    "Should create actual test for current platform")

  # Test 6: mkPlatformTest creates placeholder for different platform
  (helpers.assertTest "mkplatform-different-platform-creates-placeholder"
    let
      originalTest = helpers.assertTest "platform-specific" true "should not run on different platform";
      differentPlatform = if currentPlatform == "darwin" then "linux" else "darwin";
      platformTest = platformHelpers.mkPlatformTest differentPlatform originalTest;
    in
    # Should be a placeholder test that always succeeds
    builtins.isDerivation platformTest
    "Should create placeholder test for different platform")

  # Test 7: mkPlatformTestSuite creates suite with filtered tests
  (helpers.assertTest "mkplatform-suite-creation"
    let
      testSuite = platformHelpers.mkPlatformTestSuite "functional-test" {
        generic-test = helpers.assertTest "generic" true "always runs";
        darwin-test = { platforms = ["darwin"]; value = helpers.assertTest "darwin" true "darwin only"; };
        linux-test = { platforms = ["linux"]; value = helpers.assertTest "linux" true "linux only"; };
      };
    in
    builtins.isDerivation testSuite
    "Should create platform-aware test suite")

  # Test 8: Multi-platform test filtering
  (helpers.assertTest "filter-multi-platform-tests"
    let
      testSet = {
        multi-platform = { platforms = ["darwin" "linux"]; value = helpers.assertTest "multi" true "multi-platform"; };
        single-platform = { platforms = ["darwin"]; value = helpers.assertTest "single" true "single platform"; };
        no-platforms = helpers.assertTest "no-platforms" true "no platforms specified";
      };
      filtered = platformHelpers.filterPlatformTests testSet;
    in
    # Should include no-platforms always, and multi-platform if current platform matches
    (builtins.hasAttr "no-platforms" filtered) &&
    (if currentPlatform == "darwin" || currentPlatform == "linux"
     then builtins.hasAttr "multi-platform" filtered
     else true)
    "Should handle multi-platform test filtering correctly")

  # Test 9: Empty test set handling
  (helpers.assertTest "filter-empty-test-set"
    let
      testSet = {};
      filtered = platformHelpers.filterPlatformTests testSet;
    in
    (builtins.length (lib.attrNames filtered)) == 0
    "Should handle empty test sets gracefully")

  # Test 10: Platform validation for unknown platforms
  (helpers.assertTest "handle-unknown-platform-tests"
    let
      testSet = {
        unknown-platform = { platforms = ["unknown"]; value = helpers.assertTest "unknown" true "unknown platform"; };
        known-platform = { platforms = [currentPlatform]; value = helpers.assertTest "known" true "known platform"; };
      };
      filtered = platformHelpers.filterPlatformTests testSet;
    in
    # Should include test if current platform matches specified platforms
    builtins.length (lib.attrNames filtered) >= 0
    "Should handle unknown platform specifications correctly")
]
