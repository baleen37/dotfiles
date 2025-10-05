# Core flake configuration and inputs
# This module centralizes the basic flake setup and input definitions
#
# OVERVIEW:
#   Provides centralized configuration for flake inputs, system architectures,
#   and common utility functions used across the dotfiles project.
#
# EXPORTED FUNCTIONS:
#   - inputs: Centralized flake input definitions with version pinning
#   - systemArchitectures: Platform-specific architecture definitions
#   - utils: Common utility functions for system configuration
#
# USAGE:
#   let flakeConfig = import ./lib/flake-config.nix;
#   in {
#     inherit (flakeConfig) inputs systemArchitectures;
#     utils = flakeConfig.utils nixpkgs;
#   }
#
# VERSION: 2.0.0
# COMPATIBILITY: Nix flakes, nixfmt RFC 166 compliant
# LAST UPDATED: 2024-10-04

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
  #
  # DESCRIPTION: Cross-platform utility functions for flake operations
  # PARAMETERS: nixpkgs - The nixpkgs flake input for package access
  # RETURNS: Attribute set containing utility functions
  utils = nixpkgs: {
    # Generate attributes for all supported systems
    #
    # TYPE: (String -> a) -> AttrSet
    # DESCRIPTION: Maps a function over all supported system architectures
    # PARAMETERS: f - Function that takes a system string and returns a value
    # RETURNS: Attribute set with system names as keys and function results as values
    # EXAMPLE: forAllSystems (system: pkgs.hello) -> { x86_64-linux = <derivation>; ... }
    forAllSystems =
      f:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] f;

    # User resolution utilities with environment fallback
    #
    # TYPE: Function
    # DESCRIPTION: Import user resolution function for dynamic user detection
    # RETURNS: User resolution function that can be called with different formats
    getUserFn = import ./user-resolution.nix;

    # Get user string directly with fallback handling
    #
    # TYPE: String
    # DESCRIPTION: Resolves current user from environment with proper fallbacks
    # RETURNS: Username as string, defaults to "baleen" if detection fails
    getUser = (import ./user-resolution.nix) { returnFormat = "string"; };

    # Create development shell for a system
    #
    # TYPE: String -> AttrSet
    # DESCRIPTION: Creates a development shell with essential tools for the given system
    # PARAMETERS: system - Target system architecture (e.g., "x86_64-linux", "aarch64-darwin")
    # RETURNS: Attribute set containing shell configuration with development tools
    # TOOLS INCLUDED: git, formatters (nixfmt, shfmt, prettier), linters (shellcheck)
    # EXAMPLE: mkDevShell "aarch64-darwin" -> { default = <shell-derivation>; }
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
              nixfmt-rfc-style # Nix formatting (RFC 166 standard)
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
              echo "  - nixfmt-rfc-style (Nix files, RFC 166 standard)"
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
