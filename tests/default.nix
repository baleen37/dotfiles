# tests/default.nix
{
  inputs,
  system,
  self,
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;

  # Import container tests - inline for now to avoid path issues
  containerTests = {
    basic = import ./containers/basic-system.nix { inherit pkgs lib; };
    # user-config = import ./containers/user-config.nix { inherit pkgs lib inputs self; };  # Temporarily disabled due to dependency issues
    services = import ./containers/services.nix { inherit pkgs lib; };
    packages = import ./containers/packages.nix { inherit pkgs lib; };
  };

  # Convert to nixosTest checks
  containerChecks = builtins.mapAttrs (name: test: pkgs.testers.nixosTest test) containerTests;

  # Automatic test discovery function (nixpkgs pattern)
  # Discovers all *-test.nix files in a directory
  discoverTests =
    dir: prefix:
    lib.pipe (builtins.readDir dir) [
      # Filter for .nix files, excluding helpers
      (lib.filterAttrs (
        name: type:
        type == "regular"
        && lib.hasSuffix "-test.nix" name
        && name != "default.nix"
        && name != "nixtest-template.nix"
      ))
      # Convert filename to test name and import
      (lib.mapAttrs' (
        name: _: {
          name = "${prefix}-${lib.removeSuffix "-test.nix" name}";
          value = import (dir + "/${name}") {
            inherit
              inputs
              system
              pkgs
              lib
              self
              ;
            inherit (nixtest) nixtest;
          };
        }
      ))
    ];

  # Import existing NixTest framework
  nixtest = import ./unit/nixtest-template.nix { inherit pkgs lib; };

  # Import mksystem function for testing
  mkSystem = import ../lib/mksystem.nix { inherit inputs self; };

in
{
  # Smoke test (explicit - it's special)
  smoke = pkgs.runCommand "smoke-test" { } ''
    echo "✅ Test infrastructure ready - automatic discovery enabled"
    touch $out
  '';
}
// containerChecks
// discoverTests ./unit "unit"
// discoverTests ./integration "integration"
# E2E tests are heavy VM tests - exclude from automatic discovery
# They are available individually via nix eval on the specific test files
