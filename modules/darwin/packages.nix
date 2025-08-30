{ pkgs }:

with pkgs;
let
  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };


  # Platform-specific packages
  platform-packages = [
    dockutil
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
