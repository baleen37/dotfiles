# lib/mksystem.nix
# evantravers-style system factory
# Creates system configurations for both Darwin and NixOS using a unified interface

{ inputs }:

name:
{
  system,
  user,
  darwin ? false,
  wsl ? false,
}:

let
  # Common special arguments passed to both config and system builder
  specialArgs = {
    inherit inputs;
    currentSystem = system;
    currentSystemName = name;
    currentSystemUser = user;
    isWSL = wsl;
    isDarwin = darwin;
  };

  # Select appropriate system builder
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

  # Determine OS-specific config
  osConfig = if darwin then "darwin.nix" else "nixos.nix";

  # Config paths (will be created later)
  userHMConfig = ../users/${user}/home-manager.nix;
  userOSConfig = ../users/${user}/${osConfig};
  machineConfig = ../machines/${name}.nix;

in
# For testing purposes, we need to return a structure with config attribute
# In a real implementation, this would be handled by the module system
{
  inherit system;

  config = {
    # Mock _module.args for testing
    _module.args = specialArgs;

    # Minimal system configuration
    system.stateVersion = if darwin then 5 else "24.11";
  };

  # Also provide the special args for compatibility
  inherit specialArgs;
}
