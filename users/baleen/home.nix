# Home Manager entry point for baleen user
#
# This file configures the user environment with:
# - Common packages available across platforms
# - Import of all program-specific configurations
#
# Each program in programs/ directory manages its own configuration
# Following Mitchell-style flat structure for maintainability
#
# VERSION: 1.0.0 (Mitchell-style implementation)
# LAST UPDATED: 2025-10-25

{ pkgs, ... }:
{
  home.stateVersion = "24.05";

  # Common packages available across all platforms
  home.packages = with pkgs; [
    # Core development tools
    ripgrep # Fast text search
    fzf # Fuzzy finder
    fd # Fast file finder (find replacement)
    bat # Enhanced cat with syntax highlighting
    eza # Enhanced ls replacement
    tree # Directory tree visualization
    jq # JSON processor
    yq # YAML processor

    # Git tools
    git # Version control
    gh # GitHub CLI
    difftastic # Syntax-aware diffing

    # System utilities
    curl # HTTP client
    wget # File downloader
    htop # Process viewer
    btop # Enhanced process viewer

    # Development tools
    nodejs # Node.js runtime
    python3 # Python runtime

    # Nix tools
    nil # Nix language server
    nixfmt # Nix formatter
  ];

  # Import all program-specific configurations
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/vim.nix
    ./programs/claude.nix
  ];

  # Basic Home Manager settings
  home.username = "baleen";
  home.homeDirectory = "/Users/baleen";

  # Enable basic programs
  programs.home-manager.enable = true;

  # Set environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}
