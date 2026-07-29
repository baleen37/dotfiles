# tests/lib/test-helpers.nix
#
# The two primitives every test in this repo is built from.
#
#   assertTest name condition message
#     A derivation that builds iff `condition` is true. Because the whole suite
#     depends on it, a false condition fails `nix flake check`.
#
#   testSuite name tests
#     Aggregates assertions into one check. The `cat` of each test is what
#     creates the build dependency, so every assertion is really evaluated.
#
# Richer assertions (attribute paths, list membership, ...) live in
# common-assertions.nix; domain-specific ones in <domain>-test-helpers.nix.
{
  pkgs,
  lib,
  ...
}:

{
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
}
