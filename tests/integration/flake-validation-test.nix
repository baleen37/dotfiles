# Flake structure validation test
# Tests core flake.nix structure and essential outputs
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in

# Basic flake structure validation
testHelpers.mkTest "flake-validation" ''
  echo "Testing flake.nix structure..."

  # Test 1: flake.nix exists and is readable
  if [ -f "./flake.nix" ] && [ -r "./flake.nix" ]; then
    echo "✅ flake.nix exists and is readable"
  else
    echo "❌ flake.nix not found or not readable"
    exit 1
  fi

  # Test 2: Check for essential flake outputs structure
  if grep -q "outputs.*{.*}" ./flake.nix; then
    echo "✅ Flake outputs structure found"
  else
    echo "❌ Flake outputs structure not found"
    exit 1
  fi

  # Test 3: Check for nixosConfigurations
  if grep -q "nixosConfigurations" ./flake.nix; then
    echo "✅ nixosConfigurations found"
  else
    echo "⚠️  nixosConfigurations not found"
  fi

  # Test 4: Check for darwinConfigurations
  if grep -q "darwinConfigurations" ./flake.nix; then
    echo "✅ darwinConfigurations found"
  else
    echo "⚠️  darwinConfigurations not found"
  fi

  # Test 5: Check for homeManagerConfigurations
  if grep -q "homeManagerConfigurations" ./flake.nix; then
    echo "✅ homeManagerConfigurations found"
  else
    echo "⚠️  homeManagerConfigurations not found"
  fi

  # Test 6: Check for packages or apps
  if grep -q "packages\|apps" ./flake.nix; then
    echo "✅ packages or apps found"
  else
    echo "⚠️  packages or apps not found"
  fi

  # Test 7: Check for checks (test configurations)
  if grep -q "checks" ./flake.nix; then
    echo "✅ checks (test configurations) found"
  else
    echo "⚠️  checks not found"
  fi

  # Test 8: Validate basic Nix syntax
  if nix-instantiate --parse ./flake.nix >/dev/null 2>&1; then
    echo "✅ Flake Nix syntax is valid"
  else
    echo "❌ Flake Nix syntax is invalid"
    exit 1
  fi

  echo "✅ All flake validation tests passed"
''
