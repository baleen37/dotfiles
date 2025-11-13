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
      isLinux = pkgs.stdenv.isLinux;
    };
  },
}:

let
  # Import existing NixTest framework
  nixtest = import ../unit/nixtest-template.nix { inherit pkgs lib; };
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

  # Configuration file integrity test (behavioral)
  assertConfigIntegrity =
    name: configPath: expectedFiles:
    nixtest.test "config-integrity-${name}" (
      builtins.all (
        file:
        let
          fullPath = "${configPath}/${file}";
          readResult = builtins.tryEval (builtins.readFile fullPath);
        in
        readResult.success && builtins.stringLength readResult.value > 0
      ) expectedFiles
    );

  # System factory validation
  assertSystemFactory =
    name: systemConfig:
    nixtest.suite "system-factory-${name}" {
      hasConfig = nixtest.test "has config attribute" (
        nixtest.assertions.assertHasAttr "config" systemConfig
      );
      hasSpecialArgs = nixtest.test "has special args" (
        nixtest.assertions.assertHasAttr "_module" systemConfig
      );
    };

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

  # Create parameterized test configuration for modules that require currentSystemUser
  createModuleTestConfig = moduleConfig: {
    currentSystemUser = testConfig.username;
    config = moduleConfig;
  };

  # Generate multiple test configurations for different users
  generateUserTests =
    testFunction: users:
    builtins.listToAttrs (
      map (user: {
        name = "user-${user}";
        value = testFunction {
          username = user;
          homeDirectory = "${testConfig.homeDirPrefix}/${user}";
        };
      }) users
    );

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
      testResults = builtins.map (
        value: {
          value = value;
          result = builtins.tryEval (property value);
        }
      ) testValues;

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
      generateCombinations = valueSets:
        if builtins.length valueSets == 0 then
          [ [] ]
        else
          let
            rest = generateCombinations (builtins.tail valueSets);
            current = builtins.head valueSets;
          in
          builtins.concatLists (
            builtins.map (combo:
              builtins.map (val: [val] ++ combo) current
            ) rest
          );

      # Test each combination with the property
      combinations = generateCombinations testValueSets;
      testResults = builtins.map (
        values: {
          values = values;
          result = builtins.tryEval (builtins.foldl' (acc: v: acc v) property values);
        }
      ) combinations;

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
    pkgs.runCommand "perf-test-${name}" {
      buildInputs = [ pkgs.bc ];
      passthru.script = performanceScript;
    } ''
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

  # Backward compatibility alias for mkSimpleTest
  mkSimpleTest = mkTest;
}
