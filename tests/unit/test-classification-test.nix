# tests/unit/test-classification-test.nix
# Test classification library for stable vs unstable tests
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import test classification library
  testLib = import ../lib/test-classification.nix { inherit lib; };

  # Mock test derivations
  stableTest = {
    buildInputs = [ pkgs.nix ];
    propagatedBuildInputs = [ ];
  };

  unstableTest = {
    buildInputs = [
      pkgs.curl
      pkgs.docker
    ];
    propagatedBuildInputs = [ pkgs.network-tools ];
  };

  # Test 1: Test isStableTest function with stable test
  testStableTest = testLib.isStableTest "unit-syntax-test.nix" stableTest;

  # Test 2: Test isStableTest function with unstable test
  testUnstableTest = !testLib.isStableTest "network-connection-test.nix" unstableTest;

  # Test 3: Test platform support
  testPlatformSupport = testLib.supportsStableTesting "aarch64-darwin";

  # Test 4: Test getStableTests function
  allTests = {
    "unit-syntax-test.nix" = stableTest;
    "network-connection-test.nix" = unstableTest;
    "integration-build-test.nix" = unstableTest;
  };
  filteredTests = testLib.getStableTests allTests;
  testFiltering = builtins.length (lib.attrNames filteredTests) == 1;

in
# Create derivation that tests test classification functions
pkgs.runCommand "test-classification-test-results" { } ''
  echo "Running test classification unit tests..."

  # Test 1: Stable test identification
  echo "Test 1: Stable test identification..."
  ${
    if testStableTest then
      ''echo "✅ PASS: Stable test correctly identified"''
    else
      ''echo "❌ FAIL: Stable test misclassified"; exit 1''
  }

  # Test 2: Unstable test identification
  echo "Test 2: Unstable test identification..."
  ${
    if testUnstableTest then
      ''echo "✅ PASS: Unstable test correctly identified"''
    else
      ''echo "❌ FAIL: Unstable test misclassified"; exit 1''
  }

  # Test 3: Platform support detection
  echo "Test 3: Platform support detection..."
  ${
    if testPlatformSupport then
      ''echo "✅ PASS: Platform support correctly identified"''
    else
      ''echo "❌ FAIL: Platform support incorrect"; exit 1''
  }

  # Test 4: Test filtering functionality
  echo "Test 4: Test filtering functionality..."
  ${
    if testFiltering then
      ''echo "✅ PASS: getStableTests correctly filtered tests"''
    else
      ''echo "❌ FAIL: getStableTests filtering failed"; exit 1''
  }

  echo "✅ All test classification tests passed!"
  echo "Test classification library verified - functions work correctly"
  touch $out
''
