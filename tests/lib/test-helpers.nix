# tests/lib/test-helpers.nix
{ pkgs, lib }:

rec {
  # Basic assertion helper
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

  # Derivation builds successfully
  assertBuilds =
    name: drv:
    pkgs.runCommand "test-${name}-builds" { } ''
      echo "Testing if ${drv.name} builds..."
      ${drv}/bin/* --version || true
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
}
