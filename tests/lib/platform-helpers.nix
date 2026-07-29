# tests/lib/platform-helpers.nix
#
# Platform gating for automatic test discovery.
#
# A test file that only makes sense on one platform declares it as metadata:
#
#   {
#     platforms = [ "darwin" ];   # or ["linux"], ["darwin" "linux"], ["any"]
#     value = helpers.testSuite "my-test" [ ... ];
#   }
#
# tests/default.nix drops any test whose `platforms` excludes the current system
# and unwraps `value` for the rest. A file with no `platforms` attribute — i.e. a
# bare derivation — runs everywhere.
#
# Declaring the requirement as metadata rather than branching inside the test
# keeps the skip out of the build log and off the check list entirely.
{ pkgs, lib }:

let
  currentPlatform =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "darwin"
    else if pkgs.stdenv.hostPlatform.isLinux then
      "linux"
    else
      "unknown";

  supportsCurrentPlatform = platform: platform == "any" || platform == currentPlatform;
in
{
  inherit currentPlatform;

  filterPlatformTests = lib.filterAttrs (
    _name: test: !(test ? platforms) || lib.any supportsCurrentPlatform test.platforms
  );
}
