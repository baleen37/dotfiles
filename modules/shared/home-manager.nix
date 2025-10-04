# Shared Home Manager Configuration (Optimized)
#
# Cross-platform Home Manager configuration with performance optimizations
# and modular architecture. This file provides common program configurations
# that work across macOS and NixOS.
#
# ARCHITECTURE:
#   - Core programs: Shell, Git, SSH, Development tools
#   - Platform detection: Optimized caching and conditional logic
#   - Configuration separation: Shared vs platform-specific settings
#   - Performance optimizations: Reduced evaluation overhead
#
# USAGE:
#   Import via platform-specific modules only:
#   - modules/darwin/home-manager.nix (macOS settings)
#   - modules/nixos/home-manager.nix (NixOS settings)
#
# VERSION: 2.0.0 (Phase 2 optimized)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, ...
}:

let
  # Direct configuration constants following dustinlyons pattern
  name = "Jiho Lee";
  email = "baleen37@gmail.com";
  user = config.home.username;

  # Simple platform detection - direct system checking
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Direct imports for shared configurations
  sharedFiles = import ./files.nix { inherit config pkgs lib; };
  sharedPackages = import ./packages.nix { inherit pkgs; };

  # Simple path helpers
  homeDir = config.home.homeDirectory;
  configDir = "${homeDir}/.config";
in
{
  # Allow unfree packages (required for claude-code)
  nixpkgs.config.allowUnfree = true;

  # Import program configurations (modular structure for single responsibility)
  imports = [
    ./programs/index.nix
  ];
  # Use lib.mkMerge for combining configurations following dustinlyons pattern
  home = lib.mkMerge [
    # Base configuration
    {
      # Import shared files and packages
      file = sharedFiles;
      packages = sharedPackages;

      # Simple activation scripts
      activation.setupClaudeConfig = ''
        CLAUDE_DIR="${homeDir}/.claude"
        CLAUDE_SOURCE="${homeDir}/dev/dotfiles/modules/shared/config/claude"

        if [[ -d "$CLAUDE_SOURCE" ]]; then
          if [[ ! -L "$CLAUDE_DIR" ]] || [[ "$(readlink "$CLAUDE_DIR")" != "$CLAUDE_SOURCE" ]]; then
            echo "Setting up Claude configuration..."
            rm -rf "$CLAUDE_DIR"
            ln -sf "$CLAUDE_SOURCE" "$CLAUDE_DIR"
          fi
        fi
      '';
    }

    # Darwin-specific configuration
    (lib.mkIf isDarwin {
      activation.setupDarwinOptimizations = ''
        echo "Applying macOS optimizations..."
        # Restart Dock if needed
        killall Dock 2>/dev/null || true
      '';
    })

    # Linux-specific configuration
    (lib.mkIf isLinux {
      activation.setupLinuxOptimizations = ''
        echo "Applying Linux optimizations..."
        mkdir -p "${configDir}"
      '';
    })
  ];







}
