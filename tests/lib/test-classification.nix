# Test classification library for stable vs unstable tests
{ lib, ... }:

let
  # Determine if a test is stable based on its characteristics
  isStableTest =
    testName: testDerivation:
    let
      # Stable test criteria
      hasNoNetworkDeps = !lib.hasPrefix "network-" testName;
      hasNoExternalServices = !lib.hasPrefix "integration-" testName;
      isPureNix = lib.hasSuffix "-test.nix" testName;
      isQuickBuild = testDerivation ? buildInputs && builtins.length testDerivation.buildInputs <= 5;
    in
    hasNoNetworkDeps && hasNoExternalServices && isPureNix && isQuickBuild;

  # Filter stable tests from all available tests
  getStableTests = tests: lib.filterAttrs (name: test: isStableTest name test) tests;

  # Check if a test platform supports stable testing
  supportsStableTesting =
    system:
    lib.elem system [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
in
{
  inherit isStableTest getStableTests supportsStableTesting;
}
