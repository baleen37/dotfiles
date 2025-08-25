{ pkgs }:

with pkgs;
let
  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };

  # Platform-specific packages
  platform-packages = [
    dockutil
    # karabiner-elements는 home-manager.nix에서 앱 링크로 관리
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
