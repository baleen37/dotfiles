# Unified User Resolution System Test
# Tests the new consolidated user-resolution.nix system

{ pkgs, src ? ../.., ... }:

let
  # Import unified user resolution library
  getUserLib = import (src + "/lib/user-resolution.nix");

in
pkgs.runCommand "user-resolution-test"
{
  buildInputs = with pkgs; [ bash ];
  nativeBuildInputs = with pkgs; [ nix ];
} ''
  echo "🧪 Unified User Resolution Test Suite"
  echo "==================================="

  # Test 1: Basic String Mode (Default)
  echo ""
  echo "📋 Test 1: Basic String Mode"
  echo "---------------------------"

  # Test with USER set
  export USER="testuser"
  result=$(nix eval --impure --expr '(import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; }' --raw)
  if [[ "$result" == "testuser" ]]; then
    echo "✅ Basic string mode works correctly"
  else
    echo "❌ Failed basic string mode. Expected: testuser, Got: $result"
    exit 1
  fi

  # Test 2: Extended Mode
  echo ""
  echo "📋 Test 2: Extended Mode"
  echo "-----------------------"

  user_result=$(nix eval --impure --expr '((import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; returnFormat = "extended"; }).user' --raw)
  if [[ "$user_result" == "testuser" ]]; then
    echo "✅ Extended mode user field works correctly"
  else
    echo "❌ Failed extended mode. Expected: testuser, Got: $user_result"
    exit 1
  fi

  # Test 3: SUDO_USER Priority
  echo ""
  echo "📋 Test 3: SUDO_USER Priority"
  echo "----------------------------"

  sudo_result=$(nix eval --impure --expr '(import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "regularuser"; SUDO_USER = "sudouser"; }; }' --raw)
  if [[ "$sudo_result" == "sudouser" ]]; then
    echo "✅ SUDO_USER takes priority correctly"
  else
    echo "❌ SUDO_USER priority failed. Expected: sudouser, Got: $sudo_result"
    exit 1
  fi

  # Test 4: Disable SUDO_USER
  echo ""
  echo "📋 Test 4: Disable SUDO_USER"
  echo "---------------------------"

  no_sudo_result=$(nix eval --impure --expr '(import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "regularuser"; SUDO_USER = "sudouser"; }; allowSudoUser = false; }' --raw)
  if [[ "$no_sudo_result" == "regularuser" ]]; then
    echo "✅ SUDO_USER disabled correctly"
  else
    echo "❌ Failed to disable SUDO_USER. Expected: regularuser, Got: $no_sudo_result"
    exit 1
  fi

  # Test 5: Platform Detection (Extended Mode)
  echo ""
  echo "📋 Test 5: Platform Detection"
  echo "----------------------------"

  platform_result=$(nix eval --impure --expr '((import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; platform = "darwin"; returnFormat = "extended"; }).platform' --raw)
  if [[ "$platform_result" == "darwin" ]]; then
    echo "✅ Platform detection works correctly"
  else
    echo "❌ Platform detection failed. Expected: darwin, Got: $platform_result"
    exit 1
  fi

  # Test 6: Home Path Generation
  echo ""
  echo "📋 Test 6: Home Path Generation"
  echo "------------------------------"

  darwin_home=$(nix eval --impure --expr '((import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; platform = "darwin"; returnFormat = "extended"; }).homePath' --raw)
  if [[ "$darwin_home" == "/Users/testuser" ]]; then
    echo "✅ Darwin home path generation works"
  else
    echo "❌ Darwin home path failed. Expected: /Users/testuser, Got: $darwin_home"
    exit 1
  fi

  linux_home=$(nix eval --impure --expr '((import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; platform = "linux"; returnFormat = "extended"; }).homePath' --raw)
  if [[ "$linux_home" == "/home/testuser" ]]; then
    echo "✅ Linux home path generation works"
  else
    echo "❌ Linux home path failed. Expected: /home/testuser, Got: $linux_home"
    exit 1
  fi

  # Test 7: Utility Functions
  echo ""
  echo "📋 Test 7: Utility Functions"
  echo "---------------------------"

  config_path=$(nix eval --impure --expr '((import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; platform = "linux"; returnFormat = "extended"; }).utils.getConfigPath' --raw)
  if [[ "$config_path" == "/home/testuser/.config" ]]; then
    echo "✅ Config path utility works"
  else
    echo "❌ Config path utility failed. Expected: /home/testuser/.config, Got: $config_path"
    exit 1
  fi

  # Test 8: Return Type Validation
  echo ""
  echo "📋 Test 8: Return Type Validation"
  echo "--------------------------------"

  string_type=$(nix eval --impure --expr 'builtins.typeOf ((import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; })' --raw)
  if [[ "$string_type" == "string" ]]; then
    echo "✅ Default mode returns string type"
  else
    echo "❌ Wrong return type for string mode. Expected: string, Got: $string_type"
    exit 1
  fi

  extended_type=$(nix eval --impure --expr 'builtins.typeOf ((import ${src}/lib/user-resolution.nix) { mockEnv = { USER = "testuser"; }; returnFormat = "extended"; })' --raw)
  if [[ "$extended_type" == "set" ]]; then
    echo "✅ Extended mode returns set type"
  else
    echo "❌ Wrong return type for extended mode. Expected: set, Got: $extended_type"
    exit 1
  fi

  # Test 9: Custom Environment Variable
  echo ""
  echo "📋 Test 9: Custom Environment Variable"
  echo "------------------------------------"

  custom_result=$(nix eval --impure --expr '(import ${src}/lib/user-resolution.nix) { mockEnv = { CUSTOM_USER = "customuser"; }; envVar = "CUSTOM_USER"; allowSudoUser = false; }' --raw)
  if [[ "$custom_result" == "customuser" ]]; then
    echo "✅ Custom environment variable works"
  else
    echo "❌ Custom env var failed. Expected: customuser, Got: $custom_result"
    exit 1
  fi

  echo ""
  echo "🎉 All unified user resolution tests passed!"
  echo "=========================================="

  touch $out
''