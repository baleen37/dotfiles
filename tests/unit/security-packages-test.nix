# Security Packages Test
# Tests that required security tools (age, sops) are installed
# and deprecated tools (git-crypt, gnupg) are removed
#
# VERSION: 1.0.0
# LAST UPDATED: 2025-12-04

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

  # Import home-manager configuration to test packages
  hmConfig = import ../../users/shared/home-manager.nix {
    inherit pkgs lib inputs;
    currentSystemUser = "testuser";
  };

  # Extract package names from home.packages
  packageNames = map (pkg: pkg.pname or pkg.name or "") hmConfig.home.packages;

in
helpers.testSuite "security-packages" [
  # Test that age is installed
  (helpers.assertTest "age-installed" (
    builtins.any (name: name == "age") packageNames
  ) "age should be in home.packages")

  # Test that sops is installed
  (helpers.assertTest "sops-installed" (
    builtins.any (name: name == "sops") packageNames
  ) "sops should be in home.packages")

  # Test that git-crypt is NOT installed
  (helpers.assertTest "git-crypt-removed" (
    !(builtins.any (name: name == "git-crypt") packageNames)
  ) "git-crypt should NOT be in home.packages")

  # Test that gnupg is NOT installed
  (helpers.assertTest "gnupg-removed" (
    !(builtins.any (name: name == "gnupg") packageNames)
  ) "gnupg should NOT be in home.packages")
]
