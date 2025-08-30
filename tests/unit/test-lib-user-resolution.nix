# Comprehensive Unit Tests for lib/user-resolution.nix
# Tests all functionality including validation, platform detection, fallbacks, and error handling

{ pkgs, lib, ... }:

let
  userResolution = import ../../lib/user-resolution.nix;

  # Test helper to run tests with proper error handling
  runTest = name: testScript:
    pkgs.runCommand "test-${name}" { } (''
      echo "🧪 Running test: ${name}"

    '' + testScript + ''

      touch $out
    '');

  # Test cases as separate derivations for parallel execution
  testValidUserResolution = runTest "valid-user-resolution" ''
    # Test 1: Valid USER environment variable
    result=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "testuser"; };
      };
      in userRes
    ' | tr -d '"')

    if [ "$result" = "testuser" ]; then
      echo "✓ Valid USER environment variable resolved correctly"
    else
      echo "✗ Expected 'testuser', got '$result'"
      exit 1
    fi
  '';

  testSudoUserPriority = runTest "sudo-user-priority" ''
    # Test 2: SUDO_USER takes priority over USER
    result=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = {
          USER = "root";
          SUDO_USER = "realuser";
        };
        allowSudoUser = true;
      };
      in userRes
    ' | tr -d '"')

    if [ "$result" = "realuser" ]; then
      echo "✓ SUDO_USER takes priority over USER"
      true
    else
      echo "✗ Expected 'realuser', got '$result'"
      false
    fi
  '';

  testUserValidation = runTest "user-validation" ''
    # Test 3: Invalid usernames are rejected
    # Test empty string
    if nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = ""; };
        default = "fallback";
      };
      in userRes
    ' 2>/dev/null | grep -q "fallback"; then
      echo "✓ Empty username properly falls back to default"
    else
      echo "✗ Empty username should fall back to default"
      return 1
    fi

    # Test invalid characters
    if nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "user@invalid"; };
        default = "fallback";
      };
      in userRes
    ' 2>/dev/null | grep -q "fallback"; then
      echo "✓ Invalid username characters properly fall back to default"
      true
    else
      echo "✗ Invalid username should fall back to default"
      false
    fi
  '';

  testPlatformDetection = runTest "platform-detection" ''
    # Test 4: Platform detection works correctly
    darwinResult=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "testuser"; };
        returnFormat = "extended";
        platform = "darwin";
      };
      in userRes.platform
    ' | tr -d '"')

    if [ "$darwinResult" = "darwin" ]; then
      echo "✓ Darwin platform detected correctly"
    else
      echo "✗ Expected 'darwin', got '$darwinResult'"
      return 1
    fi

    linuxResult=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "testuser"; };
        returnFormat = "extended";
        platform = "linux";
      };
      in userRes.platform
    ' | tr -d '"')

    if [ "$linuxResult" = "linux" ]; then
      echo "✓ Linux platform detected correctly"
      true
    else
      echo "✗ Expected 'linux', got '$linuxResult'"
      false
    fi
  '';

  testExtendedFormat = runTest "extended-format" ''
    # Test 5: Extended return format provides all expected fields
    nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "testuser"; };
        returnFormat = "extended";
        platform = "darwin";
      };
      in {
        hasUser = userRes ? user;
        hasHomePath = userRes ? homePath;
        hasPlatform = userRes ? platform;
        hasUserConfig = userRes ? userConfig;
        hasUtils = userRes ? utils;
      }
    ' > /tmp/extended_test.json

    if jq -r '.hasUser' /tmp/extended_test.json | grep -q "true" &&
       jq -r '.hasHomePath' /tmp/extended_test.json | grep -q "true" &&
       jq -r '.hasPlatform' /tmp/extended_test.json | grep -q "true" &&
       jq -r '.hasUserConfig' /tmp/extended_test.json | grep -q "true" &&
       jq -r '.hasUtils' /tmp/extended_test.json | grep -q "true"; then
      echo "✓ Extended format contains all expected fields"
      true
    else
      echo "✗ Extended format missing required fields"
      cat /tmp/extended_test.json
      false
    fi
  '';

  testHomePathGeneration = runTest "home-path-generation" ''
    # Test 6: Home path generation for different platforms
    darwinHome=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "testuser"; };
        returnFormat = "extended";
        platform = "darwin";
      };
      in userRes.homePath
    ' | tr -d '"')

    if [ "$darwinHome" = "/Users/testuser" ]; then
      echo "✓ Darwin home path generated correctly"
    else
      echo "✗ Expected '/Users/testuser', got '$darwinHome'"
      return 1
    fi

    linuxHome=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "testuser"; };
        returnFormat = "extended";
        platform = "linux";
      };
      in userRes.homePath
    ' | tr -d '"')

    if [ "$linuxHome" = "/home/testuser" ]; then
      echo "✓ Linux home path generated correctly"
      true
    else
      echo "✗ Expected '/home/testuser', got '$linuxHome'"
      false
    fi
  '';

  testCIEnvironmentFallback = runTest "ci-environment-fallback" ''
    # Test 7: CI environment fallback when USER is empty
    result=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = {
          USER = "";
          CI = "true";
        };
        enableAutoDetect = true;
      };
      in userRes
    ' | tr -d '"')

    if [ "$result" = "runner" ]; then
      echo "✓ CI environment fallback works correctly"
      true
    else
      echo "✗ Expected 'runner', got '$result'"
      false
    fi
  '';

  testAutoDetectionDisabled = runTest "auto-detection-disabled" ''
    # Test 8: Auto-detection can be disabled
    if nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = {
          USER = "";
          CI = "true";
        };
        enableAutoDetect = false;
        default = "manual";
      };
      in userRes
    ' 2>/dev/null | grep -q "manual"; then
      echo "✓ Auto-detection properly disabled, fallback to default"
      true
    else
      echo "✗ Auto-detection should be disabled and use default"
      false
    fi
  '';

  testUtilityFunctions = runTest "utility-functions" ''
    # Test 9: Utility functions work correctly
    nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = "testuser"; };
        returnFormat = "extended";
        platform = "darwin";
      };
      in {
        configPath = userRes.utils.getConfigPath;
        sshPath = userRes.utils.getSshPath;
        isDarwin = userRes.utils.isDarwin;
        isLinux = userRes.utils.isLinux;
      }
    ' > /tmp/utils_test.json

    configPath=$(jq -r '.configPath' /tmp/utils_test.json)
    sshPath=$(jq -r '.sshPath' /tmp/utils_test.json)
    isDarwin=$(jq -r '.isDarwin' /tmp/utils_test.json)
    isLinux=$(jq -r '.isLinux' /tmp/utils_test.json)

    if [ "$configPath" = "/Users/testuser/.config" ] &&
       [ "$sshPath" = "/Users/testuser/.ssh" ] &&
       [ "$isDarwin" = "true" ] &&
       [ "$isLinux" = "false" ]; then
      echo "✓ All utility functions work correctly"
      true
    else
      echo "✗ Utility functions failed:"
      echo "  configPath: $configPath (expected /Users/testuser/.config)"
      echo "  sshPath: $sshPath (expected /Users/testuser/.ssh)"
      echo "  isDarwin: $isDarwin (expected true)"
      echo "  isLinux: $isLinux (expected false)"
      false
    fi
  '';

  testErrorHandling = runTest "error-handling" ''
    # Test 10: Proper error messages with helpful context
    errorOutput=$(nix eval --impure --expr '
      let userRes = import ${../../lib/user-resolution.nix} {
        mockEnv = { USER = ""; };
        enableAutoDetect = false;
      };
      in userRes
    ' 2>&1 || true)

    if echo "$errorOutput" | grep -q "Failed to detect valid user" &&
       echo "$errorOutput" | grep -q "export USER" &&
       echo "$errorOutput" | grep -q "Debug info"; then
      echo "✓ Error handling provides helpful context and solutions"
      true
    else
      echo "✗ Error message should contain helpful debugging information"
      echo "Actual error output: $errorOutput"
      false
    fi
  '';

  # Main test suite that runs all tests
  allTests = pkgs.runCommand "lib-user-resolution-tests"
    {
      buildInputs = with pkgs; [ jq nix ];
    } ''
    echo "🚀 Running comprehensive lib/user-resolution.nix test suite..."
    echo "================================================================="

    # Run all tests
    ${testValidUserResolution}/bin/*
    ${testSudoUserPriority}/bin/*
    ${testUserValidation}/bin/*
    ${testPlatformDetection}/bin/*
    ${testExtendedFormat}/bin/*
    ${testHomePathGeneration}/bin/*
    ${testCIEnvironmentFallback}/bin/*
    ${testAutoDetectionDisabled}/bin/*
    ${testUtilityFunctions}/bin/*
    ${testErrorHandling}/bin/*

    echo "================================================================="
    echo "🎉 All lib/user-resolution.nix tests completed successfully!"
    echo "✅ Total: 10 test cases passed"
    echo ""
    echo "Test Coverage:"
    echo "- Basic user resolution ✅"
    echo "- SUDO_USER priority ✅"
    echo "- Input validation ✅"
    echo "- Platform detection ✅"
    echo "- Extended format ✅"
    echo "- Home path generation ✅"
    echo "- CI environment fallback ✅"
    echo "- Configuration options ✅"
    echo "- Utility functions ✅"
    echo "- Error handling ✅"

    touch $out
  '';

in
# Return the main test suite
allTests
