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

  # Test that files removed as dead code do not break imports
  testDeadCodeRemoved = {
    expr = {
      # Placeholder test files have been properly removed as dead code
      testBuildersRemoved = !builtins.pathExists ./lib/test-builders.nix;
      libFunctionsRemoved = !builtins.pathExists ./nix/test-lib-functions.nix;
    };
    expected = {
      testBuildersRemoved = true;
      libFunctionsRemoved = true;
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
