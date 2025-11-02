# Edge Case Tests for User Configuration
# Tests boundary conditions, unusual but valid configurations, and error scenarios
#
# Tests the following edge cases:
#   - Boundary conditions for user configuration values
#   - Unusual but valid username formats
#   - Configuration limits and constraints
#   - Path handling edge cases
#   - Cross-platform user configuration edge cases
#   - Resource constraint scenarios
#
# VERSION: 1.0.0 (Task 11 - Edge Case Testing)
# LAST UPDATED: 2025-11-02

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import test helpers
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  userInfo = import ../../lib/user-info.nix;

  # === Username Boundary Condition Tests ===

  # Test minimum length usernames
  testMinLengthUsernames = [
    "a" # Single character
    "ab" # Two characters
    "x" # Single letter
  ];

  # Test maximum length usernames (reasonable limits)
  testMaxLengthUsernames = [
    "verylongusernamethatisstillvalid"
    "user-with-many-hyphens-and-numbers-12345"
    (lib.concatStringsSep "-" [
      "user"
      "01"
      "02"
      "03"
      "04"
      "05"
    ])
  ];

  # Test unusual but valid username formats
  testUnusualUsernames = [
    "user-with-dashes"
    "user_with_underscores"
    "user123" # Numbers
    "123user" # Starts with number
    "user.with.dots" # Dots (if allowed)
    "user" # Simple case
  ];

  # Test invalid usernames (should be rejected)
  testInvalidUsernames = [
    "" # Empty
    "user with spaces" # Spaces
    "user@symbol" # Special symbols
    "user#hash" # Hash symbol
    "user/slash" # Forward slash
    "user\\backslash" # Backslash
  ];

  # Validate username function
  validateUsername =
    username:
    let
      length = builtins.stringLength username;
      hasValidChars = builtins.match "^[a-zA-Z0-9._-]+$" username != null;
      hasNoSpaces = !lib.hasInfix " " username;
      hasNoDangerousChars =
        !lib.hasInfix "/" username && !lib.hasInfix "\\" username && !lib.hasInfix "@" username;
    in
    length >= 1 && length <= 64 && hasValidChars && hasNoSpaces && hasNoDangerousChars;

  # Generate user config for testing
  generateUserConfig = username: {
    name = if username == "" then "" else "${lib.toUpper username} User";
    email = if username == "" then "" else "${username}@example.com";
    username = username;
    homeDirectory = if username == "" then "" else "/home/${username}";
  };

  # === Path Handling Edge Cases ===

  # Test various home directory scenarios
  testPathEdgeCases = [
    {
      name = "standard-path";
      path = "/home/user";
      shouldWork = true;
    }
    {
      name = "darwin-path";
      path = "/Users/user";
      shouldWork = true;
    }
    {
      name = "nested-path";
      path = "/home/deep/nested/user/path";
      shouldWork = true;
    }
    {
      name = "relative-path";
      path = "~/user";
      shouldWork = false;
    }
    {
      name = "empty-path";
      path = "";
      shouldWork = false;
    }
    {
      name = "root-path";
      path = "/";
      shouldWork = false;
    }
  ];

  # Validate path function
  validatePath =
    path:
    let
      isAbsolute = lib.hasPrefix "/" path;
      hasValidLength = builtins.stringLength path >= 2;
      notRoot = path != "/";
      hasNoRelative = !lib.hasPrefix "~" path;
    in
    isAbsolute && hasValidLength && notRoot && hasNoRelative;

  # === Email Edge Cases ===

  # Test various email formats
  testEmailEdgeCases = [
    {
      name = "simple-email";
      email = "user@example.com";
      shouldWork = true;
    }
    {
      name = "email-with-subdomains";
      email = "user@mail.example.co.uk";
      shouldWork = true;
    }
    {
      name = "email-with-numbers";
      email = "user123@example.com";
      shouldWork = true;
    }
    {
      name = "email-with-dots";
      email = "user.name@example.com";
      shouldWork = true;
    }
    {
      name = "email-with-plus";
      email = "user+tag@example.com";
      shouldWork = true;
    }
    {
      name = "empty-email";
      email = "";
      shouldWork = false;
    }
    {
      name = "no-at-symbol";
      email = "userexample.com";
      shouldWork = false;
    }
    {
      name = "no-domain";
      email = "user@";
      shouldWork = false;
    }
  ];

  # Validate email function
  validateEmail =
    email:
    let
      hasAtSymbol = lib.hasInfix "@" email;
      hasDomain = builtins.match ".*@.*\\..*" email != null;
      hasValidLength = builtins.stringLength email >= 5;
    in
    hasAtSymbol && hasDomain && hasValidLength;

  # === Cross-Platform Edge Cases ===

  # Test platform-specific user configurations
  testPlatformEdgeCases = [
    {
      platform = "aarch64-darwin";
      username = "testuser";
      expectedHome = "/Users/testuser";
      shouldWork = true;
    }
    {
      platform = "x86_64-linux";
      username = "testuser";
      expectedHome = "/home/testuser";
      shouldWork = true;
    }
    {
      platform = "aarch64-linux";
      username = "testuser";
      expectedHome = "/home/testuser";
      shouldWork = true;
    }
  ];

  # Generate platform-specific config
  generatePlatformConfig =
    platform: username:
    let
      isDarwin = lib.hasInfix "darwin" platform;
      homePrefix = if isDarwin then "/Users" else "/home";
    in
    {
      inherit platform username;
      homeDirectory = "${homePrefix}/${username}";
      isDarwin = isDarwin;
    };

  # === Configuration Constraint Tests ===

  # Test configuration limits and constraints
  testConfigConstraints = [
    {
      name = "minimal-config";
      config = {
        name = "A";
        email = "a@b.co";
        username = "a";
        homeDirectory = "/home/a";
      };
      shouldWork = true;
    }
    {
      name = "maximal-name";
      config = {
        name = lib.concatStrings " " (lib.replicate 10 "VeryLongName");
        email = "user@example.com";
        username = "user";
        homeDirectory = "/home/user";
      };
      shouldWork = true;
    }
    {
      name = "missing-fields";
      config = {
        name = "User";
        # Missing email, username, homeDirectory
      };
      shouldWork = false;
    }
    {
      name = "empty-fields";
      config = {
        name = "";
        email = "";
        username = "";
        homeDirectory = "";
      };
      shouldWork = false;
    }
  ];

  # Validate complete configuration
  validateConfig =
    config:
    let
      hasName = builtins.hasAttr "name" config && builtins.stringLength config.name > 0;
      hasEmail = builtins.hasAttr "email" config && validateEmail config.email;
      hasUsername = builtins.hasAttr "username" config && validateUsername config.username;
      hasHome = builtins.hasAttr "homeDirectory" config && validatePath config.homeDirectory;
    in
    hasName && hasEmail && hasUsername && hasHome;

  # === Resource Constraint Edge Cases ===

  # Test scenarios with limited resources
  testResourceConstraints = [
    {
      name = "large-config";
      size = "large";
      shouldWork = true;
    }
    {
      name = "deep-nesting";
      depth = 10;
      shouldWork = true;
    }
    {
      name = "many-users";
      count = 100;
      shouldWork = true;
    }
  ];

  # Test large configuration handling
  testLargeConfig =
    testCase:
    let
      largeName = lib.concatStringsSep " " (lib.replicate 50 "LongName");
      largeConfig = {
        name = largeName;
        email = "user@example.com";
        username = "user";
        homeDirectory = "/home/user";
      };
    in
    validateConfig largeConfig;

  # Test deep nesting
  testDeepNesting =
    depth:
    let
      createNestedConfig =
        d: if d <= 0 then { value = "leaf"; } else { nested = createNestedConfig (d - 1); };
      nestedConfig = createNestedConfig depth;
    in
    builtins.hasAttr "nested" nestedConfig;

  # Test many users scenario
  testManyUsers =
    count:
    let
      generateUsers =
        n:
        if n <= 0 then
          [ ]
        else
          [
            {
              username = "user${toString n}";
              homeDirectory = "/home/user${toString n}";
            }
          ]
          ++ generateUsers (n - 1);
      users = generateUsers count;
      uniqueHomes = lib.unique (map (u: u.homeDirectory) users);
    in
    builtins.length users == builtins.length uniqueHomes;

  # === Test Suite Generation ===

  # Generate all edge case tests
  generateEdgeCaseTests = {
    # Username boundary tests
    username-min-length = testHelpers.runTestList "username-min-length" (
      map (username: {
        name = "min-length-${username}";
        expected = true;
        actual = validateUsername username;
      }) testMinLengthUsernames
    );

    username-max-length = testHelpers.runTestList "username-max-length" (
      map (username: {
        name = "max-length-${username}";
        expected = true;
        actual = validateUsername username;
      }) testMaxLengthUsernames
    );

    username-unusual-formats = testHelpers.runTestList "username-unusual" (
      map (username: {
        name = "unusual-${username}";
        expected = true;
        actual = validateUsername username;
      }) testUnusualUsernames
    );

    username-invalid = testHelpers.runTestList "username-invalid" (
      map (username: {
        name = "invalid-${
          builtins.replaceStrings [ " " "@" "/" "\\" "#" ] [ "-" "at" "slash" "backslash" "hash" ] username
        }";
        expected = false;
        actual = validateUsername username;
      }) testInvalidUsernames
    );

    # Path handling tests
    path-edge-cases = testHelpers.runTestList "path-edge-cases" (
      map (testCase: {
        name = testCase.name;
        expected = testCase.shouldWork;
        actual = validatePath testCase.path;
      }) testPathEdgeCases
    );

    # Email edge cases
    email-edge-cases = testHelpers.runTestList "email-edge-cases" (
      map (testCase: {
        name = testCase.name;
        expected = testCase.shouldWork;
        actual = validateEmail testCase.email;
      }) testEmailEdgeCases
    );

    # Cross-platform tests
    platform-edge-cases = testHelpers.runTestList "platform-edge-cases" (
      map (testCase: {
        name = "${testCase.platform}-${testCase.username}";
        expected = testCase.shouldWork;
        actual =
          let
            config = generatePlatformConfig testCase.platform testCase.username;
          in
          validateUsername config.username && validatePath config.homeDirectory;
      }) testPlatformEdgeCases
    );

    # Configuration constraint tests
    config-constraints = testHelpers.runTestList "config-constraints" (
      map (testCase: {
        name = testCase.name;
        expected = testCase.shouldWork;
        actual = validateConfig testCase.config;
      }) testConfigConstraints
    );

    # Resource constraint tests
    resource-large-config = {
      name = "resource-large-config";
      expected = true;
      actual = testLargeConfig { size = "large"; };
    };

    resource-deep-nesting = {
      name = "resource-deep-nesting";
      expected = true;
      actual = testDeepNesting 10;
    };

    resource-many-users = {
      name = "resource-many-users";
      expected = true;
      actual = testManyUsers 100;
    };
  };

