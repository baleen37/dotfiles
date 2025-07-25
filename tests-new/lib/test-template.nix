{ pkgs, lib ? pkgs.lib }:
let
  testHelpers = import ./test-helpers-v2.nix { inherit pkgs lib; };
  testFixtures = import ./test-fixtures.nix { inherit pkgs lib; };
  performanceUtils = import ./performance-utils.nix { inherit pkgs lib; };

  # Core test template - for fundamental functionality tests
  coreTestTemplate = {
    name,
    description,
    fixtures ? {},
    systemState ? testFixtures.systemFixtures.cleanSystem,
    environment ? testFixtures.environmentFixtures.development,
    setup ? "",
    teardown ? "",
    tests
  }: testHelpers.createTestScript {
    name = "core-${name}";
    script = ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply fixtures and system state
      ${testFixtures.setupTestEnvironmentWithFixtures {
        inherit fixtures systemState environment;
      }}

      # Custom setup
      ${setup}

      # Run core test suite
      ${testHelpers.testSuite "Core: ${name}" description ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (testName: testBody:
          testHelpers.testCase testName testBody
        ) tests)}
      ''}

      # Custom teardown
      ${teardown}

      # Enhanced cleanup
      ${testHelpers.enhancedCleanup}
    '';
  };

  # Integration test template - for testing component interactions
  integrationTestTemplate = {
    name,
    description,
    fixtures ? {},
    systemState ? testFixtures.systemFixtures.builtSystem,
    environment ? testFixtures.environmentFixtures.development,
    dependencies ? [],
    setup ? "",
    teardown ? "",
    testGroups
  }: testHelpers.createTestScript {
    name = "integration-${name}";
    script = ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply fixtures and system state
      ${testFixtures.setupTestEnvironmentWithFixtures {
        inherit fixtures systemState environment;
      }}

      # Check dependencies
      ${lib.concatStringsSep "\n" (map (dep:
        testHelpers.assertCommand "command -v ${dep} >/dev/null" "Dependency available: ${dep}"
      ) dependencies)}

      # Custom setup
      ${setup}

      # Run integration test suite
      ${testHelpers.testSuite "Integration: ${name}" description ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (groupName: groupTests:
          testHelpers.testGroup groupName ''
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (testName: testBody:
              testHelpers.testCase testName testBody
            ) groupTests)}
          ''
        ) testGroups)}
      ''}

      # Custom teardown
      ${teardown}

      # Enhanced cleanup
      ${testHelpers.enhancedCleanup}
    '';
  };

  # End-to-end test template - for full workflow testing
  e2eTestTemplate = {
    name,
    description,
    fixtures ? testFixtures.configFixtures,
    systemState ? testFixtures.systemFixtures.cleanSystem,
    environment ? testFixtures.environmentFixtures.development,
    prerequisites ? [],
    setup ? "",
    teardown ? "",
    scenarios
  }: testHelpers.createTestScript {
    name = "e2e-${name}";
    script = ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply full fixture set for E2E testing
      ${testFixtures.setupTestEnvironmentWithFixtures {
        inherit fixtures systemState environment;
      }}

      # Validate prerequisites
      ${lib.concatStringsSep "\n" (map (prereq:
        if builtins.isString prereq then
          testHelpers.assertCommand "command -v ${prereq} >/dev/null" "Prerequisite available: ${prereq}"
        else
          testHelpers.assertExists prereq.path prereq.description
      ) prerequisites)}

      # Custom setup
      ${setup}

      # Run E2E test suite with resource monitoring
      ${performanceUtils.monitorResourceUsage {
        command = testHelpers.testSuite "E2E: ${name}" description ''
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (scenarioName: scenarioConfig:
            testHelpers.testGroup "Scenario: ${scenarioName}" ''
              # Scenario setup
              ${scenarioConfig.setup or ""}

              # Scenario steps
              ${lib.concatStringsSep "\n" (map (step:
                if builtins.isString step then
                  testHelpers.testCase "Step" step
                else
                  testHelpers.testCase step.name step.test
              ) (scenarioConfig.steps or []))}

              # Scenario teardown
              ${scenarioConfig.teardown or ""}
            ''
          ) scenarios)}
        '';
        description = "E2E Test: ${name}";
      }}

      # Custom teardown
      ${teardown}

      # Collect artifacts for E2E tests
      ${testHelpers.collectArtifacts "e2e-${name}"}

      # Enhanced cleanup
      ${testHelpers.enhancedCleanup}
    '';
  };

  # Performance test template - for benchmarking and performance validation
  performanceTestTemplate = {
    name,
    description,
    fixtures ? {},
    systemState ? testFixtures.systemFixtures.cleanSystem,
    environment ? testFixtures.environmentFixtures.development,
    setup ? "",
    teardown ? "",
    benchmarks
  }: testHelpers.createTestScript {
    name = "performance-${name}";
    script = ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply minimal fixtures for performance testing
      ${testFixtures.setupTestEnvironmentWithFixtures {
        inherit fixtures systemState environment;
      }}

      # Custom setup
      ${setup}

      # Run performance test suite
      ${testHelpers.testSuite "Performance: ${name}" description ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (benchmarkName: benchmarkConfig:
          testHelpers.testCase benchmarkName ''
            ${performanceUtils.performanceBenchmark ({
              name = benchmarkName;
            } // benchmarkConfig)}

            # Optional regression check
            ${lib.optionalString (benchmarkConfig ? regressionCheck) ''
              ${performanceUtils.checkPerformanceRegression {
                testName = benchmarkName;
                currentMetric = "$LAST_BENCHMARK_AVG";
                thresholdPercent = benchmarkConfig.regressionCheck.thresholdPercent or 10;
              }}
            ''}
          ''
        ) benchmarks)}
      ''}

      # Generate performance report
      ${performanceUtils.generatePerformanceReport { testSuite = name; }}

      # Custom teardown
      ${teardown}

      # Enhanced cleanup
      ${testHelpers.enhancedCleanup}
    '';
  };

  # Template for testing specific components with mocking
  componentTestTemplate = {
    name,
    description,
    component,
    fixtures ? {},
    mocks ? {},
    setup ? "",
    teardown ? "",
    tests
  }: testHelpers.createTestScript {
    name = "component-${name}";
    script = ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply fixtures
      ${testFixtures.setupTestEnvironmentWithFixtures {
        inherit fixtures;
        systemState = testFixtures.systemFixtures.cleanSystem;
      }}

      # Set up mocks
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (mockName: mockConfig:
        testHelpers.createMockFile {
          path = mockConfig.path;
          content = mockConfig.content;
          permissions = mockConfig.permissions or "644";
        }
      ) mocks)}

      # Custom setup
      ${setup}

      # Import component under test
      COMPONENT_PATH="${component}"

      # Run component tests
      ${testHelpers.testSuite "Component: ${name}" description ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (testName: testBody:
          testHelpers.testCase testName testBody
        ) tests)}
      ''}

      # Custom teardown
      ${teardown}

      # Enhanced cleanup
      ${testHelpers.enhancedCleanup}
    '';
  };

  # Template for regression testing
  regressionTestTemplate = {
    name,
    description,
    baselineCommit ? null,
    fixtures ? {},
    setup ? "",
    teardown ? "",
    tests
  }: testHelpers.createTestScript {
    name = "regression-${name}";
    script = ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply fixtures
      ${testFixtures.setupTestEnvironmentWithFixtures {
        inherit fixtures;
        systemState = testFixtures.systemFixtures.cleanSystem;
      }}

      # Set up baseline if specified
      ${lib.optionalString (baselineCommit != null) ''
        echo "Testing against baseline: ${baselineCommit}"
        export BASELINE_COMMIT="${baselineCommit}"
      ''}

      # Custom setup
      ${setup}

      # Run regression tests
      ${testHelpers.testSuite "Regression: ${name}" description ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (testName: testConfig:
          testHelpers.testCase testName ''
            # Run the test command and measure performance
            ${performanceUtils.measureExecutionTime {
              command = testConfig.command;
              description = testName;
            }}

            # Check for regression if baseline exists
            ${lib.optionalString (testConfig ? baseline) ''
              ${performanceUtils.checkPerformanceRegression {
                testName = testName;
                currentMetric = "$LAST_PERF_DURATION_MS";
                thresholdPercent = testConfig.regressionThreshold or 10;
              }}
            ''}

            # Validate output if specified
            ${lib.optionalString (testConfig ? expectedOutput) ''
              ${testHelpers.assertCommandWithOutput testConfig.command testConfig.expectedOutput "Output validation: ${testName}"}
            ''}
          ''
        ) tests)}
      ''}

      # Custom teardown
      ${teardown}

      # Enhanced cleanup
      ${testHelpers.enhancedCleanup}
    '';
  };

  # Template for load/stress testing
  loadTestTemplate = {
    name,
    description,
    fixtures ? {},
    setup ? "",
    teardown ? "",
    loadTests
  }: testHelpers.createTestScript {
    name = "load-${name}";
    script = ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply fixtures
      ${testFixtures.setupTestEnvironmentWithFixtures {
        inherit fixtures;
        systemState = testFixtures.systemFixtures.cleanSystem;
      }}

      # Custom setup
      ${setup}

      # Run load tests
      ${testHelpers.testSuite "Load: ${name}" description ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (testName: testConfig:
          testHelpers.testCase testName ''
            ${performanceUtils.loadTest ({
              name = testName;
            } // testConfig)}
          ''
        ) loadTests)}
      ''}

      # Generate performance report
      ${performanceUtils.generatePerformanceReport { testSuite = "Load-${name}"; }}

      # Custom teardown
      ${teardown}

      # Enhanced cleanup
      ${testHelpers.enhancedCleanup}
    '';
  };

  # Helper function to create test suites with multiple templates
  createTestSuite = { name, description, tests }:
    let
      # Organize tests by type
      coreTests = lib.filterAttrs (n: v: v.type or "core" == "core") tests;
      integrationTests = lib.filterAttrs (n: v: v.type or "core" == "integration") tests;
      e2eTests = lib.filterAttrs (n: v: v.type or "core" == "e2e") tests;
      performanceTests = lib.filterAttrs (n: v: v.type or "core" == "performance") tests;

      # Create test derivations
      testDerivations = {}
        // (lib.mapAttrs (testName: testConfig:
            coreTestTemplate (testConfig // { name = testName; })
          ) coreTests)
        // (lib.mapAttrs (testName: testConfig:
            integrationTestTemplate (testConfig // { name = testName; })
          ) integrationTests)
        // (lib.mapAttrs (testName: testConfig:
            e2eTestTemplate (testConfig // { name = testName; })
          ) e2eTests)
        // (lib.mapAttrs (testName: testConfig:
            performanceTestTemplate (testConfig // { name = testName; })
          ) performanceTests);

    in testDerivations;

