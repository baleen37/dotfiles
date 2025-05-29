#!/usr/bin/env bash
set -euo pipefail

# Ask for sudo password upfront
sudo -v
# Keep-alive: update existing sudo time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

# Install Nix if not already installed
if ! command -v nix &> /dev/null; then
  echo "Nix is not installed. Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
else
  echo "Nix is already installed."
fi

# Check for host argument
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <baleen|jito>"
  exit 1
fi
TARGET_HOST="$1"

# Validate input
if [[ "$TARGET_HOST" != "baleen" && "$TARGET_HOST" != "jito" ]]; then
  echo "Invalid input. Please enter 'baleen' or 'jito'."
  exit 1
fi

echo "Selected configuration: $TARGET_HOST"

nix --experimental-features 'nix-command flakes' build ".#darwinConfigurations.$TARGET_HOST.system"
sudo ./result/sw/bin/darwin-rebuild switch --flake ".#$TARGET_HOST"

# Kill the sudo keep-alive background process
kill $SUDO_KEEPALIVE_PID
