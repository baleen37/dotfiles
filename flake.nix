{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, disko } @inputs:
    let
      # Import modular flake configuration
      flakeConfig = import ./lib/flake-config.nix;

      # Import modular system configuration builders
      systemConfigs = import ./lib/system-configs.nix { inherit inputs nixpkgs; };

      # Import modular check builders
      checkBuilders = import ./lib/check-builders.nix { inherit nixpkgs self; };

      # Use architecture definitions from flake config
      inherit (flakeConfig.systemArchitectures) linux darwin all;
      linuxSystems = linux;
      darwinSystems = darwin;

      # Use utilities from flake config
      utils = flakeConfig.utils nixpkgs;
      forAllSystems = utils.forAllSystems;

      # Development shell using flake config utils
      devShell = system: utils.mkDevShell system;
    in
    {
      # Development shells using modular config
      devShells = forAllSystems devShell;

      # Apps using modular app configurations
      apps =
        (nixpkgs.lib.genAttrs linuxSystems systemConfigs.mkAppConfigurations.mkLinuxApps) //
        (nixpkgs.lib.genAttrs darwinSystems systemConfigs.mkAppConfigurations.mkDarwinApps);

      # Checks using modular check builders
      checks = forAllSystems checkBuilders.mkChecks;

      # Darwin configurations using modular system configs
      darwinConfigurations = systemConfigs.mkDarwinConfigurations darwinSystems;

      # NixOS configurations using modular system configs
      nixosConfigurations = systemConfigs.mkNixosConfigurations linuxSystems;
    };
}
