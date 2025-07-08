{ pkgs }:

with pkgs;
let
  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };


  # Platform-specific packages
  platform-packages = [
    dockutil
    # karabiner-elements is now installed via homebrew
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
