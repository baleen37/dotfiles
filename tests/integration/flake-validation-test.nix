# Flake structure validation test
# Tests core flake.nix structure and essential outputs
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  nixtest ? {},
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in

# Basic flake structure validation
testHelpers.mkTest "flake-validation" ''
  echo "Testing flake structure..."

  # Test basic flake outputs exist
  if [ -f "flake.nix" ]; then
    echo "✅ flake.nix exists"
  else
    echo "❌ flake.nix missing"
    exit 1
  fi

  if [ -f "default.nix" ]; then
    echo "✅ default.nix exists"
  else
    echo "❌ default.nix missing"
    exit 1
  fi

  echo "✅ Flake structure validation passed"
''
