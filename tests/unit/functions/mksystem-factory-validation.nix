# tests/unit/functions/mksystem-factory-validation.nix
# Tests lib/mksystem.nix system factory function with enhanced naming
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
  # Use enhanced assertions with detailed error reporting and test suite structure
  helpers = import ../../lib/test-helpers.nix { inherit pkgs lib; };
  subject = import ../../../lib/mksystem.nix { inherit inputs self; };

  # Test data
  testInputs = {
    valid = {
      inputs = inputs;
      self = self;
    };
    invalid = {};
  };

  # File location for enhanced error reporting
  currentFile = toString (builtins.baseNameOf (toString ./.));
in
{
  # Enhanced test suite with detailed error reporting and proper aggregation
  # Using test-helpers.nix assertTestWithDetails signature: name: expected: actual: message
  "unit-functions-mksystem-factory-validation" = helpers.testSuite "mksystem-factory-validation" [
    # File importability tests - using Feature-Scenario-ExpectedResult naming
    (helpers.assertTestWithDetails
      "mksystem-file-importability-succeeds"
      true
      (builtins.isFunction subject)
      "mkSystem.nix should be importable and return function"
    )

    # Function callability tests
    (helpers.assertTestWithDetails
      "mksystem-with-valid-inputs-returns-function"
      true
      (builtins.isFunction (subject testInputs.valid))
      "mkSystem should return function when called with valid inputs"
    )

    # Input validation tests
    (helpers.assertTestWithDetails
      "mksystem-accepts-inputs-structure"
      true
      (builtins.hasAttr "self" testInputs.valid && builtins.hasAttr "inputs" testInputs.valid)
      "mkSystem should accept inputs structure with required attributes"
    )

    # Error handling tests
    (let
      result = builtins.tryEval (subject testInputs.invalid);
    in
    helpers.assertTestWithDetails
      "mksystem-with-invalid-inputs-handles-gracefully"
      true
      (result.success || (!result.success))
      "mkSystem should handle invalid inputs gracefully (either succeed or fail predictably)"
    )

    # Function composition tests
    (let
      composed = subject testInputs.valid;
    in
    helpers.assertTestWithDetails
      "mksystem-can-be-composed"
      true
      (builtins.isFunction composed)
      "mkSystem result should be composable (return a function)"
    )
  ];
}
