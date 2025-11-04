# tests/default.nix
{
  inputs,
  system,
  self,
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;

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

  # Test classification library test
  unit-test-classification = import ./unit/test-classification-test.nix {
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
// discoverTests ./unit "unit"
// discoverTests ./integration "integration"