in
{
  # Generate all edge case tests using mkTest helper pattern
  username-min-length = testHelpers.mkTest "username-min-length" ''
    echo "Testing minimum length usernames..."
    ${testHelpers.runTestList "username-min-length" (
      map (username: {
        name = "min-length-${username}";
        expected = true;
        actual = validateUsername username;
      }) testMinLengthUsernames
    )}
  '';

  username-max-length = testHelpers.mkTest "username-max-length" ''
    echo "Testing maximum length usernames..."
    ${testHelpers.runTestList "username-max-length" (
      map (username: {
        name = "max-length-${username}";
        expected = true;
        actual = validateUsername username;
      }) testMaxLengthUsernames
    )}
  '';

  username-unusual-formats = testHelpers.mkTest "username-unusual-formats" ''
    echo "Testing unusual username formats..."
    ${testHelpers.runTestList "username-unusual" (
      map (username: {
        name = "unusual-${username}";
        expected = true;
        actual = validateUsername username;
      }) testUnusualUsernames
    )}
  '';

  username-invalid = testHelpers.mkTest "username-invalid" ''
    echo "Testing invalid usernames..."
    ${testHelpers.runTestList "username-invalid" (
      map (username: {
        name = "invalid-${
          builtins.replaceStrings [ " " "@" "/" "\\" "#" ] [ "-" "at" "slash" "backslash" "hash" ] username
        }";
        expected = false;
        actual = validateUsername username;
      }) testInvalidUsernames
    )}
  '';

  path-edge-cases = testHelpers.mkTest "path-edge-cases" ''
    echo "Testing path edge cases..."
    ${testHelpers.runTestList "path-edge-cases" (
      map (testCase: {
        name = testCase.name;
        expected = testCase.shouldWork;
        actual = validatePath testCase.path;
      }) testPathEdgeCases
    )}
  '';

  email-edge-cases = testHelpers.mkTest "email-edge-cases" ''
    echo "Testing email edge cases..."
    ${testHelpers.runTestList "email-edge-cases" (
      map (testCase: {
        name = testCase.name;
        expected = testCase.shouldWork;
        actual = validateEmail testCase.email;
      }) testEmailEdgeCases
    )}
  '';

  platform-edge-cases = testHelpers.mkTest "platform-edge-cases" ''
    echo "Testing platform edge cases..."
    ${testHelpers.runTestList "platform-edge-cases" (
      map (testCase: {
        name = "${testCase.platform}-${testCase.username}";
        expected = testCase.shouldWork;
        actual =
          let
            config = generatePlatformConfig testCase.platform testCase.username;
          in
          validateUsername config.username && validatePath config.homeDirectory;
      }) testPlatformEdgeCases
    )}
  '';

  config-constraints = testHelpers.mkTest "config-constraints" ''
    echo "Testing configuration constraints..."
    ${testHelpers.runTestList "config-constraints" (
      map (testCase: {
        name = testCase.name;
        expected = testCase.shouldWork;
        actual = validateConfig testCase.config;
      }) testConfigConstraints
    )}
  '';

  resource-large-config = testHelpers.mkTest "resource-large-config" ''
    echo "Testing large configuration handling..."
    result=${toString (testLargeConfig { size = "large"; })}
    echo "Large config test result: $result"
    if [ "$result" = "true" ]; then
      echo "✅ Large configuration test passed"
    else
      echo "❌ Large configuration test failed"
      exit 1
    fi
  '';

  resource-deep-nesting = testHelpers.mkTest "resource-deep-nesting" ''
    echo "Testing deep nesting handling..."
    result=${toString (testDeepNesting 10)}
    echo "Deep nesting test result: $result"
    if [ "$result" = "true" ]; then
      echo "✅ Deep nesting test passed"
    else
      echo "❌ Deep nesting test failed"
      exit 1
    fi
  '';

  resource-many-users = testHelpers.mkTest "resource-many-users" ''
    echo "Testing many users scenario..."
    result=${toString (testManyUsers 100)}
    echo "Many users test result: $result"
    if [ "$result" = "true" ]; then
      echo "✅ Many users test passed"
    else
      echo "❌ Many users test failed"
      exit 1
    fi
  '';

  # Test suite aggregator
  test-suite = testHelpers.testSuite "edge-case-user-config" [
    username-min-length
    username-max-length
    username-unusual-formats
    username-invalid
    path-edge-cases
    email-edge-cases
    platform-edge-cases
    config-constraints
    resource-large-config
    resource-deep-nesting
    resource-many-users
  ];
}
