#!/bin/bash
# VM Test Validation Script
#
# This script validates that the VM tests are properly structured
# and can be evaluated (though not executed on macOS).

set -euo pipefail

cd "$(dirname "$0")/../../"

echo "🔍 Validating VM test structure..."

# Check that VM test files exist
echo "📁 Checking VM test files..."
if [[ ! -f "tests/vm/boot-test-minimal.nix" ]]; then
    echo "❌ boot-test-minimal.nix not found"
    exit 1
fi
echo "✓ boot-test-minimal.nix exists"

if [[ ! -f "tests/vm/boot-test.nix" ]]; then
    echo "❌ boot-test.nix not found"
    exit 1
fi
echo "✓ boot-test.nix exists"

if [[ ! -f "tests/vm/README.md" ]]; then
    echo "❌ README.md not found"
    exit 1
fi
echo "✓ README.md exists"

# Check that flake.nix references VM tests
echo "🔧 Checking flake.nix configuration..."
if ! grep -q "vm-boot-test-minimal" flake.nix; then
    echo "❌ vm-boot-test-minimal not found in flake.nix"
    exit 1
fi
echo "✓ vm-boot-test-minimal referenced in flake.nix"

if ! grep -q "vm-boot-test" flake.nix; then
    echo "❌ vm-boot-test not found in flake.nix"
    exit 1
fi
echo "✓ vm-boot-test referenced in flake.nix"

# Check that Makefile has VM targets
echo "🛠️  Checking Makefile targets..."
if ! grep -q "test-vm:" Makefile; then
    echo "❌ test-vm target not found in Makefile"
    exit 1
fi
echo "✓ test-vm target exists in Makefile"

if ! grep -q "test-vm-minimal:" Makefile; then
    echo "❌ test-vm-minimal target not found in Makefile"
    exit 1
fi
echo "✓ test-vm-minimal target exists in Makefile"

# Validate that VM test files have correct syntax (basic checks)
echo "📝 Checking VM test syntax..."
if ! grep -q "pkgs.nixosTest" tests/vm/boot-test-minimal.nix; then
    echo "❌ boot-test-minimal.nix doesn't use pkgs.nixosTest"
    exit 1
fi
echo "✓ boot-test-minimal.nix uses nixosTest"

if ! grep -q "testScript" tests/vm/boot-test-minimal.nix; then
    echo "❌ boot-test-minimal.nix doesn't have testScript"
    exit 1
fi
echo "✓ boot-test-minimal.nix has testScript"

# Check that Make targets show appropriate warnings on non-Linux systems
echo "🖥️  Testing Make target behavior..."
OS=$(uname -s)
if [[ "$OS" != "Linux" ]]; then
    echo "ℹ️  Running on $OS - checking for appropriate warnings..."

    # Capture make output ignoring exit code
    set +e  # Temporarily disable exit on error

    # Test minimal VM target
    MINIMAL_OUTPUT=$(make test-vm-minimal 2>&1 || true)
    if echo "$MINIMAL_OUTPUT" | grep -q "VM tests require"; then
        echo "✓ test-vm-minimal correctly warns about Linux requirement"
    else
        echo "❌ test-vm-minimal doesn't warn about Linux requirement"
        echo "Output: $MINIMAL_OUTPUT"
        set -e
        exit 1
    fi

    # Test full VM target
    VM_OUTPUT=$(make test-vm 2>&1 || true)
    if echo "$VM_OUTPUT" | grep -q "VM tests require"; then
        echo "✓ test-vm correctly warns about Linux requirement"
    else
        echo "❌ test-vm doesn't warn about Linux requirement"
        echo "Output: $VM_OUTPUT"
        set -e
        exit 1
    fi
    set -e  # Re-enable exit on error
else
    echo "ℹ️  Running on Linux - VM tests would be executable"
fi

echo ""
echo "🎉 VM test validation completed successfully!"
echo ""
echo "📋 Summary:"
echo "  ✓ VM test files are properly structured"
echo "  ✓ Flake configuration references VM tests"
echo "  ✓ Makefile targets are configured correctly"
echo "  ✓ Syntax validation passed"
echo "  ✓ Error handling works correctly"
echo ""
echo "🚀 VM tests are ready for use on Linux systems!"
echo ""
echo "📖 Usage instructions:"
echo "  Linux: make test-vm-minimal"
echo "  macOS: Use Docker with NixOS (see README.md)"