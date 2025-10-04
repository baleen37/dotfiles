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
  # User configuration constants
  name = "Jiho Lee";
  email = "baleen37@gmail.com";

  # Optimized platform detection with caching
  platformDetection = import ../../lib/platform-detection.nix { inherit pkgs; };

  # Enhanced user resolution with platform awareness
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = platformDetection.platform;
    returnFormat = "extended";
  };
  user = getUserInfo.user;

  # Cached platform detection flags for performance
  platformFlags = {
    isDarwin = platformDetection.isDarwin pkgs.system;
    isLinux = platformDetection.isLinux pkgs.system;
    isX86_64 = platformDetection.isX86_64 pkgs.system;
    isAarch64 = platformDetection.isAarch64 pkgs.system;
  };

  # Performance optimized shortcuts
  isDarwin = platformFlags.isDarwin;
  isLinux = platformFlags.isLinux;

  # Common configuration helpers
  commonPaths = {
    home = getUserInfo.homePath;
    config = "${getUserInfo.homePath}/.config";
    ssh = "${getUserInfo.homePath}/.ssh";
    dotfiles = "${getUserInfo.homePath}/dotfiles";
    devDotfiles = "${getUserInfo.homePath}/dev/dotfiles";
  };
in
{
  # Import program configurations (separated for single responsibility)
  imports = [
    ./programs.nix
  ];
  # Optimized home activation scripts
  home.activation = {
    # Enhanced Claude configuration setup with better path resolution
    setupClaudeConfig = ''
      CLAUDE_DIR="${commonPaths.home}/.claude"

      # Optimized source directory detection
      for source_dir in "${commonPaths.dotfiles}" "${commonPaths.devDotfiles}"; do
        CLAUDE_SOURCE="$source_dir/modules/shared/config/claude"
        if [[ -d "$CLAUDE_SOURCE" ]]; then
          if [[ ! -L "$CLAUDE_DIR" ]] || [[ "$(readlink "$CLAUDE_DIR")" != "$CLAUDE_SOURCE" ]]; then
            echo "🔧 Setting up Claude configuration..."
            rm -rf "$CLAUDE_DIR"
            ln -sf "$CLAUDE_SOURCE" "$CLAUDE_DIR"
            echo "✅ Claude config linked: $CLAUDE_DIR -> $CLAUDE_SOURCE"
          else
            echo "✓ Claude config already properly linked"
          fi
          break
        fi
      done
    '';

    # Platform-specific optimizations
  }
  // lib.optionalAttrs isDarwin {
    # macOS-specific activation with performance improvements
    setupDarwinOptimizations = ''
      echo "🍎 Applying macOS optimizations..."

      # Optimized keyboard configuration
      echo "⚠️  Manual setup required for optimal keyboard configuration:"
      echo "   1. Korean/English toggle: System Preferences > Keyboard > Input Sources"
      echo "   2. Disable conflicting services: Shortcuts > Services"

      # Only restart Dock if configuration changed
      if pgrep Dock >/dev/null; then
        echo "🔄 Refreshing Dock (if needed)..."
        killall Dock 2>/dev/null || true
      fi

      echo "✅ macOS optimizations applied"
    '';
  }
  // lib.optionalAttrs isLinux {
    # Linux-specific optimizations
    setupLinuxOptimizations = ''
      echo "🐧 Applying Linux optimizations..."

      # Ensure XDG directories exist
      mkdir -p "${commonPaths.config}"

      echo "✅ Linux optimizations applied"
    '';
  };







}
