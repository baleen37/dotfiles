{ pkgs }:

with pkgs;
let
  # Custom karabiner-elements version 14 (Darwin-only)
  karabiner-elements-14 = karabiner-elements.overrideAttrs (_oldAttrs: {
    version = "14.13.0";
    src = fetchurl {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
      sha256 = "1g3c7jb0q5ag3ppcpalfylhq1x789nnrm767m2wzjkbz3fi70ql2"; # pragma: allowlist secret
    };
  });

  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };

  # Platform-specific packages
  platform-packages = [
    dockutil
    karabiner-elements-14 # Advanced keyboard customizer for macOS (version 14)
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
