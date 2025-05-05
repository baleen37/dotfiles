#!/usr/bin/env bash
set -euo pipefail

nix --experimental-features 'nix-command flakes' build '.#darwinConfigurations.darwin.system'
./result/sw/bin/darwin-rebuild switch --flake '.#darwin'
