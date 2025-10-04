# Test Builders Unit Tests
#
# 테스트 빌더 라이브러리의 유닛 테스트 모음
# lib/test-builders.nix에 정의된 테스트 빌더 함수들의 동작을 검증
#
# 테스트 대상:
# - unit: 단위 테스트 빌더 (mkNixUnitTest, mkLibTestSuite, mkFunctionTest, mkModuleTest)
# - contract: 인터페이스 계약 테스트 빌더 (mkInterfaceTest, mkFlakeOutputTest, mkPlatformContractTest, mkAPIContractTest)
# - integration: 통합 테스트 빌더 (mkBatsTest, mkBuildIntegrationTest, mkCrossPlatformTest, mkServiceIntegrationTest)
# - e2e: 종단간 테스트 빌더 (mkNixOSVMTest, mkUserWorkflowTest, mkFreshInstallTest, mkDeploymentTest)
# - suite: 테스트 스위트 빌더 (mkTestSuite, mkPlatformSuite, mkLayerSuite)
# - validators: 테스트 검증 함수들
# - runners: 테스트 프레임워크 실행기
#
# TDD 요구사항: 이 테스트들은 처음에는 실패해야 함 (구현 전)

{ lib, runTests, ... }:

let
  # Import test builders (doesn't exist yet, will fail)
  testBuilders = import ../../../lib/test-builders.nix { inherit lib; };

