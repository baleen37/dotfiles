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

      # Import performance optimization integration
      performanceIntegration = system: import ./lib/performance-integration.nix {
        inherit (nixpkgs) lib;
        pkgs = nixpkgs.legacyPackages.${system};
        inherit system inputs self;
      };

      # Use architecture definitions from flake config
      inherit (flakeConfig.systemArchitectures) linux darwin all;
      linuxSystems = linux;
      darwinSystems = darwin;

      # Use utilities from flake config
      utils = flakeConfig.utils nixpkgs;
      forAllSystems = utils.forAllSystems;

      # Development shell using flake config utils with performance optimization
      devShell = system:
        let
          baseShell = utils.mkDevShell system;
          perfIntegration = performanceIntegration system;
        in
        perfIntegration.performanceOptimizations.mkOptimizedDevShell baseShell;

    in
    let
      # Generate base outputs
      baseOutputs = {
        # Shared library functions - using unified systems
        lib = {
          # Unified systems (functions that take system as parameter)
          utilsSystem = system: import ./lib/utils-system.nix { pkgs = nixpkgs.legacyPackages.${system}; lib = nixpkgs.lib; };
          platformSystem = system: import ./lib/platform-system.nix { pkgs = nixpkgs.legacyPackages.${system}; lib = nixpkgs.lib; inherit nixpkgs self system; };
          errorSystem = system: import ./lib/error-system.nix { pkgs = nixpkgs.legacyPackages.${system}; lib = nixpkgs.lib; };
          testSystem = system: import ./lib/test-system.nix { pkgs = nixpkgs.legacyPackages.${system}; inherit nixpkgs self; };

          # Performance optimization libraries
          performanceIntegration = performanceIntegration;

          # Legacy compatibility - redirect to unified systems
          userResolution = import ./lib/user-resolution.nix;
        };

        # Development shells using modular config with performance optimization
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
    in
    baseOutputs;
}
