# tests/default.nix
#
# Builds flake `checks` from the test tree.
#
#   tests/unit/*-test.nix          fast, evaluate configuration in isolation
#   tests/integration/*-test.nix   evaluate configurations against each other
#   tests/containers/*.nix         NixOS VM tests, Linux + KVM only
#
# Unit and integration tests are discovered automatically: drop in a
# `<feature>-test.nix` and it becomes `checks.<system>.{unit,integration}-<feature>`.
#
# A test file evaluates to one of:
#   - a derivation                          -> one check
#   - an attribute set of derivations       -> one check per attribute
#   - { platforms = [...]; value = <above>; }  -> the above, skipped off-platform
#
# See lib/platform-helpers.nix for the `platforms` metadata.
{
  inputs,
  system,
  self,
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;

  platformHelpers = import ./lib/platform-helpers.nix { inherit pkgs lib; };

  containerTests = {
    container-smoke = import ./containers/smoke-test.nix { inherit pkgs lib; };
    container-basic = import ./containers/basic-system.nix { inherit pkgs lib; };
    container-services = import ./containers/services.nix { inherit pkgs lib; };
    container-packages = import ./containers/packages.nix { inherit pkgs lib; };
  };

  # An import failure becomes a failing check rather than aborting the whole
  # evaluation, so one broken file does not hide the state of every other test.
  importTest =
    name: path:
    let
      result = builtins.tryEval (
        import path {
          inherit
            inputs
            system
            pkgs
            lib
            self
            ;
        }
      );
    in
    if result.success then
      result.value
    else
      pkgs.runCommand "test-import-failed-${name}" { } ''
        echo "❌ TEST IMPORT FAILED: ${name}"
        echo "   ${toString path}"
        echo "   Usually a missing argument or a platform-specific import."
        exit 1
      '';

  # `checks` must be a flat name -> derivation map, so a test that groups several
  # derivations in an attribute set is expanded into `<test>-<assertion>` entries.
  flatten =
    name: test:
    if lib.isDerivation test then
      { ${name} = test; }
    else
      lib.concatMapAttrs (subName: subTest: flatten "${name}-${subName}" subTest) test;

  # Discovers `*-test.nix` in `dir` and its subdirectories, keyed
  # `<prefix>-<feature>`; subdirectories extend the prefix with their name.
  discoverTests =
    prefix: dir:
    lib.concatMapAttrs (
      entry: type:
      if type == "directory" then
        discoverTests "${prefix}-${entry}" (dir + "/${entry}")
      else if lib.hasSuffix "-test.nix" entry then
        let
          name = "${prefix}-${lib.removeSuffix "-test.nix" entry}";
        in
        { ${name} = importTest name (dir + "/${entry}"); }
      else
        { }
    ) (builtins.readDir dir);

  platformTests =
    prefix: dir:
    lib.concatMapAttrs (name: test: flatten name (test.value or test)) (
      platformHelpers.filterPlatformTests (discoverTests prefix dir)
    );

  assertionChecks = platformTests "unit" ./unit // platformTests "integration" ./integration;

in
lib.mapAttrs (_name: pkgs.testers.nixosTest) containerTests
// assertionChecks
// {
  # `nix flake check --no-build` only *evaluates* checks, so a false assertion is
  # never noticed — and container tests make dropping --no-build impossible off
  # Linux+KVM. This aggregate is buildable on every platform, which is what
  # `make test-build` uses to actually run the assertions.
  all-assertions = pkgs.runCommand "all-assertions" { } ''
    ${lib.concatMapStringsSep "\n" (check: "cat ${check}") (lib.attrValues assertionChecks)}
    echo "✅ ${toString (builtins.length (lib.attrNames assertionChecks))} assertion checks passed"
    touch $out
  '';
}
