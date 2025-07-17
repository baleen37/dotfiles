# Common Utilities Library - Legacy Compatibility Wrapper
# Redirects to unified utils-system.nix
# Reusable functions for system detection, package filtering, and configuration operations

{ pkgs ? import <nixpkgs> {} }:

let
  # Import unified utils system
  utilsSystem = import ./utils-system.nix { inherit pkgs; lib = pkgs.lib; };

in
# Re-export utilities from unified system with legacy compatibility
{
  # System detection utilities
  inherit (utilsSystem) isSystem isDarwin isLinux;

  # Package filtering utilities
  inherit (utilsSystem) filterValidPackages;

  # Configuration merging utilities
  inherit (utilsSystem) mergeConfigs;

  # List manipulation utilities
  inherit (utilsSystem) unique flatten;

  # String utilities
  inherit (utilsSystem) joinStrings hasPrefix;

  # Version metadata
  version = "2.0.0-unified";
  description = "Common utilities with unified backend";
}
