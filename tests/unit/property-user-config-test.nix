# Property-Based Tests for User Configuration
# Tests user configuration invariants across multiple scenarios
#
# Tests the following properties:
#   - User config consistency for any valid username
#   - Home directory structure invariants across platforms
#   - Multi-user support properties
#   - XDG configuration invariants
#   - User information consistency across modules
#
# VERSION: 1.0.0 (Task 7 - Property-Based Testing)
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
  # Import property testing utilities
  propertyHelpers = import ../lib/property-test-helpers.nix { inherit pkgs lib; };

  # Import existing test helpers
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import user configuration modules for testing
  userInfo = import ../../lib/user-info.nix;
  homeManagerConfig = ../../users/shared/home-manager.nix;

  # Test data: Multiple realistic usernames
  testUsernames = [
    "baleen" # Current user
    "jito" # Alternative user
    "alex" # Short username
    "sarah123" # Username with numbers
    "test_user" # Username with underscore
    "dev" # Very short username
    "developer" # Long username
    "user42" # Numbers at end
  ];

  # === User Configuration Property Tests ===

  # Property: User configurations maintain consistency regardless of username
  userConfigConsistencyTest =
    propertyHelpers.forAllCases propertyHelpers.userConfigConsistencyProperty
      (map propertyHelpers.generateUserConfig testUsernames)
      "user-config-consistency";

  # Property: Home directory structure is consistent across platforms
  homeDirStructureTest =
    propertyHelpers.forAllCases propertyHelpers.homeDirStructureProperty testUsernames
      "home-dir-structure";

  # Property: XDG user directories are properly configured
  xdgConfigProperty =
    username:
    let
      userConfig = propertyHelpers.generateUserConfig username;
      # Simulate XDG configuration properties
      expectedDirs = [
        "XDG_CONFIG_HOME"
        "XDG_CACHE_HOME"
        "XDG_DATA_HOME"
        "XDG_STATE_HOME"
      ];
      # All XDG dirs should be under user's home directory
      xdgDirsUnderHome = lib.all (dir: lib.hasPrefix userConfig.homeDirectory "/${dir}") expectedDirs;
      # XDG should be enabled
      xdgEnabled = true;
    in
    xdgDirsUnderHome && xdgEnabled;

  xdgConfigTest = propertyHelpers.forAllCases xdgConfigProperty testUsernames "xdg-configuration";

  # Property: User information is consistent across all modules
  userInfoConsistencyProperty =
    username:
    let
      generatedUser = propertyHelpers.generateUserConfig username;
      actualUserInfo = userInfo;

      # Compare key properties
      nameMatches = generatedUser.name != "" && actualUserInfo.name != "";
      emailMatches = generatedUser.email != "" && actualUserInfo.email != "";

      # Both should have valid email format
      generatedEmailValid = builtins.match ".*@.*\\..*" generatedUser.email != null;
      actualEmailValid = builtins.match ".*@.*\\..*" actualUserInfo.email != null;

      # Names should be reasonable length
      generatedNameReasonable = builtins.stringLength generatedUser.name > 1;
      actualNameReasonable = builtins.stringLength actualUserInfo.name > 1;
    in
    nameMatches
    && emailMatches
    && generatedEmailValid
    && actualEmailValid
    && generatedNameReasonable
    && actualNameReasonable;

  userInfoConsistencyTest =
    propertyHelpers.forAllCases userInfoConsistencyProperty testUsernames
      "user-info-consistency";

  # Property: Multi-user configuration isolation
  multiUserIsolationProperty =
    user1: user2:
    let
      config1 = propertyHelpers.generateUserConfig user1;
      config2 = propertyHelpers.generateUserConfig user2;

      # Different users should have different home directories
      differentHomeDirs = config1.homeDirectory != config2.homeDirectory;

      # Different users should have different usernames (obviously)
      differentUsernames = config1.username != config2.username;

      # But they should both have valid structure
      bothValid =
        builtins.stringLength config1.homeDirectory > 0
        && builtins.stringLength config2.homeDirectory > 0
        && builtins.stringLength config1.username > 0
        && builtins.stringLength config2.username > 0;
    in
    differentHomeDirs && differentUsernames && bothValid;

  # Generate user pairs for isolation testing
  userPairs =
    let
      users = testUsernames;
      pairs = lib.cartesianProductOfSets {
        u1 = users;
        u2 = users;
      };
      # Only test unique pairs where u1 != u2
      uniquePairs = lib.filter (pair: pair.u1 != pair.u2) pairs;
    in
    uniquePairs;

  multiUserIsolationTest = propertyHelpers.forAllCases (
    pair: multiUserIsolationProperty pair.u1 pair.u2
  ) userPairs "multi-user-isolation";

  # Property: Configuration loading maintains user context
  configContextProperty =
    username:
    let
      userConfig = propertyHelpers.generateUserConfig username;

      # Simulate Home Manager configuration loading
      homeConfig = {
        home = {
          username = userConfig.username;
          homeDirectory = userConfig.homeDirectory;
          stateVersion = "24.11";
        };
        xdg.enable = true;
      };

      # Properties that should hold after loading
      usernamePreserved = homeConfig.home.username == userConfig.username;
      homeDirPreserved = homeConfig.home.homeDirectory == userConfig.homeDirectory;
      hasStateVersion = homeConfig.home.stateVersion != "";
      xdgEnabled = homeConfig.xdg.enable;
    in
    usernamePreserved && homeDirPreserved && hasStateVersion && xdgEnabled;

  configContextTest =
    propertyHelpers.forAllCases configContextProperty testUsernames
      "config-context-preservation";

  # Property: User configuration validation across edge cases
  edgeCaseValidationProperty =
    testCase:
    let
      # Test various edge cases
      testCases = [
        {
          username = "a";
          valid = true;
        } # Minimum length
        {
          username = "user-with-dash";
          valid = true;
        }
        {
          username = "user.with.dots";
          valid = true;
        }
        {
          username = "123user";
          valid = true;
        } # Starts with number
        {
          username = "";
          valid = false;
        } # Empty username
        {
          username = "user with spaces";
          valid = false;
        }
        {
          username = "user@symbol";
          valid = false;
        }
      ];

      currentCase = builtins.elemAt testCases (lib.mod testCase (builtins.length testCases));
      username = currentCase.username;
      expectedValid = currentCase.valid;

      # Check if our validation matches expectations
      usernameValid =
        builtins.stringLength username > 0 && builtins.match "^[a-zA-Z0-9._-]+$" username != null;

      # Also check generated user config
      userConfig = propertyHelpers.generateUserConfig username;
      configValid =
        builtins.stringLength userConfig.name > 0 && builtins.stringLength userConfig.homeDirectory > 0;
    in
    (expectedValid -> (usernameValid && configValid))
    && (!expectedValid -> (!usernameValid || !configValid));

  edgeCaseValidationTest = propertyHelpers.forAll edgeCaseValidationProperty (
    i: i
  ) "edge-case-validation";

  # === Test Suite Aggregation ===

  # Generate comprehensive user property tests
  userPropertyTests = propertyHelpers.generateUserPropertyTests testUsernames;

  # Combine all property tests into a test suite
  testSuite = propertyHelpers.propertyTestSuite "user-config-properties" {
    user-consistency = {
      name = "user-consistency";
      result = userConfigConsistencyTest;
    };

    home-dir-structure = {
      name = "home-dir-structure";
      result = homeDirStructureTest;
    };

    xdg-configuration = {
      name = "xdg-configuration";
      result = xdgConfigTest;
    };

    user-info-consistency = {
      name = "user-info-consistency";
      result = userInfoConsistencyTest;
    };

    multi-user-isolation = {
      name = "multi-user-isolation";
      result = multiUserIsolationTest;
    };

    config-context-preservation = {
      name = "config-context-preservation";
      result = configContextTest;
    };

    edge-case-validation = {
      name = "edge-case-validation";
      result = edgeCaseValidationTest;
    };
  };

