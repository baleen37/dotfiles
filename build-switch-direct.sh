#!/bin/bash
# Direct build-switch using existing result without re-building

set -e

echo "🔄 Using pre-built configuration from ./result"

# Check if result exists
if [ ! -d "./result" ]; then
    echo "❌ No pre-built result found. Run 'make build-current' first."
    exit 1
fi

# Check if darwin-rebuild exists in result
if [ ! -x "./result/sw/bin/darwin-rebuild" ]; then
    echo "❌ darwin-rebuild not found in result. Build may be incomplete."
    exit 1
fi

echo "✅ Pre-built configuration found"
echo "🔧 Attempting to activate user-level configurations..."

# Try to activate user configurations directly
if [ -x "./result/activate-user" ]; then
    echo "⚠️  Using deprecated activate-user (will show warning)"
    ./result/activate-user
else
    echo "🔧 Using result/activate directly (user-level only)"
    # Use user activation parts only
    if [ -x "./result/user/bin/home-manager" ]; then
        ./result/user/bin/home-manager switch --flake .
    else
        echo "⚠️  Home Manager not available in result"
    fi
fi

echo "✅ User-level configuration activated"
echo ""
echo "ℹ️  For system-level activation (requires sudo):"
echo "   sudo ./result/sw/bin/darwin-rebuild activate"
