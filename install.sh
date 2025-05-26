#!/usr/bin/env bash
set -euo pipefail

# Install Nix if not already installed
if ! command -v nix &> /dev/null; then
  echo "Nix is not installed. Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
else
  echo "Nix is already installed."
fi

# Prompt the user for the configuration to install
echo "Which configuration do you want to install? (baleen or jito):"
read TARGET_HOST

# Validate input (optional but recommended)
if [[ "$TARGET_HOST" != "baleen" && "$TARGET_HOST" != "jito" ]]; then
  echo "Invalid input. Please enter 'baleen' or 'jito'."
  exit 1
fi

echo "Selected configuration: $TARGET_HOST"

nix --experimental-features 'nix-command flakes' build ".#darwinConfigurations.$TARGET_HOST.system"
./result/sw/bin/darwin-rebuild switch --flake ".#$TARGET_HOST"
