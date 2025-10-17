# Cachix Binary Cache Configuration
#
# Configures Nix to use binary caches for faster package downloads.
# Binary caches provide pre-built packages, significantly reducing build times.
#
# Configured Caches:
#   - cache.nixos.org: Official NixOS binary cache
#   - nix-community.cachix.org: Community-maintained packages
#   - cuda-maintainers.cachix.org: CUDA and GPU-related packages
#   - devenv.cachix.org: devenv development environment packages
#   - pre-commit-hooks.cachix.org: pre-commit framework packages
#   - numtide.cachix.org: numtide tools and utilities
#   - ghostty.cachix.org: Ghostty terminal emulator
#   - tweag-jupyter.cachix.org: Jupyter notebook environments
#
# Benefits:
#   - Faster package installation (download vs compile)
#   - Reduced CPU and disk usage
#   - Consistent builds across systems
#
# Usage:
#   Import this module in darwin or nixos host configurations:
#   imports = [ ../../modules/shared/cachix ];

_:

{
  nix.settings = {
    # Binary cache substituters (in priority order)
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://devenv.cachix.org"
      "https://pre-commit-hooks.cachix.org"
      "https://numtide.cachix.org"
      "https://ghostty.cachix.org"
      "https://tweag-jupyter.cachix.org"
    ];

    # Trusted public keys for cache verification
    # These keys ensure downloaded binaries are authentic and untampered
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgKpvNhFE8gvXv6bZg6RzjWUYqZFFI="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy2Oa9+LG8+NJf2XRAYsGGHghiZZ0="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "tweag-jupyter.cachix.org-1:UtNH4Zs6hVUFpFBTLaA4ejYavPo5EFFqgd7G7FxGW9g="
    ];
  };
}
