#!/usr/bin/env bash
set -euo pipefail

# Install Nix if not already installed
if ! command -v nix &> /dev/null; then
  echo "Nix is not installed. Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
else
  echo "Nix is already installed."
fi

nix --experimental-features 'nix-command flakes' build '.#darwinConfigurations.darwin.system'
./result/sw/bin/darwin-rebuild switch --flake '.#darwin'
