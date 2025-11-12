# Test for Unified Test Helpers
# Tests that the unified helper functions work correctly
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
}:

let
  # Import the unified test helpers
  unifiedHelpers = import ../lib/unified-test-helpers.nix { inherit pkgs lib; };

  # Test 1: Basic assertTest functionality
  testAssertTestPass = unifiedHelpers.assertTest "assert-test-pass" true "Should pass";

  # Test 2: assertTest failure case (commented out as it would fail)
  # testAssertTestFail = unifiedHelpers.assertTest "assert-test-fail" false "Should fail";

  # Test 3: assertHasAttr functionality
  testAssertHasAttrPass = unifiedHelpers.assertHasAttr "assert-has-attr-pass" "testAttr" { testAttr = "value"; };

  # Test 4: assertContains functionality
  testAssertContainsPass = unifiedHelpers.assertContains "assert-contains-pass" "needle" "haystack with needle inside";

  # Test 5: assertFileExists functionality
  # Create a test derivation with a file
  testDerivation = pkgs.writeTextDir "test-file.txt" "test content";
  testAssertFileExists = unifiedHelpers.assertFileExists "assert-file-exists" testDerivation "test-file.txt";

  # Test 6: canImport functionality
  testCanImport = pkgs.runCommand "test-can-import" { } ''
    echo "Testing canImport function..."

    # Test importing a known good file
    result="${builtins.toString (unifiedHelpers.canImport ./test-can-import.nix)}"

    if [ "$result" = "true" ] || [ "$result" = "1" ]; then
      echo "✅ PASS: canImport correctly identifies importable files"
    else
      echo "❌ FAIL: canImport failed to identify importable file (result: $result)"
      exit 1
    fi

    touch $out
  '';

  # Test 7: getUserHomeDir functionality
  testGetUserHomeDir = pkgs.runCommand "test-get-user-home-dir" { } ''
    echo "Testing getUserHomeDir function..."

    # Test Darwin path
    darwinPath="${unifiedHelpers.getUserHomeDir "testuser" true}"
    expectedDarwin="/Users/testuser"

    if [ "$darwinPath" = "$expectedDarwin" ]; then
      echo "✅ PASS: getUserHomeDir returns correct Darwin path"
    else
      echo "❌ FAIL: getUserHomeDir returned '$darwinPath', expected '$expectedDarwin'"
      exit 1
    fi

    # Test Linux path
    linuxPath="${unifiedHelpers.getUserHomeDir "testuser" false}"
    expectedLinux="/home/testuser"

    if [ "$linuxPath" = "$expectedLinux" ]; then
      echo "✅ PASS: getUserHomeDir returns correct Linux path"
    else
      echo "❌ FAIL: getUserHomeDir returned '$linuxPath', expected '$expectedLinux'"
      exit 1
    fi

    touch $out
  '';

  # Test 8: allPackagesExist functionality
  testAllPackagesExist = pkgs.runCommand "test-all-packages-exist" { } ''
    echo "Testing allPackagesExist function..."

    # Test with all valid packages
    validPackagesResult="${builtins.toString (unifiedHelpers.allPackagesExist [pkgs.git pkgs.vim pkgs.zsh])}"

    if [ "$validPackagesResult" = "true" ] || [ "$validPackagesResult" = "1" ]; then
      echo "✅ PASS: allPackagesExist correctly identifies valid packages"
    else
      echo "❌ FAIL: allPackagesExist failed to identify valid packages"
      exit 1
    fi

    # Test with null package
    nullPackagesResult="${builtins.toString (unifiedHelpers.allPackagesExist [pkgs.git null pkgs.vim])}"

    if [ "$nullPackagesResult" = "" ]; then
      echo "✅ PASS: allPackagesExist correctly identifies null package"
    else
      echo "❌ FAIL: allPackagesExist failed to identify null package"
      exit 1
    fi

    touch $out
  '';

  # Test 9: mkTest functionality
  testMkTest = unifiedHelpers.mkTest "mk-test-function" ''
    echo "Testing mkTest function..."
    if [ "test" = "test" ]; then
      echo "✅ mkTest execution works correctly"
    else
      echo "❌ mkTest execution failed"
      exit 1
    fi
  '';

  # Test 10: Constants availability
  testConstants = pkgs.runCommand "test-constants" { } ''
    echo "Testing constants availability..."

    # Check that test users exist
    if [ -n "${builtins.toString unifiedHelpers.constants.testUsers}" ]; then
      echo "✅ PASS: testUsers constant is available"
    else
      echo "❌ FAIL: testUsers constant is missing"
      exit 1
    fi

    # Check that required build packages exist
    if [ -n "${builtins.toString unifiedHelpers.constants.requiredBuildPackages}" ]; then
      echo "✅ PASS: requiredBuildPackages constant is available"
    else
      echo "❌ FAIL: requiredBuildPackages constant is missing"
      exit 1
    fi

    # Check state version
    if [ "${unifiedHelpers.constants.stateVersion}" = "24.05" ]; then
      echo "✅ PASS: stateVersion constant is correct"
    else
      echo "❌ FAIL: stateVersion constant is incorrect"
      exit 1
    fi

    touch $out
  '';

in
pkgs.runCommand "test-unified-helpers-results"
  {
    buildInputs = [
      testAssertTestPass
      testAssertHasAttrPass
      testAssertContainsPass
      testAssertFileExists
      testCanImport
      testGetUserHomeDir
      testAllPackagesExist
      testMkTest
      testConstants
    ];
  }
  ''
    echo "🧪 Running Unified Test Helpers Test Suite" > $out
    echo "" >> $out

    echo "✅ All unified helper tests passed!" >> $out
    echo "" >> $out
    echo "🎯 Unified helper functions verified:" >> $out
    echo "• assertTest - Basic assertion functionality" >> $out
    echo "• assertHasAttr - Attribute existence checking" >> $out
    echo "• assertContains - String containment checking" >> $out
    echo "• assertFileExists - File existence validation" >> $out
    echo "• canImport - Module import validation" >> $out
    echo "• getUserHomeDir - Platform-agnostic home directory resolution" >> $out
    echo "• allPackagesExist - Package validity checking" >> $out
    echo "• mkTest - Test derivation creation" >> $out
    echo "• constants - Common test constants" >> $out
    echo "" >> $out
    echo "📝 Benefits of unified helpers:" >> $out
    echo "• Eliminates code duplication between test-helpers.nix and e2e/helpers.nix" >> $out
    echo "• Provides consistent testing interface across all test types" >> $out
    echo "• Reduces maintenance burden by consolidating common functionality" >> $out
    echo "• Maintains backward compatibility with existing tests" >> $out

    # Also output to stdout for immediate feedback
    cat $out
  ''
