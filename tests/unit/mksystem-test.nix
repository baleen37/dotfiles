# tests/unit/mksystem-test.nix
# evantravers-style system factory tests
# Tests lib/mksystem.nix system factory function
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test 1: mkSystem function exists and is callable
  mkSystemFunc = import ../../lib/mksystem.nix { inherit inputs self; };
  testFunctionExists = builtins.isFunction mkSystemFunc;

  # Test 2: File can be imported and is usable (behavioral test)
  fileImportable =
    let
      importResult = builtins.tryEval (import ../../lib/mksystem.nix { inherit inputs self; });
    in
    importResult.success && builtins.isFunction importResult.value;

  # Test 3: Function can be called with inputs (basic test)
  canCallWithInputs = builtins.tryEval (mkSystemFunc inputs);

  # Test 4: The function returns a function when called with inputs
  returnsFunction = canCallWithInputs.success && builtins.isFunction canCallWithInputs.value;

in
helpers.testSuite "mksystem" [
  # Test mkSystem file importability and functionality
  (helpers.assertTest "mksystem-file-importable" fileImportable
    "mkSystem.nix should be importable and return a function"
  )

  # Test mkSystem function existence and callability
  (helpers.assertTest "mksystem-function-exists" testFunctionExists
    "mkSystem function should exist and be callable"
  )

  # Test mkSystem accepts inputs parameter
  (helpers.assertTest "mksystem-accepts-inputs" canCallWithInputs.success
    "mkSystem should accept inputs parameter"
  )

  # Test mkSystem returns function after inputs
  (helpers.assertTest "mksystem-returns-function" returnsFunction
    "mkSystem should return function after inputs are provided"
  )

  # Note: Smoke test skipped - calling mkSystem requires file dependencies
]