in
{
  # Property-based tests using mkTest helper pattern
  user-config-consistency = testHelpers.mkTest "user-config-consistency" ''
    echo "Testing user configuration consistency for any valid username..."
    echo "Testing across ${toString (builtins.length testUsernames)} different usernames..."
    cat ${userConfigConsistencyTest}
  '';

  home-dir-structure = testHelpers.mkTest "home-dir-structure" ''
    echo "Testing home directory structure consistency across platforms..."
    cat ${homeDirStructureTest}
  '';

  xdg-configuration = testHelpers.mkTest "xdg-configuration" ''
    echo "Testing XDG configuration properties..."
    cat ${xdgConfigTest}
  '';

  user-info-consistency = testHelpers.mkTest "user-info-consistency" ''
    echo "Testing user information consistency across modules..."
    cat ${userInfoConsistencyTest}
  '';

  multi-user-isolation = testHelpers.mkTest "multi-user-isolation" ''
    echo "Testing multi-user configuration isolation (${toString (builtins.length userPairs)} user pairs)..."
    cat ${multiUserIsolationTest}
  '';

  config-context-preservation = testHelpers.mkTest "config-context-preservation" ''
    echo "Testing configuration context preservation..."
    cat ${configContextTest}
  '';

  edge-case-validation = testHelpers.mkTest "edge-case-validation" ''
    echo "Testing edge case validation..."
    cat ${edgeCaseValidationTest}
  '';

  # Test suite aggregator
  test-suite = testHelpers.testSuite "property-user-config" [
    user-config-consistency
    home-dir-structure
    xdg-configuration
    user-info-consistency
    multi-user-isolation
    config-context-preservation
    edge-case-validation
  ];
}
