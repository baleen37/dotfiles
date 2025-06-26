# Unit tests for lib/common-utils.nix
# Tests common utility functions for system operations

{ pkgs ? import <nixpkgs> {} }:

let
  # Import the module we're testing
  commonUtils = import ../../lib/common-utils.nix { inherit pkgs; };
  
  # Pre-computed test values
  testPackages = ["git" "bash"];
  filtered = commonUtils.filterValidPackages testPackages pkgs;
  
  # Test mergeConfigs
  config1 = { a = 1; b = { x = 10; }; };
  config2 = { b = { y = 20; }; c = 3; };
  merged = commonUtils.mergeConfigs config1 config2;
  
  # Test list functions
  testList = [1 2 2 3 1 4];
  uniqueList = commonUtils.unique testList;
  
  nestedList = [[1 2] [3] [4 5 6]];
  flatList = commonUtils.flatten nestedList;
  
  # Test string functions
  joined = commonUtils.joinStrings "-" ["a" "b" "c"];

in
pkgs.runCommand "common-utils-unit-tests" { } ''
  # Test 1: System detection utilities
  echo "Testing system detection utilities..."
  
  # Test isSystem function
  ${if commonUtils.isSystem "x86_64-linux" "x86_64-linux" then "echo 'PASS: isSystem matches correctly'" else "exit 1"}
  ${if !commonUtils.isSystem "x86_64-linux" "aarch64-darwin" then "echo 'PASS: isSystem rejects correctly'" else "exit 1"}
  
  # Test isDarwin function
  ${if commonUtils.isDarwin "aarch64-darwin" then "echo 'PASS: isDarwin detects Darwin'" else "exit 1"}
  ${if !commonUtils.isDarwin "x86_64-linux" then "echo 'PASS: isDarwin rejects Linux'" else "exit 1"}
  
  # Test isLinux function
  ${if commonUtils.isLinux "x86_64-linux" then "echo 'PASS: isLinux detects Linux'" else "exit 1"}
  ${if !commonUtils.isLinux "aarch64-darwin" then "echo 'PASS: isLinux rejects Darwin'" else "exit 1"}
  
  # Test 2: Package filtering utilities
  echo "Testing package filtering utilities..."
  ${if builtins.length filtered == 2 then "echo 'PASS: filterValidPackages keeps valid packages'" else "exit 1"}
  
  # Test 3: Configuration merging utilities  
  echo "Testing configuration merging utilities..."
  ${if merged.a == 1 && merged.c == 3 then "echo 'PASS: mergeConfigs basic merge'" else "exit 1"}
  ${if merged.b.x == 10 && merged.b.y == 20 then "echo 'PASS: mergeConfigs nested merge'" else "exit 1"}
  
  # Test 4: List manipulation utilities
  echo "Testing list manipulation utilities..."
  ${if builtins.length uniqueList == 4 then "echo 'PASS: unique removes duplicates'" else "exit 1"}
  ${if builtins.length flatList == 6 then "echo 'PASS: flatten works correctly'" else "exit 1"}
  
  # Test 5: String utilities
  echo "Testing string utilities..."
  ${if joined == "a-b-c" then "echo 'PASS: joinStrings works correctly'" else "exit 1"}
  ${if commonUtils.hasPrefix "test" "testing" then "echo 'PASS: hasPrefix detects prefix'" else "exit 1"}
  ${if !commonUtils.hasPrefix "xyz" "testing" then "echo 'PASS: hasPrefix rejects non-prefix'" else "exit 1"}
  
  echo "All common-utils tests passed!"
  touch $out
''