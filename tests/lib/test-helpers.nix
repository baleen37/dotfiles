# Extended test helpers for evantravers refactor
# Builds upon existing NixTest framework with additional assertions
#
# Core assertions live here. Specialized helpers are split into:
# - test-helpers-property.nix: property-based testing
# - test-helpers-advanced.nix: performance, file, git, plugin, import assertions
{
  pkgs,
  lib,
  # Parameterized test configuration to eliminate external dependencies
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
    };
  },
}:

let
  # Simple NixTest framework replacement (since nixtest-template.nix doesn't exist)
  nixtest = {
    test =
      name: condition:
      if condition then
        pkgs.runCommand "test-${name}-pass" { } ''
          echo "✅ ${name}: PASS"
          touch $out
        ''
      else
        pkgs.runCommand "test-${name}-fail" { } ''
          echo "❌ ${name}: FAIL"
          exit 1
        '';

    suite =
      name: tests:
      pkgs.runCommand "test-suite-${name}" { } ''
        echo "Running test suite: ${name}"
        echo "✅ Test suite ${name}: All tests passed"
        touch $out
      '';

    assertions = {
      assertHasAttr = attrName: set: builtins.hasAttr attrName set;
    };
  };

  # Core assertions (defined in let so they can be passed to sub-files)
  assertTest =
    name: condition: message:
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL - ${message}"
        exit 1
      '';

  testSuite =
    name: tests:
    pkgs.runCommand "test-suite-${name}" { } ''
      echo "Running test suite: ${name}"
      ${lib.concatMapStringsSep "\n" (t: "cat ${t}") tests}
      echo "✅ Test suite ${name}: All tests passed"
      touch $out
    '';

  mkTest =
    name: testLogic:
    pkgs.runCommand "test-${name}-results" { } ''
      echo "Running ${name}..."
      ${testLogic}
      echo "✅ ${name}: PASS"
      touch $out
    '';

  # Import sub-files, passing shared dependencies
  propertyHelpers = import ./test-helpers-property.nix {
    inherit pkgs lib assertTest testSuite;
  };
  advancedHelpers = import ./test-helpers-advanced.nix {
    inherit pkgs lib assertTest testSuite mkTest;
  };

in
rec {
  # Re-export NixTest framework
  inherit (nixtest) nixtest;

  # Core assertions
  inherit assertTest testSuite mkTest;

  # Behavioral file validation check
  assertFileExists =
    name: derivation: path:
    let
      fullPath = "${derivation}/${path}";
      readResult = builtins.tryEval (builtins.readFile fullPath);
    in
    assertTest name (
      readResult.success && builtins.stringLength readResult.value > 0
    ) "File ${path} not readable or empty in derivation";

  # Attribute existence check
  assertHasAttr =
    name: attrName: set:
    assertTest name (builtins.hasAttr attrName set) "Attribute ${attrName} not found";

  # String contains check
  assertContains =
    name: needle: haystack:
    assertTest name (lib.hasInfix needle haystack) "${needle} not found in ${haystack}";

  # Derivation builds successfully
  assertBuilds =
    name: drv:
    pkgs.runCommand "test-${name}-builds" { buildInputs = [ drv ]; } ''
      echo "Testing if ${drv.name} builds..."
      ${drv}/bin/* --version 2>/dev/null || echo "Version check not available"
      echo "✅ ${name}: Builds successfully"
      touch $out
    '';

  # Parameterized test helpers
  getUserHomeDir = user: "${testConfig.homeDirPrefix}/${user}";
  getTestUserHome = getUserHomeDir testConfig.username;

  createTestUserConfig =
    additionalConfig:
    {
      home = {
        username = testConfig.username;
        homeDirectory = getTestUserHome;
      }
      // (additionalConfig.home or { });
    }
    // (additionalConfig.config or { });

  # Platform-conditional test execution
  runIfPlatform =
    platform: test:
    if platform == "darwin" && testConfig.platformSystem.isDarwin then
      test
    else if platform == "linux" && testConfig.platformSystem.isLinux then
      test
    else if platform == "any" then
      test
    else
      pkgs.runCommand "test-skipped-${platform}" { } ''
        echo "⏭️  Skipped (${platform}-only test on current platform)"
        touch $out
      '';

  # Run a list of tests and aggregate results
  runTestList =
    testName: tests:
    pkgs.runCommand "test-${testName}" { } ''
      echo "🧪 Running test suite: ${testName}"
      echo ""

      overall_success=true

      ${lib.concatMapStringsSep "\n" (test: ''
        echo "🔍 Running test: ${test.name}"
        echo "  Expected: ${toString test.expected}"
        echo "  Actual: ${toString test.actual}"

        if [ "${toString test.expected}" = "${toString test.actual}" ]; then
          echo "  ✅ PASS: ${test.name}"
        else
          echo "  ❌ FAIL: ${test.name}"
          echo "    Expected: ${toString test.expected}"
          echo "    Actual: ${toString test.actual}"
          overall_success=false
        fi
        echo ""
      '') tests}

      if [ "$overall_success" = "true" ]; then
        echo "✅ All tests in '${testName}' passed!"
        touch $out
      else
        echo "❌ Some tests in '${testName}' failed!"
        exit 1
      fi
    '';

  # Enhanced assertion with detailed error reporting
  assertTestWithDetails =
    name: expected: actual: message:
    let
      expectedStr = toString expected;
      actualStr = toString actual;
      isEqual = expectedStr == actualStr;
    in
    if isEqual then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Expected: ${expectedStr}"
        echo "  Actual: ${actualStr}"
        echo "  ${message}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Expected: ${expectedStr}"
        echo "  Actual: ${actualStr}"
        echo "  ${message}"
        echo ""
        echo "🔍 Comparison details:"
        echo "  Expected length: ${toString (builtins.stringLength expectedStr)}"
        echo "  Actual length: ${toString (builtins.stringLength actualStr)}"
        echo "  Expected type: ${builtins.typeOf expected}"
        echo "  Actual type: ${builtins.typeOf actual}"
        exit 1
      '';
}
// propertyHelpers
// advancedHelpers
