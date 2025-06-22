# Test fixture: New configuration example
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    neovim  # Changed from vim to neovim
    curl
    wget
    jq      # Added new package
  ];

  system.stateVersion = "24.05";  # Updated version

  services.nix-daemon.enable = true;

  programs.zsh.enable = true;
  programs.bash.enable = true;  # Added bash
}
