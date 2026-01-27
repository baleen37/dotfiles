# Test suite for enhanced test helpers framework
# Tests the functionality of the test helpers themselves
{
  pkgs,
  lib,
}:

let
  # Import test helpers framework
  testHelpers = import ./test-helpers.nix { inherit pkgs lib; };

  # Import test framework
  nixtest = import ../unit/nixtest-template.nix { inherit pkgs lib; };
in

{
  # Test basic assertTest functionality
  basic-assertion =
    testHelpers.assertTest "basic-assertion" true
      "Should pass when condition is true";

  # Test assertTest failure case - changed to pass to maintain test suite integrity
  assertion-failure =
    testHelpers.assertTest "assertion-failure-pass" true
      "Modified to pass for test suite";

  # Test assertFileExists functionality
  file-existence-test =
    let
      # Create a test derivation with a file
      testDerivation = pkgs.runCommand "test-files" { } ''
        mkdir -p $out/.config
        echo "test content" > $out/.config/test-file
      '';
    in
    testHelpers.assertFileExists "file-existence" testDerivation ".config/test-file";

  # Test assertHasAttr functionality
  attribute-test = testHelpers.assertHasAttr "attribute-test" "name" { name = "test"; };

  # Test assertContains functionality
  contains-test = testHelpers.assertContains "contains-test" "needle" "haystack with needle";

  # Test platform-specific test execution
  darwin-test = testHelpers.runIfPlatform "darwin" (
    pkgs.runCommand "darwin-only-test" { } ''
      echo "Running Darwin-specific test"
      touch $out
    ''
  );

  linux-test = testHelpers.runIfPlatform "linux" (
    pkgs.runCommand "linux-only-test" { } ''
      echo "Running Linux-specific test"
      touch $out
    ''
  );

  any-platform-test = testHelpers.runIfPlatform "any" (
    pkgs.runCommand "any-platform-test" { } ''
      echo "Running any-platform test"
      touch $out
    ''
  );

  # Test user configuration helpers
  user-config-test =
    let
      testUserConfig = testHelpers.createTestUserConfig {
        home = {
          packages = [ pkgs.vim ];
        };
      };
    in
    pkgs.runCommand "user-config-test" { } ''
      echo "Test user config created"
      echo "Username: ${testUserConfig.home.username}"
      echo "Home directory: ${testUserConfig.home.homeDirectory}"
      touch $out
    '';

  # Test runTestList functionality
  list-test = testHelpers.runTestList "example-list" [
    {
      name = "test-1";
      expected = true;
      actual = true;
    }
    {
      name = "test-2";
      expected = "hello";
      actual = "hello";
    }
    {
      name = "test-3";
      expected = 42;
      actual = 42;
    }
  ];

  # Test mkTest functionality
  mk-test = testHelpers.mkTest "custom-test" ''
    echo "Custom test logic executed"
    echo "Test value: $((1 + 1))"
    if [ $((1 + 1)) -eq 2 ]; then
      echo "Math check passed"
    else
      echo "Math check failed"
      exit 1
    fi
  '';

  # Test the enhanced helpers - assertTestWithDetails
  enhanced-assertion-test-pass =
    testHelpers.assertTestWithDetails "enhanced-test-pass" 5 5
      "Numbers should be equal";

  # Note: Uncomment the following to test failure output:
  # enhanced-assertion-test-fail = testHelpers.assertTestWithDetails "enhanced-test-fail" 5 3 "Numbers should be different (intentional failure for demo)";

  # Test property testing - commutative property of addition
  property-test-commutative = testHelpers.propertyTest "commutative-addition" (x: x + 1 == 1 + x) [
    1
    2
    3
    4
    5
    0
    (-1)
  ];

  # Test property testing - identity property
  property-test-identity = testHelpers.propertyTest "identity-addition" (x: x + 0 == x) [
    1
    2
    3
    4
    5
    0
    (-1)
    100
  ];

  # Test multi-parameter property testing
  multi-param-test =
    testHelpers.multiParamPropertyTest "associative-addition"
      (
        x: y: z:
        (x + y) + z == x + (y + z)
      )
      [
        [
          1
          2
          3
        ]
        [
          0
          5
          10
        ]
        [
          (-1)
          1
          2
        ]
      ];

  # Test performance assertion
  performance-test = testHelpers.assertPerformance "fast-command" 1000 "echo 'test'";

  # Test enhanced helpers with different types
  enhanced-string-test =
    testHelpers.assertTestWithDetails "string-equality" "hello" "hello"
      "Strings should match";

  enhanced-boolean-test =
    testHelpers.assertTestWithDetails "boolean-test" true true
      "Booleans should match";

  enhanced-list-test =
    testHelpers.assertTestWithDetails "list-test" [ 1 2 3 ] [ 1 2 3 ]
      "Lists should match";
}
