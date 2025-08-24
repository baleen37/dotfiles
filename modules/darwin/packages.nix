{ pkgs }:

with pkgs;
let
  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };


  # Platform-specific packages
  platform-packages = [
    dockutil
    # karabiner-elements-14 is now provided by shared/packages.nix
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
