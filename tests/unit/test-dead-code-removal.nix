# Dead Code Removal Validation Test
#
# Ensures that after removing references to the non-existent lib/test-builders.nix,
# all modified files still evaluate correctly without errors

{ lib, ... }:

{
  # Test that lib_test.nix evaluates without test-builders references
  testLibTestEvaluation = {
    expr = builtins.tryEval (
      import ./lib_test.nix {
        inherit lib;
        pkgs = { };
        system = "x86_64-linux";
        nixtest = null;
        self = null;
      }
    );
    expected.success = true;
  };

  # Test that placeholder tests pass
  testPlaceholderTests = {
    expr =
      let
        libFunctionsTest = import ./nix/test-lib-functions.nix {
          inherit lib;
          runTests = tests: tests;
        };
        testBuildersTest = import ./lib/test-builders.nix {
          inherit lib;
          runTests = tests: tests;
        };
      in
      {
        libFunctions = libFunctionsTest.testPlaceholder.expr == libFunctionsTest.testPlaceholder.expected;
        testBuilders = testBuildersTest.testPlaceholder.expr == testBuildersTest.testPlaceholder.expected;
      };
    expected = {
      libFunctions = true;
      testBuilders = true;
    };
  };

  # Test that test-system.nix evaluates without broken imports
  testSystemEvaluation = {
    expr = builtins.tryEval (
      import ../../lib/test-system.nix {
        pkgs = {
          inherit lib;
        };
      }
    );
    expected.success = true;
  };
}
