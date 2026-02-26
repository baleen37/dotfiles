# tests/lib/assertions.nix
# Re-export wrapper for backward compatibility
# All assertion functions are consolidated in test-helpers.nix

{ pkgs, lib }:

let
  helpers = import ./test-helpers.nix { inherit pkgs lib; };
in
{
  # Re-export the verbose variant as assertTestWithDetails to preserve
  # the original 7-argument API (name, condition, message, expected, actual, file, line)
  assertTestWithDetails = helpers.assertTestWithDetailsVerbose;
  inherit (helpers) assertFileContent;
}
