# Platform Application Definitions - Legacy Compatibility Wrapper
# Redirects to unified platform-system.nix
# Provides common app builders for Darwin and Linux systems

{ nixpkgs, self }:

let
  # Import unified platform system with nixpkgs and self
  platformSystem = import ./platform-system.nix {
    pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "x86_64-linux"};
    inherit nixpkgs self;
  };

in
# Re-export apps from unified system with legacy compatibility
platformSystem.apps // {
  # Export current platform apps as the main interface
  inherit (platformSystem.apps) mkApp mkSetupDevApp mkBlAutoUpdateApp;
  inherit (platformSystem.apps) platformApps getCurrentPlatformApps;

  # Legacy function names for backward compatibility
  mkDarwinCoreApps = system:
    if platformSystem.apps.platformApps ? darwin then
      platformSystem.apps.platformApps.darwin
    else {};

  mkLinuxCoreApps = system:
    if platformSystem.apps.platformApps ? linux then
      platformSystem.apps.platformApps.linux
    else {};

  # Version metadata
  version = "2.0.0-unified";
  description = "Platform applications with unified backend";
}
