# ABOUTME: Development shell environment for dotfiles repository
# ABOUTME: Provides linting tools for pre-commit hooks (shellcheck, yamllint, markdownlint-cli)

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "dotfiles-dev";
  
  buildInputs = with pkgs; [
    # Pre-commit and linting tools
    pre-commit
    shellcheck      # Shell script analysis
    yamllint        # YAML file validation  
    markdownlint-cli # Markdown linting
    
    # General development tools
    git
    gnumake
    
    # For debugging and development
    nix
    nixpkgs-fmt
  ];

  shellHook = ''
    echo "🔧 Dotfiles development environment loaded"
    echo "Available linting tools:"
    echo "  - shellcheck (Shell script analysis)"
    echo "  - yamllint (YAML validation)"
    echo "  - markdownlint-cli (Markdown linting)"
    echo "  - pre-commit (Git hooks)"
    echo ""
    echo "Run 'pre-commit install' to setup git hooks"
    echo "Run 'make lint' to run all pre-commit checks"
  '';
}