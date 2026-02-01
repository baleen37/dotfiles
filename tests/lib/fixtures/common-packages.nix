# Common package sets for testing to eliminate duplication

{ pkgs }:
{
  # Minimal set for basic system tests
  basicPackages = with pkgs; [
    git
    vim
  ];

  # Basic + common tools
  corePackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # Core + development tools
  devPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    jq
  ];

  # Full-featured set for integration tests
  fullPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    jq
    tree
    ripgrep
    bat
  ];

  # E2E test basic set (most common pattern in E2E tests)
  e2eBasicPackages = with pkgs; [
    git
    curl
    jq
    nix
    gnumake
  ];

  # E2E test with vim
  e2eWithVim = with pkgs; [
    git
    vim
    curl
    jq
    nix
  ];

  # Comprehensive development environment
  comprehensivePackages = with pkgs; [
    # Core development tools
    git
    vim
    zsh
    tmux
    curl
    jq
    nix
    gnumake

    # Additional development tools
    nodejs
    python3
    docker
    docker-compose
    gh

    # Build and testing tools
    gcc
    gnumake
    cmake
    findutils
    gnugrep
    gnused

    # Network and debugging tools
    netcat
    htop
    tree
    bat
    ripgrep
  ];
}
