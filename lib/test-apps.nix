# Test Applications Module - Legacy Compatibility Wrapper
# Redirects to unified test-system.nix
# Provides test-related app definitions for both Darwin and Linux systems

{ nixpkgs, self }:

let
  # Import unified test system
  testSystem = import ./test-system.nix {
    pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "x86_64-linux"};
    inherit nixpkgs self;
  };

in
# Re-export test apps from unified system with legacy compatibility
{
  # Export core functions from unified system
  inherit (testSystem) mkTestApp mkTestApps;

  # For backwards compatibility
  mkLinuxTestApps = testSystem.mkLinuxTestApps;
  mkDarwinTestApps = testSystem.mkDarwinTestApps;

  # Version metadata
  version = "2.0.0-unified";
  description = "Test applications with unified backend";
}
