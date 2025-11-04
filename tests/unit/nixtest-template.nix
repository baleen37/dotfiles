# Minimal nixtest template for compatibility
{ pkgs, lib }:

let
  nixtest = {
    assertions = {
      assertHasAttr = name: set: builtins.hasAttr name set;
      assertContains = needle: haystack: lib.hasInfix needle haystack;
    };

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
        echo "🧪 Running test suite: ${name}"
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (testName: test: "cat ${test}") tests)}
        echo "✅ Test suite ${name}: All tests passed"
        touch $out
      '';
  };
in
{
  inherit nixtest;
}
