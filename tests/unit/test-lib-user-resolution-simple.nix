# Simple Unit Test for lib/user-resolution.nix
# Focused on core functionality with straightforward bash scripts

{ pkgs, lib, ... }:

pkgs.runCommand "lib-user-resolution-test"
{
  buildInputs = with pkgs; [ nix ];
} ''
  echo "🚀 Testing lib/user-resolution.nix"
  echo "=================================="

  # Test 1: Basic user resolution with mock environment
  echo "Test 1: Basic user resolution..."
  result=$(nix eval --impure --expr '
    let userRes = import ${../../lib/user-resolution.nix} {
      mockEnv = { USER = "testuser"; };
    };
    in userRes
  ' | tr -d '"' || echo "error")

  if [ "$result" = "testuser" ]; then
    echo "✓ Basic user resolution: PASSED"
  else
    echo "✗ Basic user resolution: FAILED (got: $result)"
    exit 1
  fi

  # Test 2: Extended format with platform detection
  echo "Test 2: Extended format..."
  platform=$(nix eval --impure --expr '
    let userRes = import ${../../lib/user-resolution.nix} {
      mockEnv = { USER = "testuser"; };
      returnFormat = "extended";
      platform = "darwin";
    };
    in userRes.platform
  ' | tr -d '"' || echo "error")

  if [ "$platform" = "darwin" ]; then
    echo "✓ Extended format: PASSED"
  else
    echo "✗ Extended format: FAILED (got: $platform)"
    exit 1
  fi

  # Test 3: SUDO_USER priority
  echo "Test 3: SUDO_USER priority..."
  result=$(nix eval --impure --expr '
    let userRes = import ${../../lib/user-resolution.nix} {
      mockEnv = {
        USER = "root";
        SUDO_USER = "realuser";
      };
      allowSudoUser = true;
    };
    in userRes
  ' | tr -d '"' || echo "error")

  if [ "$result" = "realuser" ]; then
    echo "✓ SUDO_USER priority: PASSED"
  else
    echo "✗ SUDO_USER priority: FAILED (got: $result)"
    exit 1
  fi

  # Test 4: CI environment fallback
  echo "Test 4: CI environment fallback..."
  result=$(nix eval --impure --expr '
    let userRes = import ${../../lib/user-resolution.nix} {
      mockEnv = {
        USER = "";
        CI = "true";
      };
      enableAutoDetect = true;
    };
    in userRes
  ' | tr -d '"' || echo "error")

  if [ "$result" = "runner" ] || [ "$result" = "auto-detected-user" ]; then
    echo "✓ CI environment fallback: PASSED (got: $result)"
  else
    echo "✗ CI environment fallback: FAILED (got: $result)"
    exit 1
  fi

  # Test 5: Home path generation
  echo "Test 5: Home path generation..."
  homePath=$(nix eval --impure --expr '
    let userRes = import ${../../lib/user-resolution.nix} {
      mockEnv = { USER = "testuser"; };
      returnFormat = "extended";
      platform = "darwin";
    };
    in userRes.homePath
  ' | tr -d '"' || echo "error")

  if [ "$homePath" = "/Users/testuser" ]; then
    echo "✓ Home path generation: PASSED"
  else
    echo "✗ Home path generation: FAILED (got: $homePath)"
    exit 1
  fi

  echo "=================================="
  echo "🎉 All lib/user-resolution.nix tests completed!"
  echo "✅ Total: 5 test cases passed"
  echo ""
  echo "Test Coverage:"
  echo "- Basic user resolution ✅"
  echo "- Extended format with platform detection ✅"
  echo "- SUDO_USER priority handling ✅"
  echo "- CI environment fallback ✅"
  echo "- Home path generation ✅"

  touch $out
''
