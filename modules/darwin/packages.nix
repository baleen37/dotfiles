{ pkgs }:

with pkgs;
let
  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };

  # Karabiner-Elements v14.13.0 (v15.0+ has nix-darwin compatibility issues)
  karabiner-elements-v14 = karabiner-elements.overrideAttrs (old: {
    version = "14.13.0";
    src = fetchurl {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
      hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
    };
  });

  # Platform-specific packages
  platform-packages = [
    dockutil
    karabiner-elements-v14
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