in
runTests {
  # Test unit test builder validation
  testMkNixUnitTestValidation = {
    expr = testBuilders.unit.mkNixUnitTest {
      name = "validation-test";
      expr = lib.add 5 3;
      expected = 8;
      description = "Test addition function";
    };
    expected = {
      name = "validation-test";
      type = "unit";
      framework = "nix-unit";
      description = "Test addition function";
    };
  };

  testMkLibTestSuiteStructure = {
    expr = testBuilders.unit.mkLibTestSuite {
      name = "lib-test-suite";
      tests = {
        testSimple = {
          expr = 1;
          expected = 1;
        };
      };
    };
    expected = {
      name = "lib-test-suite";
      type = "unit";
      framework = "lib.runTests";
    };
  };

  testMkFunctionTestBuilder = {
    expr = testBuilders.unit.mkFunctionTest {
      name = "function-test";
      func = lib.concatStrings;
      inputs = [
        "hello"
        " "
        "world"
      ];
      expected = "hello world";
    };
    expected = {
      name = "function-test";
      type = "unit";
      framework = "function";
    };
  };

  testMkModuleTestBuilder = {
    expr = testBuilders.unit.mkModuleTest {
      name = "module-test";
      modulePath = "./test-module.nix";
      config = { };
      expected = { };
    };
    expected = {
      name = "module-test";
      type = "unit";
      framework = "module";
    };
  };

  # Test contract test builder validation
  testMkInterfaceTestValidation = {
    expr = testBuilders.contract.mkInterfaceTest {
      name = "interface-validation";
      modulePath = "./modules/shared/example.nix";
      requiredExports = [
        "config"
        "options"
        "imports"
      ];
      description = "Test module interface";
    };
    expected = {
      name = "interface-validation";
      type = "contract";
      framework = "interface";
      description = "Test module interface";
    };
  };

  testMkFlakeOutputTestValidation = {
    expr = testBuilders.contract.mkFlakeOutputTest {
      name = "flake-output-test";
      outputPath = ".#checks";
      expectedSchema = {
        type = "object";
      };
    };
    expected = {
      name = "flake-output-test";
      type = "contract";
      framework = "flake-output";
    };
  };

  testMkPlatformContractTestValidation = {
    expr = testBuilders.contract.mkPlatformContractTest {
      name = "platform-contract";
      platforms = [
        "darwin-x86_64"
        "nixos-x86_64"
      ];
      testFunction = platform: platform != null;
    };
    expected = {
      name = "platform-contract";
      type = "contract";
      framework = "platform";
    };
  };

  testMkAPIContractTestValidation = {
    expr = testBuilders.contract.mkAPIContractTest {
      name = "api-contract";
      command = "git";
      expectedInterface = [
        "--version"
        "--help"
      ];
    };
    expected = {
      name = "api-contract";
      type = "contract";
      framework = "api";
    };
  };

  # Test integration test builder validation
  testMkBatsTestValidation = {
    expr = testBuilders.integration.mkBatsTest {
      name = "bats-integration";
      testScript = ''
        run echo "test"
        assert_success
        assert_output "test"
      '';
      setup = "export TEST_VAR=value";
      teardown = "unset TEST_VAR";
    };
    expected = {
      name = "bats-integration";
      type = "integration";
      framework = "bats";
    };
  };

  testMkBuildIntegrationTestValidation = {
    expr = testBuilders.integration.mkBuildIntegrationTest {
      name = "build-integration";
      buildTargets = [ ".#checks" ];
      validationSteps = [ "test -f result" ];
    };
    expected = {
      name = "build-integration";
      type = "integration";
      framework = "build-workflow";
    };
  };

  testMkCrossPlatformTestValidation = {
    expr = testBuilders.integration.mkCrossPlatformTest {
      name = "cross-platform-integration";
      platforms = [
        "darwin-x86_64"
        "nixos-x86_64"
      ];
      testSteps = [
        (platform: "echo Testing on ${platform}")
        (platform: "nix eval .#checks.${platform}")
      ];
    };
    expected = {
      name = "cross-platform-integration";
      type = "integration";
      framework = "cross-platform";
    };
  };

  testMkServiceIntegrationTestValidation = {
    expr = testBuilders.integration.mkServiceIntegrationTest {
      name = "service-integration";
      services = [ "example-service" ];
      testScenarios = [
        {
          action = "start";
          validate = "is-active";
        }
        {
          action = "stop";
          validate = "is-inactive";
        }
      ];
    };
    expected = {
      name = "service-integration";
      type = "integration";
      framework = "service";
    };
  };

  # Test E2E test builder validation
  testMkNixOSVMTestValidation = {
    expr = testBuilders.e2e.mkNixOSVMTest {
      name = "nixos-vm-test";
      nodes = {
        machine =
          { ... }:
          {
            services.nginx.enable = true;
          };
      };
      testScript = ''
        machine.wait_for_unit("nginx.service")
        machine.succeed("curl http://localhost")
      '';
    };
    expected = {
      name = "nixos-vm-test";
      type = "e2e";
      framework = "nixos-vm";
    };
  };

  testMkUserWorkflowTestValidation = {
    expr = testBuilders.e2e.mkUserWorkflowTest {
      name = "user-workflow";
      workflow = [
        "install system"
        "configure user"
        "test functionality"
      ];
      expectedOutcome = "system fully functional";
    };
    expected = {
      name = "user-workflow";
      type = "e2e";
      framework = "user-workflow";
    };
  };

  testMkFreshInstallTestValidation = {
    expr = testBuilders.e2e.mkFreshInstallTest {
      name = "fresh-install";
      installConfig = {
        user = "testuser";
      };
      validationSteps = [
        "home-manager switch"
        "git --version"
      ];
    };
    expected = {
      name = "fresh-install";
      type = "e2e";
      framework = "fresh-install";
    };
  };

  testMkDeploymentTestValidation = {
    expr = testBuilders.e2e.mkDeploymentTest {
      name = "deployment-test";
      deploymentTarget = "nixos-vm";
      deploymentSteps = [
        "build"
        "switch"
      ];
      validationSteps = [ "systemctl status" ];
    };
    expected = {
      name = "deployment-test";
      type = "e2e";
      framework = "deployment";
    };
  };

  # Test suite builder validation
  testMkTestSuiteValidation = {
    expr = testBuilders.suite.mkTestSuite {
      name = "comprehensive-suite";
      tests = [ ];
      config = {
        parallel = true;
        timeout = 600;
        coverage = true;
        reporter = "json";
      };
    };
    expected = {
      name = "comprehensive-suite";
      type = "suite";
      config.parallel = true;
      config.timeout = 600;
    };
  };

  testMkPlatformSuiteValidation = {
    expr = testBuilders.suite.mkPlatformSuite {
      name = "darwin-suite";
      platform = "darwin-x86_64";
      tests = [ ];
    };
    expected = {
      name = "darwin-suite";
      platform = "darwin-x86_64";
      type = "platform-suite";
    };
  };

  testMkLayerSuiteValidation = {
    expr = testBuilders.suite.mkLayerSuite {
      name = "unit-suite";
      layer = "unit";
      tests = [ ];
    };
    expected = {
      name = "unit-suite";
      layer = "unit";
      type = "layer-suite";
    };
  };

  # Test validation functions
  testValidateTestCaseValid = {
    expr = testBuilders.validators.validateTestCase {
      name = "valid-test";
      type = "unit";
      framework = "nix-unit";
    };
    expected = {
      name = "valid-test";
      type = "unit";
      framework = "nix-unit";
    };
  };

  testValidateTestCaseInvalid = {
    expr = builtins.tryEval (
      testBuilders.validators.validateTestCase {
        name = "invalid-test";
        # missing type and framework
      }
    );
    expected = {
      success = false;
    };
  };

  testValidateTestSuiteValid = {
    expr = testBuilders.validators.validateTestSuite {
      name = "valid-suite";
      type = "suite";
      testCases = [
        {
          name = "test1";
          type = "unit";
          framework = "nix-unit";
        }
      ];
    };
    expected = {
      name = "valid-suite";
      type = "suite";
    };
  };

  testValidateTestSuiteInvalid = {
    expr = builtins.tryEval (
      testBuilders.validators.validateTestSuite {
        name = "invalid-suite";
        # missing type and testCases
      }
    );
    expected = {
      success = false;
    };
  };

  testValidatePlatformValid = {
    expr = testBuilders.validators.validatePlatform "darwin-aarch64";
    expected = "darwin-aarch64";
  };

  testValidatePlatformInvalid = {
    expr = builtins.tryEval (testBuilders.validators.validatePlatform "unsupported-platform");
    expected = {
      success = false;
    };
  };

  # Test framework runner functions
  testMkFrameworkRunnerNixUnit = {
    expr = testBuilders.runners.mkFrameworkRunner "nix-unit";
    expected = {
      command = "nix-unit";
      args = [ "--flake" ];
      supported = true;
    };
  };

  testMkFrameworkRunnerBats = {
    expr = testBuilders.runners.mkFrameworkRunner "bats";
    expected = {
      command = "bats";
      args = [ ];
      supported = true;
    };
  };

  testMkFrameworkRunnerUnsupported = {
    expr = testBuilders.runners.mkFrameworkRunner "unsupported";
    expected = {
      command = null;
      args = [ ];
      supported = false;
    };
  };

  testGetRunner = {
    expr = testBuilders.runners.getRunner {
      name = "test";
      framework = "nix-unit";
    };
    expected = {
      command = "nix-unit";
      supported = true;
    };
  };

  # Test metadata and compatibility
  testBuilderVersion = {
    expr = testBuilders.version;
    expected = "1.0.0";
  };

  testSupportedFrameworks = {
    expr = builtins.length testBuilders.supportedFrameworks;
    expected = 6; # nix-unit, lib.runTests, bats, nixos-vm, interface, api
  };

  testSupportedLayers = {
    expr = builtins.length testBuilders.supportedLayers;
    expected = 4; # unit, contract, integration, e2e
  };

  # Test legacy compatibility
  testLegacyMkTestApp = {
    expr = testBuilders.legacy.mkTestApp {
      name = "legacy-test";
      system = "x86_64-linux";
      command = "echo legacy";
    };
    expected = {
      type = "app";
    };
  };
}
