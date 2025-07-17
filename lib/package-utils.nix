# Package Utilities - Legacy Compatibility Wrapper
# Redirects to unified utils-system.nix
# Package management and validation utilities

{ lib }:

let
  # Import unified utils system
  utilsSystem = import ./utils-system.nix { pkgs = import <nixpkgs> {}; inherit lib; };

in
# Re-export package utilities from unified system with legacy compatibility
{
  # Package merging and validation utilities
  inherit (utilsSystem.packages) mergePackageLists getPackageNames validatePackages;
  inherit (utilsSystem.packages) filterValidPackages packageExists getPackageSafe filterAvailablePackages;

  # Version metadata
  version = "2.0.0-unified";
  description = "Package utilities with unified backend";
}
