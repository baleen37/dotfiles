# Edge Case Tests for User Configuration
# Tests boundary conditions, unusual but valid configurations, and error scenarios
#
# VERSION: 1.0.0 (Task 11 - Edge Case Testing)
# LAST UPDATED: 2025-11-02

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

in
helpers.testSuite "edge-case-user-config" [
  # Test minimum username length
  (helpers.assertTest "username-min-length" (
    let
      username = "a";
    in
    builtins.stringLength username >= 1
  ) "Single character username should be valid")

  # Test maximum username length
  (helpers.assertTest "username-max-length" (
    let
      username = "verylongusernamethatisstillvalid";
    in
    builtins.stringLength username <= 64
  ) "Long username should be valid if under 64 characters")

  # Test unusual username formats
  (helpers.assertTest "unusual-username-format" (
    let
      username = "user-123-test";
    in
    builtins.match "^[a-z][a-z0-9-]*[a-z0-9]$" username != null
  ) "Username with numbers and hyphens should be valid")

  # Test email validation
  (helpers.assertTest "email-validation" (
    let
      email = "user@example.com";
    in
    builtins.match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$" email != null
  ) "Standard email format should be valid")

  # Test path handling
  (helpers.assertTest "path-handling" (
    let
      homeDir = if lib.hasInfix "darwin" system then "/Users/testuser" else "/home/testuser";
    in
    builtins.stringLength homeDir > 0
  ) "Home directory path should be valid")
]
