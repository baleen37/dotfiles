# Centralized Nix Binary Cache Configuration
# Single source of truth for substituters and public keys
#
# Used by:
# - lib/mksystem.nix cacheSettings (system nix.settings)
# - flake.nix nixConfig duplicates these values (cannot import, must be top-level attrset)
#
# Performance-first order: project cache (highest hit rate) -> community -> official fallback

{
  substituters = [
    "https://baleen-nix.cachix.org"
    "https://nix-community.cachix.org"
    "https://cache.nixos.org/"
  ];
  trusted-public-keys = [
    "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
}
