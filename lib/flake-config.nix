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
    linux = [ "x86_64-linux" "aarch64-linux" ];
    darwin = [ "aarch64-darwin" "x86_64-darwin" ];
    all = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
  };

  # Common utility functions for flake configuration
  utils = nixpkgs: {
    # Generate attributes for all systems
    forAllSystems = f: nixpkgs.lib.genAttrs
      ([ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ]) f;


    # Get user from environment with proper fallback
    getUserFn = import ./user-resolution.nix;
    getUser = (import ./user-resolution.nix) { returnFormat = "string"; };

    # Create development shell for a system
    mkDevShell = system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = with pkgs; mkShell {
          nativeBuildInputs = [ bashInteractive git ];
          shellHook = ''
            export EDITOR=vim
          '';
        };
      };
  };
}
