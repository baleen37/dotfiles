# Project Structure

This document explains the overall directory layout of the repository with brief code examples.

```text
.
├── apps/      # Platform-specific installable applications
├── hosts/     # Host configurations for nix-darwin or NixOS
├── modules/   # Reusable Nix modules
├── overlays/  # Custom package overlays
├── tests/     # Flake checks and unit tests
├── docs/      # Documentation files
├── flake.nix  # Entry point for the Nix flake
└── README.md
```

## Example: Importing a Module

```nix
# hosts/darwin/myhost/home.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/darwin/some-module
  ];
}
```

See `README.md` and other docs for usage details.
