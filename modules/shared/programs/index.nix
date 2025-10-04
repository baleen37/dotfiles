# Shared Program Configurations Entry Point
#
# Modular program configurations with flat structure and directories for complex programs.
# Following YAGNI principle - simple flat files, directories only when needed.
#
# ARCHITECTURE:
#   - Flat structure: Simple programs as individual files
#   - Directory modules: Complex programs (zsh, tmux) in their own directories
#   - Standardized interface: Consistent inputs/outputs across all modules
#
# PROGRAM MODULES:
#   - zsh/: Complete shell environment configuration
#   - tmux/: Terminal multiplexer with plugins
#   - git.nix: Version control with aliases
#   - vim.nix: Editor with plugins
#   - alacritty.nix: Terminal emulator
#   - ssh.nix: SSH client configuration
#   - direnv.nix: Environment management
#   - fzf.nix: Fuzzy finder
#
# VERSION: 3.1.0 (Flat structure with complex program directories)
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

  # Import complex program modules (directories)
  zshConfig = import ./zsh/default.nix moduleInputs;
  tmuxConfig = import ./tmux/default.nix moduleInputs;

  # Import simple program modules (flat files)
  gitConfig = import ./git.nix moduleInputs;
  vimConfig = import ./vim.nix moduleInputs;
  alacrittyConfig = import ./alacritty.nix moduleInputs;
  sshConfig = import ./ssh.nix moduleInputs;
  direnvConfig = import ./direnv.nix moduleInputs;
  fzfConfig = import ./fzf.nix moduleInputs;

in
{
  # Merge all program configurations using lib.mkMerge for clean combination
  programs = lib.mkMerge [
    # Complex programs with their own directories
    zshConfig.programs
    tmuxConfig.programs

    # Simple programs as flat files
    gitConfig.programs
    vimConfig.programs
    alacrittyConfig.programs
    sshConfig.programs
    direnvConfig.programs
    fzfConfig.programs
  ];
}
