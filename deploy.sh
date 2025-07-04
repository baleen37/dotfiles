#!/bin/sh -e

# Build and switch for any computer
# No complex dependencies needed

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Auto-detect system
if [ "$(uname)" = "Darwin" ]; then
    SYSTEM_TYPE="$(uname -m)-darwin"
    REBUILD_CMD="darwin-rebuild"
else
    SYSTEM_TYPE="$(uname -m)-linux"
    REBUILD_CMD="nixos-rebuild"
fi

# Set USER if not set
export USER="${USER:-$(whoami)}"

echo "${YELLOW}🔨 Building and switching for ${SYSTEM_TYPE}${NC}"

# Step 1: Build
echo "${YELLOW}▶ Building...${NC}"
nix --extra-experimental-features 'nix-command flakes' build --impure .#darwinConfigurations.${SYSTEM_TYPE}.system 2>/dev/null || \
nix --extra-experimental-features 'nix-command flakes' build --impure .#nixosConfigurations.${SYSTEM_TYPE}.config.system.build.toplevel 2>/dev/null || {
    echo "${RED}✗ Build failed${NC}"
    exit 1
}

# Step 2: Switch with sudo
echo "${YELLOW}▶ Switching (requesting sudo)...${NC}"
if [ "$(uname)" = "Darwin" ]; then
    sudo USER="$USER" ./result/sw/bin/darwin-rebuild switch --impure --flake .#${SYSTEM_TYPE}
else
    sudo nixos-rebuild switch --impure --flake .#${SYSTEM_TYPE}
fi

echo "${GREEN}✅ Done!${NC}"
