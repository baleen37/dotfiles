# Test User Fixture
#
# Reusable test user configuration for E2E testing
#
# Provides:
# - Test user with sudo access
# - Zsh shell (common in E2E tests)
# - Basic development tools
# - Home Manager integration ready
#
# Usage:
#   imports = [ ../lib/fixtures/test-user.nix ]

{ pkgs, lib, ... }:
{
  users.users.testuser = {
    isNormalUser = true;
    password = "test";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  # Enable zsh for test user
  programs.zsh.enable = true;

  # Development packages with zsh support
  environment.systemPackages = with pkgs; [
    git
    vim
    zsh
    tmux
    curl
    jq
    nix
    gnumake
    fzf
    fd
    bat
    tree
    ripgrep
  ];
}
