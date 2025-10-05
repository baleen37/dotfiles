# Cachix Binary Cache Configuration
#
# Configures Nix to use binary caches for faster package downloads.
# Binary caches provide pre-built packages, significantly reducing build times.
#
# Configured Caches:
#   - cache.nixos.org: Official NixOS binary cache
#   - nix-community.cachix.org: Community-maintained packages
#
# Benefits:
#   - Faster package installation (download vs compile)
#   - Reduced CPU and disk usage
#   - Consistent builds across systems
#
# Usage:
#   Import this module in darwin or nixos host configurations:
#   imports = [ ../../modules/shared/cachix ];

{ pkgs, lib, ... }:

{
  nix.settings = {
    # Binary cache substituters (in priority order)
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    # Trusted public keys for cache verification
    # These keys ensure downloaded binaries are authentic and untampered
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
