#!/usr/bin/env bash

set -euo pipefail

export USER=nixos

echo "🧪 Testing WSL Integration..."

# Test 1: Flake evaluation
echo "Test 1: Flake evaluation"
nix flake check --impure

# Test 2: WSL configuration builds
echo "Test 2: WSL system configuration"
nix build .#nixosConfigurations.wsl.config.system.build.toplevel --impure

# Test 3: Home Manager configuration
echo "Test 3: Home Manager configuration"
nix eval .#homeConfigurations.nixos.activationPackage --impure

# Test 4: Configuration application test
echo "Test 4: Configuration application test"
export USER=nixos
export NIXNAME=wsl
make -n switch | grep -q "nixos-rebuild"

echo "✅ All WSL integration tests passed!"