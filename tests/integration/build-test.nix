# tests/integration/build-test.nix
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

in
if pkgs.stdenv.isDarwin then
  let
    # Try to build the full system
    fullSystem = inputs.self.darwinConfigurations.macbook-pro;
  in
  helpers.testSuite "integration-build" [
    (helpers.assertTest "system-has-config" (fullSystem ? config) "Full system should have config")

    (helpers.assertTest "home-manager-loaded" (
      fullSystem.config ? home-manager
    ) "Home Manager should be loaded")
  ]
else
  # Skip test on non-Darwin systems
  pkgs.runCommand "integration-build-skipped" { } ''
    echo "⏭️  Skipped (Darwin-only test on ${system})"
    touch $out
  ''
