# Simplified test helpers for dotfiles project
# Focused on essential testing patterns without over-engineering
{
  pkgs,
  lib,
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
      isLinux = pkgs.stdenv.isLinux;
    };
  },
}:

let
  # Import minimal nixtest framework
  nixtest = import ../unit/nixtest-template.nix { inherit pkgs lib; };
in

rec {
  # Re-export nixtest framework
  inherit (nixtest) nixtest;

  # Core assertion helpers
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

  # File existence validation
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
      echo "Testing if ${drv.name or name} builds..."
      echo "✅ ${name}: Builds successfully"
      touch $out
    '';

  # Simple test helper - main entry point for most tests
  mkTest =
    name: testLogic:
    pkgs.runCommand "test-${name}" { } ''
      echo "🧪 Running ${name}..."
      ${testLogic}
      echo "✅ ${name}: PASS"
      touch $out
    '';

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

  # Test suite aggregator for combining multiple tests
  testSuite =
    name: tests:
    pkgs.runCommand "test-suite-${name}" { } ''
      echo "🧪 Running test suite: ${name}"
      echo ""

      # Run all tests and collect results
      ${lib.concatMapStringsSep "\n" (test: ''
        echo "🔍 Running: ${test.name or "unnamed test"}"
        if [ -f "${test}" ]; then
          echo "✅ ${test.name or "test"}: PASS"
        else
          echo "❌ ${test.name or "test"}: FAIL"
          exit 1
        fi
      '') (builtins.attrValues tests)}

      echo ""
      echo "✅ Test suite '${name}': All tests passed"
      touch $out
    '';

  # User directory helpers
  getUserHomeDir = user: "${testConfig.homeDirPrefix}/${user}";
  getTestUserHome = getUserHomeDir testConfig.username;

  # Create test configuration for modules
  createTestUserConfig =
    additionalConfig:
    {
      home = {
        username = testConfig.username;
        homeDirectory = getTestUserHome;
      } // (additionalConfig.home or { });
    } // (additionalConfig.config or { });

  # Backward compatibility
  mkSimpleTest = mkTest;
}
