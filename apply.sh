#!/bin/sh -e

# Simple apply script for built configuration
# Usage: ./apply.sh

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SYSTEM_TYPE="aarch64-darwin"

# Check if build result exists
if [ ! -L "./result" ]; then
    echo "${RED}✗ No build found. Run 'make build' first.${NC}"
    exit 1
fi

echo "${YELLOW}▶ Applying system configuration...${NC}"
echo "${YELLOW}  This will request sudo permission${NC}"

# Simple sudo with proper environment
sudo USER="$USER" ./result/sw/bin/darwin-rebuild switch --impure --flake .#${SYSTEM_TYPE}

echo "${GREEN}✓ System configuration applied successfully!${NC}"