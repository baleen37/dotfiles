# Project Overview

This document provides additional context on the layout and purpose of the `dotfiles` repository.

## Directory Layout

- `apps/`: Nix definitions for installable applications per platform.
- `hosts/`: Host-specific configurations for nix-darwin or NixOS.
- `modules/`: Reusable Nix modules shared between platforms or system types.
- `overlays/`: Custom package overlays for nixpkgs.
- `tests/`: Flake checks and example unit tests.
- `docs/`: Extra documentation files like this one.

See `README.md` for general usage instructions.
