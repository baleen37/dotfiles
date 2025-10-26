# Extended test helpers for evantravers refactor
# Builds upon existing NixTest framework with additional assertions
{ pkgs, lib }:

let
  # Import existing NixTest framework
  nixtest = import ../unit/nixtest-template.nix { inherit pkgs lib; };
in

rec {
  # Re-export NixTest framework
  inherit (nixtest) nixtest;

  # Basic assertion helper (from evantravers refactor plan)
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

  # Attribute existence check (from evantravers refactor plan)
  # File existence check
  assertFileExists =
    name: derivation: path:
    assertTest name (builtins.pathExists "${derivation}/${path}")
      "File ${path} not found in derivation";

  # Attribute existence check
  assertHasAttr =
    name: attrName: set:
    assertTest name (builtins.hasAttr attrName set) "Attribute ${attrName} not found";

  # String contains check
  assertContains =
    name: needle: haystack:
    assertTest name (lib.hasInfix needle haystack) "${needle} not found in ${haystack}";

  # Derivation builds successfully (version-aware)
  assertBuilds =
    name: drv:
    pkgs.runCommand "test-${name}-builds" { buildInputs = [ drv ]; } ''
      echo "Testing if ${drv.name} builds..."
      ${drv}/bin/* --version 2>/dev/null || echo "Version check not available"
      echo "✅ ${name}: Builds successfully"
      touch $out
    '';

  # Test suite aggregator
  testSuite =
    name: tests:
    pkgs.runCommand "test-suite-${name}" { } ''
      echo "Running test suite: ${name}"
      ${lib.concatMapStringsSep "\n" (t: "cat ${t}") tests}
      echo "✅ Test suite ${name}: All tests passed"
      touch $out
    '';

  # Configuration file integrity test
  assertConfigIntegrity =
    name: configPath: expectedFiles:
    nixtest.test "config-integrity-${name}" (
      builtins.all (file: builtins.pathExists "${configPath}/${file}") expectedFiles
    );

  # System factory validation
  assertSystemFactory =
    name: systemConfig:
    nixtest.suite "system-factory-${name}" {
      hasConfig = nixtest.test "has config attribute" (
        nixtest.assertions.assertHasAttr "config" systemConfig
      );
      hasSpecialArgs = nixtest.test "has special args" (
        nixtest.assertions.assertHasAttr "_module" systemConfig
      );
    };
}