in
{
  inherit coreTestTemplate integrationTestTemplate e2eTestTemplate performanceTestTemplate;
  inherit componentTestTemplate regressionTestTemplate loadTestTemplate;
  inherit createTestSuite;

  # Convenience functions for common test patterns
  simpleTest = { name, description, command }:
    coreTestTemplate {
      inherit name description;
      tests = {
        "basic-functionality" = command;
      };
    };

  quickIntegrationTest = { name, description, testGroups }:
    integrationTestTemplate {
      inherit name description testGroups;
    };

  benchmarkTest = { name, description, command, iterations ? 5 }:
    performanceTestTemplate {
      inherit name description;
      benchmarks = {
        "${name}-benchmark" = {
          inherit command iterations;
        };
      };
    };

  # Test template validation
  validateTestTemplate = template: ''
    echo "${testHelpers.colors.cyan}🔍 Validating test template...${testHelpers.colors.reset}"

    # Check required fields
    ${lib.optionalString (!template ? name) ''
      echo "${testHelpers.colors.red}✗ Missing required field: name${testHelpers.colors.reset}"
      exit 1
    ''}

    ${lib.optionalString (!template ? description) ''
      echo "${testHelpers.colors.red}✗ Missing required field: description${testHelpers.colors.reset}"
      exit 1
    ''}

    ${lib.optionalString (!template ? tests && !template ? testGroups && !template ? scenarios && !template ? benchmarks) ''
      echo "${testHelpers.colors.red}✗ Missing test content (tests/testGroups/scenarios/benchmarks)${testHelpers.colors.reset}"
      exit 1
    ''}

    echo "${testHelpers.colors.green}✓ Test template is valid${testHelpers.colors.reset}"
  '';

  # Template metadata for documentation
  templateMetadata = {
    core = {
      description = "For testing fundamental functionality and basic unit tests";
      fields = [ "name" "description" "tests" ];
      optional = [ "fixtures" "systemState" "environment" "setup" "teardown" ];
    };

    integration = {
      description = "For testing component interactions and system integration";
      fields = [ "name" "description" "testGroups" ];
      optional = [ "fixtures" "systemState" "environment" "dependencies" "setup" "teardown" ];
    };

    e2e = {
      description = "For testing complete workflows and user scenarios";
      fields = [ "name" "description" "scenarios" ];
      optional = [ "fixtures" "systemState" "environment" "prerequisites" "setup" "teardown" ];
    };

    performance = {
      description = "For benchmarking and performance validation";
      fields = [ "name" "description" "benchmarks" ];
      optional = [ "fixtures" "systemState" "environment" "setup" "teardown" ];
    };
  };
}
