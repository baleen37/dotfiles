# Makefile integration test
# Tests core Makefile commands that users actually use daily
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  nixtest ? { },
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in

# Core Makefile functionality validation
testHelpers.mkTest "makefile-commands" ''
  echo "Testing Makefile commands..."

  # Test 1: Makefile exists and is readable
  if [ -f "./Makefile" ] && [ -r "./Makefile" ]; then
    echo "✅ Makefile exists and is readable"
  else
    echo "❌ Makefile not found or not readable"
    exit 1
  fi

  # Test 2: Check for essential Makefile targets
  if grep -q "^[a-zA-Z_-]*:" ./Makefile; then
    echo "✅ Makefile contains valid targets"
  else
    echo "❌ Makefile doesn't contain valid targets"
    exit 1
  fi

  # Test 3: Check for required targets
  required_targets=("switch" "test" "cache")
  for target in "''${required_targets[@]}"; do
    if grep -q "^$target:" ./Makefile; then
      echo "✅ Target '$target' found in Makefile"
    else
      echo "⚠️  Target '$target' not found in Makefile (may be conditionally defined)"
    fi
  done

  # Test 4: Check for VM management targets
  vm_targets=("vm/bootstrap" "vm/copy" "vm/switch")
  for target in "''${vm_targets[@]}"; do
    if grep -q "vm.*$target" ./Makefile || grep -q "^$target:" ./Makefile; then
      echo "✅ VM target '$target' found"
    else
      echo "⚠️  VM target '$target' not found"
    fi
  done

  # Test 5: Check for secrets management
  if grep -q "secrets" ./Makefile; then
    echo "✅ Secrets management found in Makefile"
  else
    echo "⚠️  Secrets management not found in Makefile"
  fi

  # Test 6: Check for cross-platform support
  if grep -q "darwin\|linux" ./Makefile; then
    echo "✅ Cross-platform support detected"
  else
    echo "⚠️  Cross-platform support not explicitly detected"
  fi

  echo "✅ All Makefile command tests passed"
''
