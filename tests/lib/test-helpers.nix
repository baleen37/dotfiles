# tests/lib/test-helpers.nix
# Extended test helpers for evantravers refactor
# Builds upon existing NixTest framework with additional assertions
{ pkgs, lib }:

let
  # Import existing NixTest framework
  nixtest = import ../unit/nixtest-template.nix { inherit pkgs lib; };
in

rec {
  # Re-export NixTest framework
  inherit (nixtest) nixtest;

  # Additional helpers specific to evantravers refactor requirements
  # File existence check (NixOS system path aware)
  assertFileExists =
    name: derivation: path:
    nixtest.test "file-exists-${name}" (
      nixtest.assertions.assertTrue (builtins.pathExists "${derivation}/${path}")
    );

  # Derivation builds successfully (version-aware)
  assertBuilds =
    name: drv:
    pkgs.runCommand "test-${name}-builds" { buildInputs = [ drv ]; } ''
      echo "Testing if ${drv.name} builds..."
      ${drv}/bin/* --version 2>/dev/null || echo "Version check not available"
      echo "✅ ${name}: Builds successfully"
      touch $out
    '';

  # Test suite aggregator for refactor-specific tests
  refactorTestSuite =
    name: tests:
    pkgs.runCommand "refactor-test-suite-${name}" { } ''
      echo "Running refactor test suite: ${name}"
      ${lib.concatMapStringsSep "\n" (t: "cat ${t}") tests}
      echo "✅ Refactor test suite ${name}: All tests passed"
      touch $out
    '';

  # Configuration file integrity test
  assertConfigIntegrity =
    name: configPath: expectedFiles:
    nixtest.test "config-integrity-${name}" (
      builtins.all (file: builtins.pathExists "${configPath}/${file}") expectedFiles
    );

  # System factory validation
  assertSystemFactory =
    name: systemConfig:
    nixtest.suite "system-factory-${name}" {
      hasConfig = nixtest.test "has config attribute" (
        nixtest.assertions.assertHasAttr "config" systemConfig
      );
      hasSpecialArgs = nixtest.test "has special args" (
        nixtest.assertions.assertHasAttr "_module" systemConfig
      );
    };
}
