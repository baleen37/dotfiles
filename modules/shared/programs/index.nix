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
  # Import centralized user information
  userInfo = import ../../../lib/user-info.nix;

  # User configuration constants
  name = userInfo.name;
  email = userInfo.email;

  # Simple platform detection - direct system checking
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Standardized module interface data
  homePath = config.home.homeDirectory;
  moduleInputs = {
    inherit config pkgs lib;
    platformInfo = {
      inherit isDarwin isLinux;
      system = pkgs.system;
    };
    userInfo = {
      inherit name email homePath;
      # Legacy compatibility
      paths = {
        home = homePath;
        config = "${homePath}/.config";
        ssh = "${homePath}/.ssh";
      };
    };
  };

  # Import complex program modules (directories)
  zshConfig = import ./zsh/default.nix moduleInputs;
  tmuxConfig = import ./tmux/default.nix moduleInputs;
  claudeConfig = import ./claude/default.nix moduleInputs;

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
    (claudeConfig.programs or { })

    # Simple programs as flat files
    gitConfig.programs
    vimConfig.programs
    alacrittyConfig.programs
    sshConfig.programs
    direnvConfig.programs
    fzfConfig.programs
  ];

  # Additional home configurations from complex modules
  home = lib.mkMerge [
    (claudeConfig.home or { })
  ];
}
