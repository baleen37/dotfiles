# Core flake configuration and inputs
# This module centralizes the basic flake setup and input definitions

{
  # Core flake metadata
  description = "Starter Configuration for MacOS and NixOS";

  # Centralized input definitions
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

  # System architecture definitions
  systemArchitectures = {
    linux = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    darwin = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    all = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };

  # Common utility functions for flake configuration
  utils = nixpkgs: {
    # Generate attributes for all systems
    forAllSystems =
      f:
      nixpkgs.lib.genAttrs ([
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ]) f;

    # Get user from environment with proper fallback
    getUserFn = import ./user-resolution.nix;
    getUser = (import ./user-resolution.nix) { returnFormat = "string"; };

    # External configuration system
    configValidator = import ./config-validator-simple.nix { lib = nixpkgs.lib; };
    configLoader = import ./config-loader.nix { lib = nixpkgs.lib; };

    # Load all external configurations with validation
    loadExternalConfigs =
      configDir: (import ./config-loader.nix { lib = nixpkgs.lib; }).loadAllConfigs configDir;

    # Helper function to get validated config for use in modules
    getValidatedConfig =
      configDir: configType:
      let
        configResult =
          (import ./config-loader.nix { lib = nixpkgs.lib; }).loadConfig configType
            "${configDir}/${configType}.yaml";
      in
      if configResult.validation.valid then
        configResult.config
      else
        throw "Invalid ${configType} configuration: ${nixpkgs.lib.concatStringsSep ", " configResult.validation.errors}";

    # Helper function to merge external config with module defaults
    mergeExternalConfig =
      configDir: configType: moduleDefaults:
      let
        configResult =
          (import ./config-loader.nix { lib = nixpkgs.lib; }).loadConfig configType
            "${configDir}/${configType}.yaml";
        baseConfig = if configResult.validation.valid then configResult.config else moduleDefaults;
      in
      nixpkgs.lib.recursiveUpdate moduleDefaults baseConfig;

    # Create development shell for a system
    mkDevShell =
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        default =
          with pkgs;
          mkShell {
            nativeBuildInputs = [
              bashInteractive
              git
              # Auto-formatting tools
              nixpkgs-fmt # Nix formatting
              shfmt # Shell script formatting
              nodePackages.prettier # YAML, JSON, Markdown formatting
              jq # JSON formatting and manipulation
              yq-go # YAML formatting and manipulation
              # Development tools
              pre-commit # Pre-commit hooks
              shellcheck # Shell script linting
            ];
            shellHook = ''
              export EDITOR=vim
              echo "🔧 Auto-formatting tools available:"
              echo "  - nixpkgs-fmt (Nix files)"
              echo "  - shfmt (Shell scripts)"
              echo "  - prettier (YAML, JSON, Markdown)"
              echo "  - jq (JSON)"
              echo "  - yq (YAML)"
              echo ""
              echo "💡 Run 'make format' to auto-format all files"
            '';
          };
      };
  };
}
