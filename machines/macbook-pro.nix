# machines/macbook-pro.nix
{ pkgs, ... }:

{
  # Minimal system-level settings
  environment.systemPackages = with pkgs; [
    home-manager
  ];

  # Enable essential programs
  programs = {
    zsh.enable = true;
  };

  # System state version
  system.stateVersion = 5;

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
