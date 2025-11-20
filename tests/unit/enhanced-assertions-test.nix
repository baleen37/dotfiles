# tests/unit/enhanced-assertions-test.nix
# Test enhanced assertion utilities with detailed error reporting

{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Create test files for content comparison
  expectedFile = pkgs.writeText "expected.txt" ''
    Hello World
    This is test content
    Line 3
  '';

  actualFileMatch = pkgs.writeText "actual-match.txt" ''
    Hello World
    This is test content
    Line 3
  '';

  actualFileMismatch = pkgs.writeText "actual-mismatch.txt" ''
    Hello World
    This is different content
    Line 3
  '';
in
helpers.testSuite "enhanced-assertions" [
  # Test basic assertTestWithDetails pass case
  (enhancedHelpers.assertTestWithDetails "simple-pass" true "Should pass" null null null null)

  # Test basic assertTestWithDetails fail case with detailed error reporting
  (enhancedHelpers.assertTestWithDetails "simple-fail" false "Should fail" "expected-value" "actual-value" "test-file.txt" 42)

  # Test assertFileContent with matching files (should pass)
  (enhancedHelpers.assertFileContent "file-content-match" expectedFile actualFileMatch)

  # Test assertFileContent with mismatching files (should fail with detailed diff)
  (enhancedHelpers.assertFileContent "file-content-mismatch" expectedFile actualFileMismatch)
]
