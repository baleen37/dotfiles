# Property-Based Testing Helpers for Nix Configuration
# Leverages Nix's functional nature for testing invariants across many scenarios
#
# Property-based testing validates that certain properties hold true across
# a wide range of inputs, catching edge cases that example-based testing misses.
#
# Key capabilities:
#   - Generate test cases using Nix's builtins (genList, listToAttrs, etc.)
#   - Validate invariants across different user configurations
#   - Test cross-platform compatibility properties
#   - Validate transformation properties and system invariants
#
# VERSION: 1.0.0 (Task 7 - Property-Based Testing)
# LAST UPDATED: 2025-11-02

{
  pkgs,
  lib,
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
      isLinux = pkgs.stdenv.isLinux;
    };
  },
}:

let
  # Import existing test helpers
  testHelpers = import ./test-helpers.nix { inherit pkgs lib testConfig; };
in

rec {
  # Re-export existing helpers
  inherit (testHelpers)
    assertTest
    assertHasAttr
    assertContains
    assertFileExists
    ;

  # === Property Testing Core Utilities ===

  # Generate test cases using a generator function
  # Type: (a -> Bool) -> (Int -> a) -> String -> Derivation
  forAll =
    property: generator: name:
    let
      # Generate 100 test cases by default
      testCount = 100;
      testCases = builtins.genList generator testCount;
      # Test property against all generated cases
      results = map property testCases;
      # Check if all tests passed
      allPassed = lib.all lib.id results;
      failedCases = lib.filter (case: !case.result) (
        lib.zipListsWith (index: result: { inherit index result; }) (lib.range 0 (testCount - 1)) results
      );
    in
    if allPassed then
      pkgs.runCommand "property-test-${name}-pass" { } ''
        echo "✅ ${name}: Property holds for all ${toString testCount} test cases"
        touch $out
      ''
    else
      pkgs.runCommand "property-test-${name}-fail" { } ''
        echo "❌ ${name}: Property failed for ${toString (builtins.length failedCases)} test cases"
        ${lib.concatMapStringsSep "\n" (case: ''
          echo "  Failed case ${toString case.index}: ${toString (builtins.elemAt testCases case.index)}"
        '') failedCases}
        exit 1
      '';

  # Test a property across multiple predefined test cases
  # Type: (a -> Bool) -> [a] -> String -> Derivation
  forAllCases =
    property: testCases: name:
    let
      results = map property testCases;
      allPassed = lib.all lib.id results;
      failedCases = lib.filter (case: !case.result) (
        lib.zipListsWith (testCase: result: { inherit testCase result; }) testCases results
      );
    in
    if allPassed then
      pkgs.runCommand "property-test-cases-${name}-pass" { } ''
        echo "✅ ${name}: Property holds for all ${toString (builtins.length testCases)} test cases"
        touch $out
      ''
    else
      pkgs.runCommand "property-test-cases-${name}-fail" { } ''
        echo "❌ ${name}: Property failed for ${toString (builtins.length failedCases)} test cases"
        ${lib.concatMapStringsSep "\n" (case: ''
          echo "  Failed case: ${toString case.testCase}"
        '') failedCases}
        exit 1
      '';

  # === Test Data Generators ===

  # Generate valid usernames (alphanumeric, starting with letter)
  generateUsername =
    i:
    let
      letters = "abcdefghijklmnopqrstuvwxyz";
      chars = letters + "0123456789";
      base = builtins.substring (lib.mod i 26) 1 letters;
      suffix = builtins.substring (lib.mod i 36) 1 chars;
    in
    "${base}${suffix}";

  # Generate valid email addresses
  generateEmail =
    username:
    let
      domains = [
        "gmail.com"
        "yahoo.com"
        "outlook.com"
        "protonmail.com"
        "example.com"
      ];
      domain = builtins.elemAt domains (
        lib.mod (builtins.stringLength username) (builtins.length domains)
      );
    in
    "${username}@${domain}";

  # Generate user configurations
  generateUserConfig = username: {
    name = "Test User ${username}";
    email = generateEmail username;
    username = username;
    homeDirectory = "${testConfig.homeDirPrefix}/${username}";
  };

  # Generate package lists for testing
  generatePackageList =
    seed:
    let
      basePackages = [
        "git"
        "vim"
        "curl"
        "wget"
        "tree"
        "jq"
        "ripgrep"
        "fzf"
      ];
      additionalPackages = [
        "nodejs"
        "python3"
        "docker"
        "gh"
        "sqlite"
        "postgresql"
      ];
      useAdditional = (lib.mod seed 2) == 0;
      selectedPackages = if useAdditional then basePackages ++ additionalPackages else basePackages;
    in
    builtins.genList (
      i: builtins.elemAt selectedPackages (lib.mod i (builtins.length selectedPackages))
    ) (lib.mod seed (builtins.length selectedPackages) + 1);

  # Generate git alias configurations
  generateGitAliases =
    seed:
    let
      baseAliases = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        df = "diff";
        lg = "log --graph --oneline --decorate --all";
      };
      extendedAliases = baseAliases // {
        aa = "add --all";
        ap = "add --patch";
        cm = "commit -m";
        amend = "commit --amend";
        pushf = "push --force-with-lease";
      };
      useExtended = (lib.mod seed 3) != 0; # 2/3 of cases use extended aliases
    in
    if useExtended then extendedAliases else baseAliases;

  # === Property Tests for User Configuration ===

  # Test that user configurations maintain consistency regardless of username
  userConfigConsistencyProperty =
    username:
    let
      userConfig = generateUserConfig username;
      # Properties that should hold for any valid user
      hasValidName = builtins.stringLength userConfig.name > 0;
      hasValidEmail = builtins.match ".*@.*\\..*" userConfig.email != null;
      hasValidUsername = builtins.stringLength userConfig.username > 0;
      hasValidHomeDir = builtins.stringLength userConfig.homeDirectory > 0;
      homeDirMatchesUsername = lib.hasInfix username userConfig.homeDirectory;
    in
    hasValidName && hasValidEmail && hasValidUsername && hasValidHomeDir && homeDirMatchesUsername;

  # Test that home directory structure is consistent across platforms
  homeDirStructureProperty =
    username:
    let
      userConfig = generateUserConfig username;
      expectedPrefix = testConfig.homeDirPrefix;
      homeDir = userConfig.homeDirectory;
      startsWithCorrectPrefix = lib.hasPrefix expectedPrefix homeDir;
      endsWithUsername = lib.hasSuffix username homeDir;
      hasCorrectSeparator = lib.hasInfix "/" homeDir;
    in
    startsWithCorrectPrefix && endsWithUsername && hasCorrectSeparator;

  # === Property Tests for Git Configuration ===

  # Test that git aliases maintain valid structure
  gitAliasStructureProperty =
    aliases:
    let
      # All aliases should be non-empty strings
      allNonEmpty = lib.all (
        name:
        let
          value = aliases.${name} or "";
        in
        builtins.stringLength value > 0
      ) (builtins.attrNames aliases);

      # All aliases should contain valid git commands (no dangerous commands)
      dangerousCommands = [
        "rm "
        "rm -rf"
        "sudo "
        "chmod "
        "chown "
      ];
      containsDangerousCommand =
        aliasValue: builtins.any (cmd: lib.hasPrefix cmd aliasValue) dangerousCommands;
      noDangerousCommands = lib.all (
        name:
        let
          value = aliases.${name} or "";
        in
        !(containsDangerousCommand value)
      ) (builtins.attrNames aliases);

      # All alias names should be reasonable (not too long, alphanumeric)
      reasonableNames = lib.all (
        name:
        let
          nameLength = builtins.stringLength name;
          nameValid = nameLength >= 1 && nameLength <= 10;
          nameChars = builtins.match "^[a-zA-Z0-9_]+$" name != null;
        in
        nameValid && nameChars
      ) (builtins.attrNames aliases);
    in
    allNonEmpty && noDangerousCommands && reasonableNames;

  # Test that git user identity is consistent across configuration
  gitUserIdentityProperty =
    userConfig:
    let
      # Extract user info from git config (simulated)
      gitUserName = userConfig.name;
      gitUserEmail = userConfig.email;

      # Properties that should hold
      nameValid = builtins.stringLength gitUserName > 1;
      emailValid = builtins.match ".*@.*\\..*" gitUserEmail != null;
      noTrailingSpaces = !(lib.hasSuffix " " gitUserName) && !(lib.hasSuffix " " gitUserEmail);
      noLeadingSpaces = !(lib.hasPrefix " " gitUserName) && !(lib.hasPrefix " " gitUserEmail);
    in
    nameValid && emailValid && noTrailingSpaces && noLeadingSpaces;

  # === Property Tests for System Configuration ===

  # Test that Nix settings maintain security invariants
  nixSettingsSecurityProperty =
    config:
    let
      nixSettings = config.nix.settings or { };

      # Security properties that should always hold
      hasCache = builtins.length (nixSettings.substituters or [ ]) >= 1;
      hasTrustedKeys = builtins.length (nixSettings.trusted-public-keys or [ ]) >= 1;
      hasTrustedUsers = builtins.length (nixSettings.trusted-users or [ ]) >= 1;

      # URL properties
      allCacheUrlsSecure = lib.all (url: lib.hasPrefix "https://" url || lib.hasPrefix "file://" url) (
        nixSettings.substituters or [ ]
      );

      # Key properties (should be actual GPG keys)
      allKeysValid = lib.all (key: builtins.stringLength key > 20 && lib.hasInfix "=" key) (
        nixSettings.trusted-public-keys or [ ]
      );
    in
    hasCache && hasTrustedKeys && hasTrustedUsers && allCacheUrlsSecure && allKeysValid;

  # Test that package installation maintains system integrity
  packageIntegrityProperty =
    packageList:
    let
      # All packages should be valid strings
      allValidNames = lib.all (
        pkg:
        let
          pkgName = builtins.toString pkg;
        in
        builtins.stringLength pkgName > 0 && builtins.match "^[a-zA-Z0-9._-]+$" pkgName != null
      ) packageList;

      # No duplicate packages
      uniquePackages = lib.unique packageList;
      noDuplicates = builtins.length packageList == builtins.length uniquePackages;

      # Package count should be reasonable (not too many)
      reasonableCount = builtins.length packageList <= 200; # Sanity check

      # Essential packages should be present for development setup
      essentialPackages = [
        "git"
        "curl"
        "wget"
      ];
      hasEssential = lib.all (pkg: lib.elem pkg packageList) essentialPackages;
    in
    allValidNames && noDuplicates && reasonableCount && hasEssential;

  # === Cross-Platform Property Tests ===

  # Test that platform detection works correctly
  platformDetectionProperty =
    platformInfo:
    let
      # Platform properties should be mutually exclusive
      isDarwin = platformInfo.isDarwin or false;
      isLinux = platformInfo.isLinux or false;

      # Exactly one platform should be true
      exactlyOnePlatform = (isDarwin && !isLinux) || (!isDarwin && isLinux);

      # Platform-specific paths should be correct
      correctHomePrefix =
        if isDarwin then
          testConfig.homeDirPrefix == "/Users"
        else if isLinux then
          testConfig.homeDirPrefix == "/home"
        else
          false;
    in
    exactlyOnePlatform && correctHomePrefix;

  # === Transformation Property Tests ===

  # Test that configuration transformations preserve essential properties
  configTransformationProperty =
    baseConfig: transformFn:
    let
      transformedConfig = transformFn baseConfig;

      # Essential properties that should be preserved
      originalUsername = baseConfig.username or "";
      transformedUsername = transformedConfig.username or "";
      usernamePreserved = originalUsername == transformedUsername;

      originalHomeDir = baseConfig.homeDirectory or "";
      transformedHomeDir = transformedConfig.homeDirectory or "";
      homeDirPreserved = originalHomeDir == transformedHomeDir;

      # Configuration should still be valid after transformation
      stillValid = builtins.isAttrs transformedConfig && builtins.hasAttr "username" transformedConfig;
    in
    usernamePreserved && homeDirPreserved && stillValid;

  # === Test Suite Aggregators ===

  # Create a comprehensive property test suite
  propertyTestSuite =
    name: tests:
    pkgs.runCommand "property-test-suite-${name}" { } ''
      echo "Running property test suite: ${name}"

      ${lib.concatMapStringsSep "\n" (test: ''
        echo "Running test: ${test.name}"
        cat ${test.result}
        echo ""
      '') (if builtins.isList tests then tests else builtins.attrValues tests)}

      echo "✅ Property test suite ${name}: All tests passed"
      touch $out
    '';

  # Generate user-based property tests
  generateUserPropertyTests =
    usernames:
    let
      userConsistencyTests = builtins.listToAttrs (
        map (username: {
          name = "user-consistency-${username}";
          value = {
            name = "user-consistency-${username}";
            result = forAll userConfigConsistencyProperty (i: username) "user-config-consistency-${username}";
          };
        }) usernames
      );

      homeDirTests = builtins.listToAttrs (
        map (username: {
          name = "home-dir-structure-${username}";
          value = {
            name = "home-dir-structure-${username}";
            result = forAll homeDirStructureProperty (i: username) "home-dir-structure-${username}";
          };
        }) usernames
      );
    in
    userConsistencyTests // homeDirTests;

  # Generate Git configuration property tests
  generateGitPropertyTests =
    testCount:
    let
      aliasTests = builtins.listToAttrs (
        map (i: {
          name = "git-aliases-${toString i}";
          value = {
            name = "git-aliases-${toString i}";
            result = forAll gitAliasStructureProperty generateGitAliases "git-alias-structure-${toString i}";
          };
        }) (lib.range 1 testCount)
      );

      userIdentityTests = builtins.listToAttrs (
        map (i: {
          name = "git-user-identity-${toString i}";
          value = {
            name = "git-user-identity-${toString i}";
            result = forAll gitUserIdentityProperty generateUserConfig "git-user-identity-${toString i}";
          };
        }) (lib.range 1 testCount)
      );
    in
    aliasTests // userIdentityTests;

  # Generate system configuration property tests
  generateSystemPropertyTests =
    testCount:
    let
      packageTests = builtins.listToAttrs (
        map (i: {
          name = "package-integrity-${toString i}";
          value = {
            name = "package-integrity-${toString i}";
            result = forAll packageIntegrityProperty generatePackageList "package-integrity-${toString i}";
          };
        }) (lib.range 1 testCount)
      );

      platformTests = [
        {
          name = "platform-detection";
          result = forAllCases platformDetectionProperty [ testConfig.platformSystem ] "platform-detection";
        }
      ];
    in
    packageTests // builtins.listToAttrs platformTests;
}
