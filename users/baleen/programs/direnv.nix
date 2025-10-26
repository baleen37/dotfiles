# Direnv environment management configuration
#
# Automatic environment variable loading per directory and Nix shell integration
#
# Features:
#   - Zsh integration: Auto-execute .envrc on directory entry
#   - nix-direnv: Nix shell environment caching for performance
#   - Auto .env file loading: load_dotenv enabled
#
# Usage examples:
#   Create .envrc in project directory:
#     use nix           # Use flake.nix or shell.nix
#     dotenv .env       # Load .env file
#
# VERSION: 4.0.0 (Mitchell-style migration)
# LAST UPDATED: 2025-10-25

{ ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config = {
      global = {
        load_dotenv = true;
      };
    };
  };
}
