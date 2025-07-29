# System configuration builders for Darwin and NixOS
# This module handles the construction of system configurations for different platforms

{ inputs, nixpkgs, ... }:
let
  # Extract inputs for cleaner access
  inherit (inputs) darwin nix-homebrew homebrew-bundle homebrew-core homebrew-cask disko home-manager;

  # Get user information
  getUserFn = import ./user-resolution.nix;
  userInfo = getUserFn { returnFormat = "string"; };
  user = "${userInfo}"; # Use as string for backward compatibility

  # Import modularized app and test builders (functions that take system)
  platformSystem = system: import ./platform-system.nix { pkgs = nixpkgs.legacyPackages.${system}; lib = nixpkgs.lib; inherit nixpkgs system; self = inputs.self; };
  testSystem = system: import ./test-system.nix { pkgs = nixpkgs.legacyPackages.${system}; inherit nixpkgs; self = inputs.self; };
in
{
  # Darwin system configuration builder
  mkDarwinConfigurations = systems:
    nixpkgs.lib.genAttrs systems (system:
      darwin.lib.darwinSystem {
        inherit system;
        specialArgs = inputs;
        modules = [
          ../modules/shared/config/nixpkgs.nix
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              inherit user;
              enable = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = false;
              autoMigrate = true;
            };
          }
          ../hosts/darwin
        ];
      }
    );

  # NixOS system configuration builder
  mkNixosConfigurations = systems:
    nixpkgs.lib.genAttrs systems (system:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs;
        modules = [
          ../modules/shared/config/nixpkgs.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ../modules/nixos/home-manager.nix;
              backupFileExtension = "bak";
              extraSpecialArgs = inputs;
            };
          }
          ../hosts/nixos
        ];
      }
    );

  # App configuration builders
  mkAppConfigurations = {
    # Linux apps builder
    mkLinuxApps = system:
      (let ps = platformSystem system; in if ps.apps.platformApps ? linux then ps.apps.platformApps.linux else {}) //
      (testSystem system).mkLinuxTestApps system;

    # Darwin apps builder
    mkDarwinApps = system:
      (let ps = platformSystem system; in if ps.apps.platformApps ? darwin then ps.apps.platformApps.darwin else {}) //
      (testSystem system).mkDarwinTestApps system;
  };

  # Development shell builder
  mkDevShells = forAllSystems: devShellFn: forAllSystems devShellFn;

  # Utility functions for system configuration
  utils = {
    # Check if system is Darwin
    isDarwin = system: builtins.match ".*-darwin" system != null;

    # Check if system is Linux
    isLinux = system: builtins.match ".*-linux" system != null;

    # Get architecture from system string
    getArch = system:
      if builtins.match "x86_64-.*" system != null then "x86_64"
      else if builtins.match "aarch64-.*" system != null then "aarch64"
      else throw "Unknown architecture in system: ${system}";

    # Get platform from system string
    getPlatform = system:
      if builtins.match ".*-darwin" system != null then "darwin"
      else if builtins.match ".*-linux" system != null then "linux"
      else throw "Unknown platform in system: ${system}";
  };
}
