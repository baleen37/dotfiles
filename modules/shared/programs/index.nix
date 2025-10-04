# Shared Program Configurations Entry Point
#
# Modular program configurations following dustinlyons pattern with single responsibility.
# This index file provides standardized interface for all program modules.
#
# ARCHITECTURE:
#   - Modular structure: Each program category in separate file
#   - Standardized interface: Consistent inputs/outputs across modules
#   - Single responsibility: Each module handles specific program set
#   - Cross-platform: Shared programs with platform-aware optimizations
#
# MODULES:
#   - shell.nix: zsh configuration and shell environment
#   - development.nix: git, vim, ssh development tools
#   - terminal.nix: alacritty, tmux terminal applications
#   - productivity.nix: direnv, fzf productivity enhancements
#
# USAGE:
#   Imported by modules/shared/home-manager.nix
#
# VERSION: 3.0.0 (Modular refactoring)
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
  platformDetection = import ../../../lib/platform-detection.nix { inherit pkgs; };

  # Enhanced user resolution with platform awareness
  getUserInfo = import ../../../lib/user-resolution.nix {
    platform = platformDetection.platform;
    returnFormat = "extended";
  };

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

  # Standardized module interface data
  moduleInputs = {
    inherit config pkgs lib;
    platformInfo = {
      inherit isDarwin isLinux;
      inherit (platformFlags) isX86_64 isAarch64;
      system = pkgs.system;
    };
    userInfo = {
      inherit name email;
      inherit (getUserInfo) homePath;
      paths = commonPaths;
    };
  };

  # Import all program modules with standardized interface
  shellConfig = import ./shell.nix moduleInputs;
  developmentConfig = import ./development.nix moduleInputs;
  terminalConfig = import ./terminal.nix moduleInputs;
  productivityConfig = import ./productivity.nix moduleInputs;

in
{
  # Merge all program configurations using lib.mkMerge for clean combination
  programs = lib.mkMerge [
    shellConfig.programs
    developmentConfig.programs
    terminalConfig.programs
    productivityConfig.programs
  ];
}
