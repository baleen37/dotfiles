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
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Inspect each category package module directly to collect its package list.
  # Each module under users/shared/packages/ exposes `myHome.packages.<cat>.enable`
  # (default true) and emits `home.packages` via `config = lib.mkIf cfg.enable {...}`.
  # We invoke the body with the option enabled to extract the contributed package list.
  categoryModules = [
    "ai"
    "cloud"
    "core"
    "databases"
    "dev"
    "fonts"
    "lsp"
    "media"
    "nix-tools"
    "security"
    "ssh"
  ];

  # Declare the minimal `home.packages` option locally so evalModules can merge
  # `home.packages = ...` from each category module without pulling in home-manager.
  homeOptionsModule = {
    options.home.packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };

  evalCategory =
    name:
    (lib.evalModules {
      modules = [
        homeOptionsModule
        (import (../../users/shared/packages + "/${name}.nix"))
        { _module.args = { inherit pkgs; }; }
      ];
    }).config.home.packages;

  allPackages = lib.concatMap evalCategory categoryModules;
  packageNames = map (pkg: pkg.pname or pkg.name or "") allPackages;

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "security-packages" [
    # Test that age is installed
    (helpers.assertTest "age-installed" (builtins.any (
      name: name == "age"
    ) packageNames) "age should be in home.packages")

    # Test that sops is installed
    (helpers.assertTest "sops-installed" (builtins.any (
      name: name == "sops"
    ) packageNames) "sops should be in home.packages")

    # Test that git-crypt is NOT installed
    (helpers.assertTest "git-crypt-removed" (
      !(builtins.any (name: name == "git-crypt") packageNames)
    ) "git-crypt should NOT be in home.packages")

    # Test that gnupg is NOT installed
    (helpers.assertTest "gnupg-removed" (
      !(builtins.any (name: name == "gnupg") packageNames)
    ) "gnupg should NOT be in home.packages")
  ];
}
