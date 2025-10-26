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

{ pkgs, lib, ... }:
{
  home.stateVersion = "24.05";

  # Common packages available across all platforms
  # Curated selection from modules/shared/packages/ for essential development
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
    nodejs_22 # Node.js runtime (LTS)
    python3 # Python runtime
    uv # Fast Python package installer
    direnv # Environment variable management per directory
    pre-commit # Pre-commit hooks framework

    # Terminal tools
    tmux # Terminal multiplexer

    # Nix tools
    nil # Nix language server
    nixfmt # Nix formatter
    statix # Nix anti-pattern linter
    deadnix # Dead code detector for Nix

    # Build tools
    gnumake # GNU make build automation
    cmake # Cross-platform build system generator

    # Archive utilities
    zip # Archive creation
    unzip # Archive extraction

    # Cloud tools
    act # Run GitHub Actions locally
    docker # Container platform

    # Security tools
    yubikey-agent # YubiKey support
    keepassxc # Password manager

    # SSH tools
    autossh # Automatic SSH restart
    mosh # Mobile shell for unreliable networks

    # Database tools
    postgresql # Database client
    sqlite # Lightweight SQL database
    redis # Redis client

    # Media tools
    ffmpeg # Video/audio processing

    # Productivity
    bc # Command-line calculator

    # AI/CLI tools
    claude-code # AI code generation
    gemini-cli # Gemini CLI
  ];

  # Import all program-specific configurations
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/vim.nix
    # ./programs/claude.nix  # TODO: Fix claude-hook path references
    ./programs/tmux.nix
    ./programs/fzf.nix
    ./programs/alacritty.nix
    ./programs/direnv.nix
    ./programs/ssh.nix
    ./programs/qemu-vm.nix
  ];

  # Basic Home Manager settings
  home.username = "baleen";
  home.homeDirectory = lib.mkDefault "/Users/baleen";

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
