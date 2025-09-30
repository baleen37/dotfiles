# Test Builders for Comprehensive Testing Framework
# Provides builder functions for all test layers: unit, contract, integration, e2e

{ pkgs ? import <nixpkgs> { }, lib, ... }:

let
  # Import existing test system
  testSystem = import ./test-system.nix { inherit pkgs; };

  # Import platform detection for cross-platform testing
  platformDetection = import ./platform-detection.nix { inherit lib; };

in
{

  # Unit Test Builders (using nix-unit integration)
  unit = {
    # Build a nix-unit test case
    mkNixUnitTest = { name, expr, expected, description ? "" }: {
      inherit name expr expected description;
      type = "unit";
      framework = "nix-unit";
    };

    # Build a test suite using nixpkgs lib.runTests
    mkLibTestSuite = { name, tests }: {
      inherit name;
      type = "unit";
      framework = "lib.runTests";
      testCases = tests;
      builder = lib.runTests tests;
    };

    # Build a function test
    mkFunctionTest = { name, func, inputs, expected, description ? "" }: {
      inherit name description;
      type = "unit";
      framework = "function";
      testCase = {
        expr = func inputs;
        inherit expected;
      };
    };

    # Build module unit tests
    mkModuleTest = { name, modulePath, config, expected, description ? "" }: {
      inherit name description;
      type = "unit";
      framework = "module";
      testCase = {
        expr = (import modulePath { inherit config lib pkgs; }).config;
        inherit expected;
      };
    };
  };

  # Contract Test Builders (interface validation)
  contract = {
    # Build a module interface contract test
    mkInterfaceTest = { name, modulePath, requiredExports, description ? "" }: {
      inherit name description;
      type = "contract";
      framework = "interface";
      testCase = {
        modulePath = modulePath;
        requiredExports = requiredExports;
        validator = exports:
          builtins.all (required: builtins.hasAttr required exports) requiredExports;
      };
    };

    # Build a flake output contract test
    mkFlakeOutputTest = { name, outputPath, expectedSchema, description ? "" }: {
      inherit name description;
      type = "contract";
      framework = "flake-output";
      testCase = {
        outputPath = outputPath;
        expectedSchema = expectedSchema;
      };
    };

    # Build a platform compatibility contract test
    mkPlatformContractTest = { name, platforms, testFunction, description ? "" }: {
      inherit name description;
      type = "contract";
      framework = "platform";
      testCase = {
        platforms = platforms;
        testFunction = testFunction;
        validator = platform:
          if builtins.elem platform platforms
          then testFunction platform
          else throw "Platform ${platform} not supported";
      };
    };

    # Build an API contract test (for shell commands)
    mkAPIContractTest = { name, command, expectedInterface, description ? "" }: {
      inherit name description;
      type = "contract";
      framework = "api";
      testCase = {
        command = command;
        expectedInterface = expectedInterface;
      };
    };
  };

  # Integration Test Builders (workflow testing)
  integration = {
    # Build a BATS integration test
    mkBatsTest = { name, testScript, setup ? "", teardown ? "", description ? "" }: {
      inherit name description;
      type = "integration";
      framework = "bats";
      testCase = {
        inherit setup teardown;
        script = testScript;
      };
    };

    # Build a build workflow integration test
    mkBuildIntegrationTest = { name, buildTargets, validationSteps, description ? "" }: {
      inherit name description;
      type = "integration";
      framework = "build-workflow";
      testCase = {
        buildTargets = buildTargets;
        validationSteps = validationSteps;
      };
    };

    # Build a cross-platform integration test
    mkCrossPlatformTest = { name, platforms, testSteps, description ? "" }: {
      inherit name description;
      type = "integration";
      framework = "cross-platform";
      testCase = {
        platforms = platforms;
        testSteps = testSteps;
        runner = platform: builtins.map (step: step platform) testSteps;
      };
    };

    # Build a service integration test
    mkServiceIntegrationTest = { name, services, testScenarios, description ? "" }: {
      inherit name description;
      type = "integration";
      framework = "service";
      testCase = {
        services = services;
        testScenarios = testScenarios;
      };
    };
  };

  # E2E Test Builders (full system testing)
  e2e = {
    # Build a NixOS VM test using testers.runNixOSTest
    mkNixOSVMTest = { name, nodes, testScript, description ? "" }: {
      inherit name description;
      type = "e2e";
      framework = "nixos-vm";
      testCase = {
        inherit nodes testScript;
        builder = pkgs.testers.runNixOSTest {
          inherit name nodes testScript;
        };
      };
    };

    # Build a user workflow E2E test
    mkUserWorkflowTest = { name, workflow, expectedOutcome, description ? "" }: {
      inherit name description;
      type = "e2e";
      framework = "user-workflow";
      testCase = {
        workflow = workflow;
        expectedOutcome = expectedOutcome;
      };
    };

    # Build a fresh installation E2E test
    mkFreshInstallTest = { name, installConfig, validationSteps, description ? "" }: {
      inherit name description;
      type = "e2e";
      framework = "fresh-install";
      testCase = {
        installConfig = installConfig;
        validationSteps = validationSteps;
      };
    };

    # Build a deployment E2E test
    mkDeploymentTest = { name, deploymentTarget, deploymentSteps, validationSteps, description ? "" }: {
      inherit name description;
      type = "e2e";
      framework = "deployment";
      testCase = {
        deploymentTarget = deploymentTarget;
        deploymentSteps = deploymentSteps;
        validationSteps = validationSteps;
      };
    };
  };

  # Test Suite Builders (combine multiple tests)
  suite = {
    # Build a comprehensive test suite
    mkTestSuite = { name, tests, config ? { }, description ? "" }: {
      inherit name description;
      type = "suite";
      testCases = tests;
      config = {
        parallel = config.parallel or true;
        timeout = config.timeout or 300;
        coverage = config.coverage or true;
        reporter = config.reporter or "console";
      } // config;
    };

    # Build a platform-specific test suite
    mkPlatformSuite = { name, platform, tests, description ? "" }: {
      inherit name platform description;
      type = "platform-suite";
      testCases = tests;
      platformInfo = platformDetection.detectPlatform or { };
    };

    # Build a layer-specific test suite (all tests of one type)
    mkLayerSuite = { name, layer, tests, description ? "" }:
      if !builtins.elem layer [ "unit" "contract" "integration" "e2e" ]
      then throw "Invalid test layer: ${layer}. Must be one of: unit, contract, integration, e2e"
      else {
        inherit name layer description;
        type = "layer-suite";
        testCases = tests;
      };
  };

  # Test Validation and Utilities
  validators = {
    # Validate test case structure
    validateTestCase = testCase:
      let
        hasRequiredFields = builtins.all (field: builtins.hasAttr field testCase)
          [ "name" "type" "framework" ];
      in
      if !hasRequiredFields
      then throw "Test case missing required fields: name, type, framework"
      else testCase;

    # Validate test suite structure
    validateTestSuite = suite:
      let
        hasRequiredFields = builtins.all (field: builtins.hasAttr field suite)
          [ "name" "type" "testCases" ];
        validTestCases = builtins.all validators.validateTestCase suite.testCases;
      in
      if !hasRequiredFields
      then throw "Test suite missing required fields: name, type, testCases"
      else if !validTestCases
      then throw "Test suite contains invalid test cases"
      else suite;

    # Validate platform compatibility
    validatePlatform = platform:
      if !builtins.elem platform [ "darwin-x86_64" "darwin-aarch64" "nixos-x86_64" "nixos-aarch64" ]
      then throw "Unsupported platform: ${platform}"
      else platform;
  };

  # Test Runner Integration
  runners = {
    # Create a test runner for a specific framework
    mkFrameworkRunner = framework:
      if framework == "nix-unit" then {
        command = "nix-unit";
        args = [ "--flake" ];
        supported = true;
      }
      else if framework == "lib.runTests" then {
        command = "nix";
        args = [ "eval" "--json" ];
        supported = true;
      }
      else if framework == "bats" then {
        command = "bats";
        args = [ ];
        supported = true;
      }
      else if framework == "nixos-vm" then {
        command = "nix";
        args = [ "build" ];
        supported = true;
      }
      else {
        command = null;
        args = [ ];
        supported = false;
      };

    # Get the appropriate runner for a test case
    getRunner = testCase: runners.mkFrameworkRunner testCase.framework;
  };

  # Compatibility with existing test system
  legacy = {
    inherit (testSystem) mkTestApp mkTestApps testUtils testCategories testConfig;
  };

  # Export version and metadata
  version = "1.0.0";
  description = "Comprehensive test builders for multi-layer testing framework";
  supportedFrameworks = [ "nix-unit" "lib.runTests" "bats" "nixos-vm" "interface" "api" ];
  supportedLayers = [ "unit" "contract" "integration" "e2e" ];
}
