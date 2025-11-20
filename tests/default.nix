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
    "container-smoke" = import ./containers/smoke-test.nix { inherit pkgs lib; };
    basic = import ./containers/basic-system.nix { inherit pkgs lib; };
    # user-config = import ./containers/user-config.nix { inherit pkgs lib inputs self; };  # Temporarily disabled due to dependency issues
    services = import ./containers/services.nix { inherit pkgs lib; };
    packages = import ./containers/packages.nix { inherit pkgs lib; };
  };

  # Convert to nixosTest checks
  containerChecks = builtins.mapAttrs (name: test: pkgs.testers.nixosTest test) containerTests;

  # Automatic test discovery function (nixpkgs pattern)
  # Discovers all *-test.nix files in a directory and subdirectories
  discoverTests =
    dir: prefix:
    lib.pipe (builtins.readDir dir) [
      # Filter for .nix files, excluding helpers, and include subdirectories
      (lib.filterAttrs (
        name: type:
        (type == "regular"
          && lib.hasSuffix "-test.nix" name
          && name != "default.nix"
          && name != "nixtest-template.nix")
        || type == "directory"
      ))
      # Process both files and directories
      (lib.mapAttrs' (name: type:
        if type == "directory" then
          # Recursively discover tests in subdirectories
          {
            name = "${prefix}-${name}";
            value = discoverTests (dir + "/${name}") "${prefix}-${name}";
          }
        else
          # Import test file
          {
            name = "${prefix}-${lib.removeSuffix "-test.nix" name}";
            value = import (dir + "/${name}") {
              inherit
                inputs
                system
                pkgs
                lib
                self
                ;
              inherit nixtest;
            };
          }
      ))
    ];

  # Flatten nested discovery results
  flattenTests = tests:
    lib.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (name: value:
          if lib.isAttrs value && !builtins.hasAttr "name" value && !builtins.hasAttr "value" value then
            # This is a nested discovery result, flatten it
            lib.mapAttrsToList (subName: subValue: {
              inherit subName;
              name = "${name}-${subName}";
              value = subValue;
            }) (flattenTests value)
          else
            # This is a direct test
            { inherit name value; }
        ) tests
      )
    );

  # Import existing NixTest framework
  nixtest = import ./unit/nixtest-template.nix { inherit pkgs lib; };

  # Import platform helpers for platform-aware test discovery
  # platformHelpers = import ./lib/platform-helpers.nix { inherit pkgs lib; };

  # Import mksystem function for testing
  mkSystem = import ../lib/mksystem.nix { inherit inputs self; };

  # Platform-specific test discovery function (commented out due to path resolution issues in flake evaluation)
  # discoverPlatformTests = dir: prefix:
  #   let
  #     discoveredTests = discoverTests dir prefix;
  #   in
  #   platformHelpers.filterPlatformTests discoveredTests;

in
{
  # Smoke test (explicit - it's special)
  smoke = pkgs.runCommand "smoke-test" { } ''
    echo "✅ Test infrastructure ready - automatic discovery enabled"
    touch $out
  '';
}
// containerChecks
// (flattenTests (discoverTests ./unit "unit") // (
  # Add the new mksystem tests explicitly by flattening the set
  import ./unit/functions/mksystem-factory-validation.nix {
    inherit inputs system pkgs lib self;
    inherit nixtest;
  }
))
// flattenTests (discoverTests ./integration "integration")
# E2E tests are heavy VM tests - exclude from automatic discovery
# They are available individually via nix eval on the specific test files
