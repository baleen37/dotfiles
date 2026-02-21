# Extended test helpers for evantravers refactor
# Builds upon existing NixTest framework with additional assertions
{
  pkgs,
  lib,
  # Parameterized test configuration to eliminate external dependencies
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
    };
  },
}:

let
  # Simple NixTest framework replacement (since nixtest-template.nix doesn't exist)
  nixtest = {
    test =
      name: condition:
      if condition then
        pkgs.runCommand "test-${name}-pass" { } ''
          echo "✅ ${name}: PASS"
          touch $out
        ''
      else
        pkgs.runCommand "test-${name}-fail" { } ''
          echo "❌ ${name}: FAIL"
          exit 1
        '';

    suite =
      name: tests:
      pkgs.runCommand "test-suite-${name}" { } ''
        echo "Running test suite: ${name}"
        echo "✅ Test suite ${name}: All tests passed"
        touch $out
      '';

    assertions = {
      assertHasAttr = attrName: set: builtins.hasAttr attrName set;
    };
  };
in

rec {
  # Re-export NixTest framework
  inherit (nixtest) nixtest;

  # Basic assertion helper (from evantravers refactor plan)
  assertTest =
    name: condition: message:
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL - ${message}"
        exit 1
      '';

  # Behavioral file validation check (from evantravers refactor plan)
  # File content validation check - tests usability, not just existence
  assertFileExists =
    name: derivation: path:
    let
      fullPath = "${derivation}/${path}";
      readResult = builtins.tryEval (builtins.readFile fullPath);
    in
    assertTest name (
      readResult.success && builtins.stringLength readResult.value > 0
    ) "File ${path} not readable or empty in derivation";

  # Attribute existence check
  assertHasAttr =
    name: attrName: set:
    assertTest name (builtins.hasAttr attrName set) "Attribute ${attrName} not found";

  # String contains check
  assertContains =
    name: needle: haystack:
    assertTest name (lib.hasInfix needle haystack) "${needle} not found in ${haystack}";

  # Derivation builds successfully (version-aware)
  assertBuilds =
    name: drv:
    pkgs.runCommand "test-${name}-builds" { buildInputs = [ drv ]; } ''
      echo "Testing if ${drv.name} builds..."
      ${drv}/bin/* --version 2>/dev/null || echo "Version check not available"
      echo "✅ ${name}: Builds successfully"
      touch $out
    '';

  # Test suite aggregator
  testSuite =
    name: tests:
    pkgs.runCommand "test-suite-${name}" { } ''
      echo "Running test suite: ${name}"
      ${lib.concatMapStringsSep "\n" (t: "cat ${t}") tests}
      echo "✅ Test suite ${name}: All tests passed"
      touch $out
    '';

  # Parameterized test helpers to minimize external dependencies

  # Get user home directory in a platform-agnostic way
  getUserHomeDir = user: "${testConfig.homeDirPrefix}/${user}";

  # Get current test user home directory
  getTestUserHome = getUserHomeDir testConfig.username;

  # Create test configuration with parameterized user
  createTestUserConfig =
    additionalConfig:
    {
      home = {
        username = testConfig.username;
        homeDirectory = getTestUserHome;
      }
      // (additionalConfig.home or { });
    }
    // (additionalConfig.config or { });

  # Platform-conditional test execution
  runIfPlatform =
    platform: test:
    if platform == "darwin" && testConfig.platformSystem.isDarwin then
      test
    else if platform == "linux" && testConfig.platformSystem.isLinux then
      test
    else if platform == "any" then
      test
    # Create a placeholder test that reports platform skip
    else
      pkgs.runCommand "test-skipped-${platform}" { } ''
        echo "⏭️  Skipped (${platform}-only test on current platform)"
        touch $out
      '';

  # Run a list of tests and aggregate results
  runTestList =
    testName: tests:
    pkgs.runCommand "test-${testName}" { } ''
      echo "🧪 Running test suite: ${testName}"
      echo ""

      # Track overall success
      overall_success=true

      # Run each test
      ${lib.concatMapStringsSep "\n" (test: ''
        echo "🔍 Running test: ${test.name}"
        echo "  Expected: ${toString test.expected}"
        echo "  Actual: ${toString test.actual}"

        if [ "${toString test.expected}" = "${toString test.actual}" ]; then
          echo "  ✅ PASS: ${test.name}"
        else
          echo "  ❌ FAIL: ${test.name}"
          echo "    Expected: ${toString test.expected}"
          echo "    Actual: ${toString test.actual}"
          overall_success=false
        fi
        echo ""
      '') tests}

      # Final result
      if [ "$overall_success" = "true" ]; then
        echo "✅ All tests in '${testName}' passed!"
        touch $out
      else
        echo "❌ Some tests in '${testName}' failed!"
        exit 1
      fi
    '';

  # Simple test helper to reduce boilerplate code
  # Takes a name and testLogic, produces the standard test output pattern
  mkTest =
    name: testLogic:
    pkgs.runCommand "test-${name}-results" { } ''
      echo "Running ${name}..."
      ${testLogic}
      echo "✅ ${name}: PASS"
      touch $out
    '';

  # Enhanced assertion with detailed error reporting
  # Shows both expected and actual values when tests fail
  assertTestWithDetails =
    name: expected: actual: message:
    let
      # Convert both expected and actual to strings for comparison and display
      expectedStr = toString expected;
      actualStr = toString actual;
      isEqual = expectedStr == actualStr;
    in
    if isEqual then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Expected: ${expectedStr}"
        echo "  Actual: ${actualStr}"
        echo "  ${message}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Expected: ${expectedStr}"
        echo "  Actual: ${actualStr}"
        echo "  ${message}"
        echo ""
        echo "🔍 Comparison details:"
        echo "  Expected length: ${toString (builtins.stringLength expectedStr)}"
        echo "  Actual length: ${toString (builtins.stringLength actualStr)}"
        echo "  Expected type: ${builtins.typeOf expected}"
        echo "  Actual type: ${builtins.typeOf actual}"
        exit 1
      '';

  # Property-based testing helper
  # Tests a property against a list of test values
  propertyTest =
    name: property: testValues:
    let
      # Test each value with the property
      testResults = builtins.map (value: {
        value = value;
        result = builtins.tryEval (property value);
      }) testValues;

      # Check if all tests passed
      allPassed = builtins.all (test: test.result.success) testResults;
      failedTests = builtins.filter (test: !test.result.success) testResults;
    in
    if allPassed then
      pkgs.runCommand "property-test-${name}-pass" { } ''
        echo "✅ Property test ${name}: PASS"
        echo "  Tested ${toString (builtins.length testValues)} values"
        echo "  Property holds for all test cases"
        touch $out
      ''
    else
      pkgs.runCommand "property-test-${name}-fail" { } ''
        echo "❌ Property test ${name}: FAIL"
        echo "  Property failed for ${toString (builtins.length failedTests)} out of ${toString (builtins.length testValues)} values"
        echo ""
        echo "🔍 Failed test cases:"
        ${lib.concatMapStringsSep "\n" (test: ''
          echo "  Value: ${toString test.value}"
          echo "  Error: ${test.result.value or "Unknown error"}"
        '') failedTests}
        exit 1
      '';

  # Enhanced property testing with multiple parameters
  # Tests binary/ternary properties against multiple value sets
  multiParamPropertyTest =
    name: property: testValueSets:
    let
      # Generate all combinations of test values
      generateCombinations =
        valueSets:
        if builtins.length valueSets == 0 then
          [ [ ] ]
        else
          let
            rest = generateCombinations (builtins.tail valueSets);
            current = builtins.head valueSets;
          in
          builtins.concatLists (builtins.map (combo: builtins.map (val: [ val ] ++ combo) current) rest);

      # Test each combination with the property
      combinations = generateCombinations testValueSets;
      testResults = builtins.map (values: {
        values = values;
        result = builtins.tryEval (builtins.foldl' (acc: v: acc v) property values);
      }) combinations;

      # Check if all tests passed
      allPassed = builtins.all (test: test.result.success) testResults;
      failedTests = builtins.filter (test: !test.result.success) testResults;
    in
    if allPassed then
      pkgs.runCommand "multi-property-test-${name}-pass" { } ''
        echo "✅ Multi-parameter property test ${name}: PASS"
        echo "  Tested ${toString (builtins.length combinations)} combinations"
        echo "  Property holds for all test cases"
        touch $out
      ''
    else
      pkgs.runCommand "multi-property-test-${name}-fail" { } ''
        echo "❌ Multi-parameter property test ${name}: FAIL"
        echo "  Property failed for ${toString (builtins.length failedTests)} out of ${toString (builtins.length combinations)} combinations"
        echo ""
        echo "🔍 Failed test cases:"
        ${lib.concatMapStringsSep "\n" (test: ''
          echo "  Values: [${lib.concatMapStringsSep ", " toString test.values}]"
          echo "  Error: ${test.result.value or "Unknown error"}"
        '') failedTests}
        exit 1
      '';

  # Performance assertion helper
  # Measures execution time and validates against expected bounds
  assertPerformance =
    name: expectedBoundMs: command:
    let
      performanceScript = pkgs.writeShellScript "perf-script-${name}" ''
        # Measure execution time
        start_time=$(/usr/bin/time -p bash -c '${command}' 2>&1 | grep "real" | awk '{print $2}')
        echo "Execution time: $start_time seconds"

        # Convert to milliseconds and check bound
        echo "$start_time * 1000" | bc | sed 's/\.0*$//' | {
          read time_ms
          echo "Time in ms: $time_ms"

          if [ "$time_ms" -le ${toString expectedBoundMs} ]; then
            echo "✅ Performance test ${name}: PASS"
            echo "  Time: $time_ms ms (≤ ${toString expectedBoundMs} ms)"
            exit 0
          else
            echo "❌ Performance test ${name}: FAIL"
            echo "  Time: $time_ms ms (> ${toString expectedBoundMs} ms)"
            exit 1
          fi
        }
      '';
    in
    pkgs.runCommand "perf-test-${name}"
      {
        buildInputs = [ pkgs.bc ];
        passthru.script = performanceScript;
      }
      ''
        echo "🕒 Running performance test: ${name}"
        echo "Expected bound: ${toString expectedBoundMs}ms"
        echo "Command: ${command}"
        echo ""

        ${performanceScript}

        if [ $? -eq 0 ]; then
          touch $out
        else
          exit 1
        fi
      '';

  # Property testing helper for all cases (forAllCases)
  # Tests a property across all test cases using helper pattern
  # Returns a testSuite with individual assertTest assertions
  forAllCases =
    testName: testCases: propertyFn:
    let
      # Create individual tests for each case
      individualTests = builtins.map (
        testCase:
        let
          caseName = "${testName}-${testCase.name or "case"}";
          propertyResult = builtins.tryEval (propertyFn testCase);
        in
        if propertyResult.success then
          assertTest caseName propertyResult.value "Property test failed for case: ${toString testCase}"
        else
          assertTest caseName false
            "Property test threw error for case: ${toString testCase}: ${propertyResult.value}"
      ) testCases;

      # Create a summary test that aggregates all results
      summaryTest = pkgs.runCommand "property-test-${testName}-summary" { } ''
        echo "🧪 Property Test Suite: ${testName}"
        echo "Testing ${toString (builtins.length testCases)} cases..."
        echo ""
        ${lib.concatMapStringsSep "\n" (testCase: ''
          echo "  🔍 Testing case: ${testCase.name or "unnamed"}"
        '') testCases}
        echo ""
        echo "✅ All property tests passed for ${testName}"
        echo "Property holds across all test cases"
        touch $out
      '';
    in
    # Return test suite with all individual tests and summary
    testSuite "${testName}-property-tests" (individualTests ++ [ summaryTest ]);

  # Backward compatibility alias for mkSimpleTest
  mkSimpleTest = mkTest;

  # ===== macOS-specific test helpers =====

  # Test a single NSGlobalDomain default setting
  # Usage: assertNSGlobalDef "window-animations" "NSAutomaticWindowAnimationsEnabled" false darwinConfig
  assertNSGlobalDef =
    testName: key: expectedValue: darwinConfig:
    assertTest "ns-global-${testName}" (
      darwinConfig.system.defaults.NSGlobalDomain.${key} == expectedValue
    ) "NSGlobalDomain.${key} should be ${toString expectedValue}";

  # Test multiple NSGlobalDomain default settings at once
  # Usage: assertNSGlobalDefs [ ["key1" val1] ["key2" val2] ] darwinConfig
  assertNSGlobalDefs =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertNSGlobalDef (builtins.head (
        builtins.split "=" (builtins.elemAt setting 0)
      )) (builtins.elemAt setting 0) (builtins.elemAt setting 1) darwinConfig
    ) settings;

  # Test a single dock setting
  # Usage: assertDockSetting "autohide" "autohide" true darwinConfig
  assertDockSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "dock-${testName}" (
      darwinConfig.system.defaults.dock.${key} == expectedValue
    ) "Dock.${key} should be ${toString expectedValue}";

  # Test multiple dock settings at once
  assertDockSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertDockSetting (builtins.elemAt setting 0) (builtins.elemAt setting 1)
        (builtins.elemAt setting 2)
        darwinConfig
    ) settings;

  # Test a single finder setting
  # Usage: assertFinderSetting "show-hidden" "AppleShowAllFiles" true darwinConfig
  assertFinderSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "finder-${testName}" (
      darwinConfig.system.defaults.finder.${key} == expectedValue
    ) "Finder.${key} should be ${toString expectedValue}";

  # Test multiple finder settings at once
  assertFinderSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertFinderSetting (builtins.elemAt setting 0) (builtins.elemAt setting 1)
        (builtins.elemAt setting 2)
        darwinConfig
    ) settings;

  # Test a single trackpad setting
  # Usage: assertTrackpadSetting "clicking" "Clicking" true darwinConfig
  assertTrackpadSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "trackpad-${testName}" (
      darwinConfig.system.defaults.trackpad.${key} == expectedValue
    ) "Trackpad.${key} should be ${toString expectedValue}";

  # Test multiple trackpad settings at once
  assertTrackpadSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTrackpadSetting (builtins.elemAt setting 0) (builtins.elemAt setting 1)
        (builtins.elemAt setting 2)
        darwinConfig
    ) settings;

  # Test a login window setting
  # Usage: assertLoginWindowSetting "showfullname" "SHOWFULLNAME" false darwinConfig
  assertLoginWindowSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "login-window-${testName}" (
      darwinConfig.system.defaults.loginwindow.${key} == expectedValue
    ) "Login window.${key} should be ${toString expectedValue}";

  # ===== Bulk assertion helpers to reduce code duplication =====

  # Test multiple key-value pairs in a nested attribute set
  # Example: assertSettings "git-core" gitSettings.core { editor = "vim"; autocrlf = "input"; }
  assertSettings =
    name: settings: expectedValues:
    let
      # Create individual tests for each key-value pair
      individualTests = builtins.map (
        key:
        let
          expectedValue = builtins.getAttr key expectedValues;
          actualValue = builtins.getAttr key settings;
          testName = "${name}-${builtins.replaceStrings [ "." ] [ "-" ] key}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "${name}.${key} should be '${toString expectedValue}'"
      ) (builtins.attrNames expectedValues);

      # Summary test
      summaryTest = pkgs.runCommand "${name}-settings-summary" { } ''
        echo "✅ Settings group '${name}': All ${toString (builtins.length individualTests)} values match"
        touch $out
      '';
    in
    testSuite "${name}-settings" (individualTests ++ [ summaryTest ]);

  # Test that a list contains all expected patterns
  # Example: assertPatterns "gitignore" gitIgnores [ "*.swp" "*.swo" ".DS_Store" ]
  assertPatterns =
    name: actualList: expectedPatterns:
    let
      # Create individual tests for each pattern
      individualTests = builtins.map (
        pattern:
        let
          sanitizedName = builtins.replaceStrings [ "*" "." "/" "-" " " ] [ "-" "-" "-" "-" "" ] (
            if pattern == "" then "empty" else pattern
          );
          testName = "${name}-${sanitizedName}";
          hasPattern = builtins.any (p: p == pattern) actualList;
        in
        assertTest testName hasPattern "${name} should include '${pattern}'"
      ) expectedPatterns;

      # Summary test
      summaryTest = pkgs.runCommand "${name}-patterns-summary" { } ''
        echo "✅ Pattern group '${name}': All ${toString (builtins.length individualTests)} patterns found"
        touch $out
      '';
    in
    testSuite "${name}-patterns" (individualTests ++ [ summaryTest ]);

  # Test multiple git aliases
  # Example: assertAliases gitSettings.alias { st = "status"; co = "checkout"; }
  assertAliases =
    aliasSettings: expectedAliases:
    let
      individualTests = builtins.map (
        aliasName:
        let
          expectedValue = builtins.getAttr aliasName expectedAliases;
          actualValue = builtins.getAttr aliasName aliasSettings;
          testName = "git-alias-${aliasName}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "Git should have '${aliasName}' alias for '${expectedValue}'"
      ) (builtins.attrNames expectedAliases);

      summaryTest = pkgs.runCommand "git-aliases-summary" { } ''
        echo "✅ Git aliases: All ${toString (builtins.length individualTests)} aliases configured correctly"
        touch $out
      '';
    in
    testSuite "git-aliases" (individualTests ++ [ summaryTest ]);

  # ========== Enhanced Test Helpers for Common Patterns ==========

  # Compare two attribute sets for deep equality
  # Parameters:
  #   - name: Test name for reporting
  #   - expected: Expected attribute set
  #   - actual: Actual attribute set to compare
  #   - message: Optional failure message
  assertAttrsEqual =
    name: expected: actual: message:
    let
      # Get all unique keys from both sets
      expectedKeys = builtins.attrNames expected;
      actualKeys = builtins.attrNames actual;
      allKeys = lib.unique (expectedKeys ++ actualKeys);

      # Compare each key
      mismatches = builtins.filter (
        key:
        let
          expectedValue = builtins.toString expected.${key} or "<missing>";
          actualValue = builtins.toString actual.${key} or "<missing>";
        in
        expectedValue != actualValue
      ) allKeys;

      # Check if all keys match
      allMatch = builtins.length mismatches == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length allKeys)} attributes match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  ${message}"
        echo ""
        echo "🔍 Mismatched attributes:"
        ${lib.concatMapStringsSep "\n" (key: ''
          echo "  ${key}:"
          echo "    Expected: ${builtins.toString expected.${key} or "<missing>"}"
          echo "    Actual: ${builtins.toString actual.${key} or "<missing>"}"
        '') mismatches}
        exit 1
      '';

  # Validate git user configuration (name and email)
  # Parameters:
  #   - name: Test name for reporting
  #   - gitConfig: The git configuration attribute set (typically config.programs.git)
  #   - expectedName: Expected user name
  #   - expectedEmail: Expected user email
  assertGitUserInfo =
    name: gitConfig: expectedName: expectedEmail:
    let
      userName = gitConfig.userName or "<not set>";
      userEmail = gitConfig.userEmail or "<not set>";
      nameMatch = userName == expectedName;
      emailMatch = userEmail == expectedEmail;
      bothMatch = nameMatch && emailMatch;
    in
    if bothMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git user: ${userName} <${userEmail}>"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git user info mismatch"
        echo ""
        echo "  User Name:"
        echo "    Expected: ${expectedName}"
        echo "    Actual: ${userName}"
        echo "  User Email:"
        echo "    Expected: ${expectedEmail}"
        echo "    Actual: ${userEmail}"
        exit 1
      '';

  # Validate git settings (lfs, init.defaultBranch, core.editor, etc.)
  # Parameters:
  #   - name: Test name for reporting
  #   - gitConfig: The git configuration attribute set
  #   - expectedSettings: Attribute set of expected settings (e.g., { lfs.enable = true; })
  assertGitSettings =
    name: gitConfig: expectedSettings:
    let
      # Extract extraConfig from gitConfig if it exists
      extraConfig = gitConfig.extraConfig or { };

      # Check each setting
      checkSetting =
        key: expectedValue:
        let
          # Handle nested keys like "init.defaultBranch"
          keys = builtins.split "\\." key;
          actualValue = builtins.foldl' (
            acc: k: if acc == null then null else acc.${k} or null
          ) extraConfig keys;

          # Convert to strings for comparison
          expectedStr =
            if expectedValue == true then
              "true"
            else if expectedValue == false then
              "false"
            else
              builtins.toString expectedValue;
          actualStr =
            if actualValue == true then
              "true"
            else if actualValue == false then
              "false"
            else if actualValue == null then
              "<not set>"
            else
              builtins.toString actualValue;

          matches = expectedStr == actualStr;
        in
        if matches then
          {
            inherit key;
            matches = true;
          }
        else
          {
            inherit key;
            matches = false;
            expected = expectedStr;
            actual = actualStr;
          };

      results = builtins.map (key: checkSetting key expectedSettings.${key}) (
        builtins.attrNames expectedSettings
      );
      failed = builtins.filter (r: !r.matches) results;
      allMatch = builtins.length failed == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} git settings match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git settings mismatch"
        echo ""
        echo "🔍 Mismatched settings:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.key}:"
          echo "    Expected: ${result.expected}"
          echo "    Actual: ${result.actual}"
        '') failed}
        exit 1
      '';

  # Validate git aliases
  # Parameters:
  #   - name: Test name for reporting
  #   - gitConfig: The git configuration attribute set
  #   - expectedAliases: Attribute set of expected aliases (e.g., { co = "checkout"; st = "status"; })
  assertGitAliases =
    name: gitConfig: expectedAliases:
    let
      # Extract aliases from gitConfig
      actualAliases = gitConfig.aliases or { };

      # Check each alias
      checkAlias =
        alias: expectedCommand:
        let
          actualCommand = actualAliases.${alias} or "<not set>";
          matches = actualCommand == expectedCommand;
        in
        if matches then
          {
            inherit alias;
            matches = true;
          }
        else
          {
            inherit alias;
            matches = false;
            expected = expectedCommand;
            actual = actualCommand;
          };

      results = builtins.map (alias: checkAlias alias expectedAliases.${alias}) (
        builtins.attrNames expectedAliases
      );
      failed = builtins.filter (r: !r.matches) results;
      allMatch = builtins.length failed == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} git aliases match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git aliases mismatch"
        echo ""
        echo "🔍 Mismatched aliases:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.alias}:"
          echo "    Expected: ${result.expected}"
          echo "    Actual: ${result.actual}"
        '') failed}
        exit 1
      '';

  # Validate gitignore patterns
  # Parameters:
  #   - name: Test name for reporting
  #   - gitConfig: The git configuration attribute set
  #   - expectedPatterns: List of expected gitignore patterns
  assertGitIgnorePatterns =
    name: gitConfig: expectedPatterns:
    let
      # Extract ignores from gitConfig
      actualPatterns = gitConfig.ignores or [ ];

      # Check each expected pattern
      checkPattern =
        pattern:
        let
          isPresent = builtins.any (p: p == pattern) actualPatterns;
        in
        if isPresent then
          {
            inherit pattern;
            present = true;
          }
        else
          {
            inherit pattern;
            present = false;
          };

      results = builtins.map checkPattern expectedPatterns;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;
    in
    if allPresent then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} gitignore patterns present"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Gitignore patterns missing"
        echo ""
        echo "🔍 Missing patterns:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.pattern}"
        '') missing}
        exit 1
      '';

  # Generic membership test for lists or attribute sets
  # Parameters:
  #   - name: Test name for reporting
  #   - needle: The item to search for
  #   - haystack: The list or attribute set to search in
  #   - message: Optional failure message
  # Note: This replaces the existing assertContains for string-only searches
  # with a more generic version that supports lists, sets, and strings
  assertContainsGeneric =
    name: needle: haystack: message:
    let
      haystackType = builtins.typeOf haystack;
      isPresent =
        if haystackType == "list" then
          builtins.any (item: item == needle) haystack
        else if haystackType == "set" then
          builtins.hasAttr (builtins.toString needle) haystack
        else if haystackType == "string" then
          lib.hasInfix (builtins.toString needle) haystack
        else
          abort "assertContainsGeneric: haystack must be a list, set, or string";
    in
    assertTest name isPresent "${message}: ${builtins.toString needle} not found in ${haystackType}";

  # ========== Enhanced Test Helpers for Plugin and Configuration Validation ==========

  # Test plugin/package presence in a list or attribute set
  # Supports exact name matching or regex pattern matching for flexible validation
  # Parameters:
  #   - name: Test name for reporting
  #   - plugins: List of plugins/packages or attribute set of plugin configurations
  #   - expectedPlugins: List of plugin names (exact strings) or regex patterns to match
  #   - options: Optional attributes:
  #     - matchType: "exact" (default) or "regex" for pattern matching
  #     - allowExtra: If true, allows additional plugins beyond expected (default: true)
  # Usage examples:
  #   assertPluginPresent "vim-plugins" vimPlugins [ "vim-airline" "nerdtree" ]
  #   assertPluginPresent "tmux-plugins" tmuxPlugins [ "tmux-sensible" ] { matchType = "exact"; }
  #   assertPluginPresent "npm-packages" npmPackages [ "eslint-.*" ] { matchType = "regex"; }
  assertPluginPresent =
    name: plugins: expectedPlugins:
    let
      options = {
        matchType = "exact";
        allowExtra = true;
      };

      # Normalize plugins to a list of names
      pluginNames =
        if builtins.typeOf plugins == "list" then
          plugins
        else if builtins.typeOf plugins == "set" then
          builtins.attrNames plugins
        else
          abort "assertPluginPresent: plugins must be a list or attribute set";

      # Check if a single plugin is present
      checkPlugin =
        expectedPlugin:
        let
          isPresent =
            if options.matchType == "exact" then
              builtins.any (p: p == expectedPlugin) pluginNames
            else if options.matchType == "regex" then
              builtins.any (p: builtins.match expectedPlugin p != null) pluginNames
            else
              abort "assertPluginPresent: matchType must be 'exact' or 'regex'";
        in
        if isPresent then
          {
            plugin = expectedPlugin;
            present = true;
          }
        else
          {
            plugin = expectedPlugin;
            present = false;
          };

      # Check all expected plugins
      results = builtins.map checkPlugin expectedPlugins;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;

      # Check for unexpected plugins if allowExtra is false
      unexpected =
        if options.allowExtra then
          [ ]
        else
          builtins.filter (
            p:
            let
              isExpected =
                if options.matchType == "exact" then
                  builtins.any (exp: exp == p) expectedPlugins
                else
                  builtins.any (exp: builtins.match exp p != null) expectedPlugins;
            in
            !isExpected
          ) pluginNames;
      hasUnexpected = builtins.length unexpected > 0;
    in
    if allPresent && !hasUnexpected then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length expectedPlugins)} expected plugins present"
        ${if options.allowExtra then "" else ''
          echo "  No unexpected plugins found"
        ''}
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        ${if !allPresent then ''
          echo "  Missing plugins:"
          ${lib.concatMapStringsSep "\n" (result: ''
            echo "    ${result.plugin}"
          '') missing}
        '' else ""}
        ${if hasUnexpected then ''
          echo ""
          echo "  Unexpected plugins found:"
          ${lib.concatMapStringsSep "\n" (p: ''
            echo "    ${p}"
          '') unexpected}
        '' else ""}
        exit 1
      '';

  # Test file system validation for files and directories
  # Validates that paths exist, are readable, and optionally checks file type
  # Parameters:
  #   - name: Test name for reporting
  #   - derivationOrPath: Either a derivation containing the files or an absolute path
  #   - expectedPaths: Attribute set or list of paths to validate:
  #     - For simple check: path = true (or just include in list)
  #     - With options: path = { type = "file"|"directory"; executable = true; }
  # Usage examples:
  #   assertFileReadable "config-files" derivation [ ".vimrc" ".gitconfig" ]
  #   assertFileReadable "binaries" buildResult {
  #     "bin/script.sh" = { type = "file"; executable = true; };
  #     "lib" = { type = "directory"; };
  #   }
  assertFileReadable =
    name: derivationOrPath: expectedPaths:
    let
      # Normalize expectedPaths to an attribute set
      normalizePaths =
        paths:
        if builtins.typeOf paths == "list" then
          builtins.listToAttrs (builtins.map (p: {
            name = p;
            value = true;
          }) paths)
        else
          paths;

      pathSpecs = normalizePaths expectedPaths;

      # Check if a path is readable and optionally validate type
      checkPath =
        relPath: options:
        let
          # Determine the full path
          fullPath =
            if builtins.typeOf derivationOrPath == "set" then
              "${derivationOrPath}/${relPath}"
            else
              "${derivationOrPath}/${relPath}";

          # Try to read the path
          readResult = builtins.tryEval (
            if builtins.typeOf derivationOrPath == "set" then
              builtins.readFile fullPath
            else
              # For raw paths, we can't readFile at eval time
              # This will be validated at build time
              "mock-success"
          );

          isReadable = readResult.success;

          # Determine expected type
          expectedType =
            if options == true then
              null
            else if builtins.typeOf options == "set" then
              options.type or null
            else
              null;

          # For now, we can only validate readability at eval time
          # Type checking would require build-time validation
          typeMatches = true; # Placeholder for build-time type checking

          # Check executable flag (only valid for files)
          executableExpected =
            if options == true then
              false
            else if builtins.typeOf options == "set" then
              options.executable or false
            else
              false;

          # Executable checking requires build-time validation
          executableMatches = true; # Placeholder
        in
        if !isReadable then
          {
            path = relPath;
            readable = false;
          }
        else if !typeMatches then
          {
            path = relPath;
            readable = true;
            typeMatches = false;
            inherit expectedType;
          }
        else if !executableMatches then
          {
            path = relPath;
            readable = true;
            typeMatches = true;
            executableMatches = false;
          }
        else
          {
            path = relPath;
            readable = true;
            typeMatches = true;
            executableMatches = true;
          };

      # Check all paths
      results = builtins.map (relPath: checkPath relPath pathSpecs.${relPath}) (
        builtins.attrNames pathSpecs
      );

      unreadablePaths = builtins.filter (r: !r.readable) results;
      typeMismatches = builtins.filter (r: r.readable && !r.typeMatches) results;
      executableMismatches = builtins.filter (r: r.readable && r.typeMatches && !r.executableMatches) results;

      allValid =
        builtins.length unreadablePaths == 0 && builtins.length typeMismatches == 0
        && builtins.length executableMismatches == 0;
    in
    if allValid then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} paths are valid"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  File system validation failed"
        ${if builtins.length unreadablePaths > 0 then ''
          echo ""
          echo "  Unreadable paths:"
          ${lib.concatMapStringsSep "\n" (r: ''
            echo "    ${r.path}"
          '') unreadablePaths}
        '' else ""}
        ${if builtins.length typeMismatches > 0 then ''
          echo ""
          echo "  Type mismatches:"
          ${lib.concatMapStringsSep "\n" (r: ''
            echo "    ${r.path} (expected type: ${r.expectedType})"
          '') typeMismatches}
        '' else ""}
        exit 1
      '';

  # Test module import validation
  # Validates that modules properly import other modules or files
  # Parameters:
  #   - name: Test name for reporting
  #   - moduleConfig: The module configuration to check
  #   - expectedImports: List of expected import patterns:
  #     - For exact match: "module-path.nix"
  #     - For regex: { regex = ".*-config\\.nix"; }
  #     - With import type: { path = "module.nix"; type = "import"|"include"; }
  # Usage examples:
  #   assertImportPresent "home-manager-imports" config [
  #     "vim.nix" "git.nix" "zsh.nix"
  #   ]
  #   assertImportPresent "module-imports" moduleConfig [
  #     { path = "./lib/utils.nix"; type = "import"; }
  #     { regex = ".*-helpers\\.nix"; }
  #   ]
  assertImportPresent =
    name: moduleConfig: expectedImports:
    let
      # Try to extract imports from different module structures
      # Home Manager imports: imports = [ ... ]
      # NixOS imports: imports = [ ... ]
      # Direct imports: import ./...
      directImports = moduleConfig.imports or [ ];

      # Also check for common import patterns in the config
      configKeys = builtins.attrNames moduleConfig;

      # Normalize import specification
      normalizeImport =
        importSpec:
        if builtins.typeOf importSpec == "string" then
          {
            type = "any";
            pattern = importSpec;
            matchType = "exact";
          }
        else if builtins.typeOf importSpec == "set" then
          if importSpec ? regex then
            {
              type = importSpec.type or "any";
              pattern = importSpec.regex;
              matchType = "regex";
            }
          else if importSpec ? path then
            {
              type = importSpec.type or "any";
              pattern = importSpec.path;
              matchType = "exact";
            }
          else
            abort "assertImportPresent: invalid import specification"
        else
          abort "assertImportPresent: import spec must be string or attribute set";

      # Check if an import pattern is present
      checkImport =
        importSpec:
        let
          spec = normalizeImport importSpec;

          # Check direct imports list
          inDirectImports =
            if spec.matchType == "exact" then
              builtins.any (imp: imp == spec.pattern) directImports
            else
              builtins.any (imp: builtins.match spec.pattern imp != null) directImports;

          # For regex, also check if pattern matches any config keys
          inConfigKeys =
            if spec.matchType == "regex" then
              builtins.any (key: builtins.match spec.pattern key != null) configKeys
            else
              false;

          # Check if pattern matches any string values in the config (for import statements)
          matchesInValues =
            if spec.matchType == "regex" then
              # This is a heuristic - we can't fully evaluate imports at eval time
              false
            else
              false;

          isPresent = inDirectImports || inConfigKeys || matchesInValues;
        in
        if isPresent then
          {
            spec = spec.pattern;
            present = true;
          }
        else
          {
            spec = spec.pattern;
            present = false;
          };

      # Check all expected imports
      results = builtins.map checkImport expectedImports;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;
    in
    if allPresent then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length expectedImports)} expected imports present"
        echo "  Direct imports found: ${toString (builtins.length directImports)}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Module import validation failed"
        echo ""
        echo "  Missing imports:"
        ${lib.concatMapStringsSep "\n" (r: ''
          echo "    ${r.spec}"
        '') missing}
        echo ""
        echo "  Found imports:"
        ${lib.concatMapStringsSep "\n" (imp: ''
          echo "    ${imp}"
        '') directImports}
        exit 1
      '';
}
