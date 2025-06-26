# Unit tests for lib/platform-utils.nix
# Tests platform-specific utility functions

{ pkgs ? import <nixpkgs> {}, flake ? null, src ? ../.. }:

let
  # Import the module we're testing (will fail initially - TDD Red phase)
  platformUtils = import ../../lib/platform-utils.nix { inherit pkgs; };

  # Pre-computed test values
  darwinDefaults = platformUtils.getPlatformDefaults "darwin";
  linuxDefaults = platformUtils.getPlatformDefaults "linux";
  darwinFlags = platformUtils.getBuildFlags "aarch64-darwin";
  maxJobs = platformUtils.getMaxJobs "x86_64-linux";
  darwinPaths = platformUtils.getSystemPaths "darwin";
  darwinPkgMgr = platformUtils.getPackageManagerCommand "darwin";
  linuxPkgMgr = platformUtils.getPackageManagerCommand "linux";

in
pkgs.runCommand "platform-utils-unit-tests" { } ''
  # Test 1: Architecture utilities
  echo "Testing architecture utilities..."

  # Test getArchFromSystem function
  ${if platformUtils.getArchFromSystem "x86_64-darwin" == "x86_64" then "echo 'PASS: getArchFromSystem extracts x86_64'" else "exit 1"}
  ${if platformUtils.getArchFromSystem "aarch64-linux" == "aarch64" then "echo 'PASS: getArchFromSystem extracts aarch64'" else "exit 1"}

  # Test getPlatformFromSystem function
  ${if platformUtils.getPlatformFromSystem "x86_64-darwin" == "darwin" then "echo 'PASS: getPlatformFromSystem extracts darwin'" else "exit 1"}
  ${if platformUtils.getPlatformFromSystem "aarch64-linux" == "linux" then "echo 'PASS: getPlatformFromSystem extracts linux'" else "exit 1"}

  # Test 2: System compatibility utilities
  echo "Testing system compatibility utilities..."

  # Test isCompatibleSystem function
  ${if platformUtils.isCompatibleSystem "x86_64-darwin" "x86_64-darwin" then "echo 'PASS: isCompatibleSystem same system'" else "exit 1"}
  ${if !platformUtils.isCompatibleSystem "x86_64-darwin" "aarch64-linux" then "echo 'PASS: isCompatibleSystem different systems'" else "exit 1"}

  # Test canCrossCompile function
  ${if platformUtils.canCrossCompile "x86_64-linux" "aarch64-linux" then "echo 'PASS: canCrossCompile same platform'" else "exit 1"}
  ${if !platformUtils.canCrossCompile "x86_64-darwin" "aarch64-linux" then "echo 'PASS: canCrossCompile different platforms'" else "exit 1"}

  # Test 3: Platform-specific configuration utilities
  echo "Testing platform-specific configuration utilities..."
  ${if darwinDefaults.hasHomebrew then "echo 'PASS: Darwin defaults include Homebrew'" else "exit 1"}
  ${if !linuxDefaults.hasHomebrew then "echo 'PASS: Linux defaults exclude Homebrew'" else "exit 1"}

  # Test 4: Build optimization utilities
  echo "Testing build optimization utilities..."
  ${if builtins.length darwinFlags > 0 then "echo 'PASS: Darwin build flags not empty'" else "exit 1"}
  ${if maxJobs > 0 then "echo 'PASS: Max jobs is positive'" else "exit 1"}

  # Test 5: System path utilities
  echo "Testing system path utilities..."
  ${if builtins.elem "/usr/bin" darwinPaths then "echo 'PASS: Darwin paths include /usr/bin'" else "exit 1"}
  ${if darwinPkgMgr == "brew" then "echo 'PASS: Darwin uses brew'" else "exit 1"}
  ${if linuxPkgMgr == "nix" then "echo 'PASS: Linux uses nix'" else "exit 1"}

  echo "All platform-utils tests passed!"
  touch $out
''
