# Refactoring Validation Tests
#
# 통합 리팩토링 검증 테스트 - placeholder 제거, dead code 제거, 시스템 리팩토링 후 기능 검증
#
# 테스트 항목:
#   - Placeholder 파일 제거 검증 (test-placeholder-removal.nix)
#   - Dead code 제거 검증 (test-dead-code-removal.nix)
#   - 시스템 리팩토링 후 검증 (test-system-refactor.nix)
#
# 목적: 리팩토링 과정에서 제거된 파일들이 정상적으로 처리되고 시스템이 올바르게 동작하는지 확인

{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Common test platforms - used across multiple test suites
  allTestPlatforms = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  # Import test system for validation
  testSystem = import ../../lib/test-system.nix {
    inherit pkgs;
    nixpkgs = pkgs;
  };

in
pkgs.lib.runTests {
  # Placeholder Files Removal Tests (from test-placeholder-removal.nix)
  testPlaceholderFilesRemoved = {
    expr = {
      # Verify test-builders.nix placeholder is removed
      testBuildersRemoved = !builtins.pathExists ./lib/test-builders.nix;

      # Verify test-lib-functions.nix placeholder is removed
      libFunctionsRemoved = !builtins.pathExists ./nix/test-lib-functions.nix;

      # Verify the nix directory is now empty
      nixDirEmpty =
        let
          dirPath = ./nix;
        in
        if builtins.pathExists dirPath then builtins.readDir dirPath == { } else true;
    };
    expected = {
      testBuildersRemoved = true;
      libFunctionsRemoved = true;
      nixDirEmpty = true;
    };
  };

  # Dead Code Removal Tests (from test-dead-code-removal.nix)
  testLibTestEvaluation = {
    expr = builtins.tryEval (
      import ./lib-test.nix {
        inherit lib;
        pkgs = { };
        system = builtins.head allTestPlatforms; # x86_64-linux
        nixtest = null;
        self = null;
      }
    );
    expected.success = true;
  };

  testDeadCodeRemoved = {
    expr = {
      # Placeholder test files have been properly removed as dead code
      testBuildersRemoved = !builtins.pathExists ./lib/test-builders.nix;
      libFunctionsRemoved = !builtins.pathExists ./nix/test-lib-functions.nix;
    };
    expected = {
      testBuildersRemoved = true;
      libFunctionsRemoved = true;
    };
  };

  testSystemEvaluation = {
    expr = builtins.tryEval (
      import ../../lib/test-system.nix {
        pkgs = {
          inherit lib;
        };
      }
    );
    expected.success = true;
  };

  # System Refactoring Tests (from test-system-refactor.nix)
  testMkTestApp = {
    expr = builtins.typeOf (
      testSystem.mkTestApp {
        name = "test-example";
        system = "x86_64-linux";
        command = "echo test";
      }
    );
    expected = "set";
  };

  testMkTestAppsStructure = {
    expr = builtins.attrNames (testSystem.mkTestApps "x86_64-linux");
    expected = [
      "test"
      "test-core"
      "test-integration"
      "test-list"
      "test-perf"
      "test-smoke"
      "test-unit"
      "test-workflow"
    ];
  };

  testRunSuiteExists = {
    expr = builtins.typeOf testSystem.runSuite;
    expected = "lambda";
  };

  testTestCategoriesComplete = {
    expr = builtins.sort builtins.lessThan (builtins.attrNames testSystem.testCategories);
    expected = [
      "all"
      "core"
      "integration"
      "performance"
      "smoke"
    ];
  };

  testNoUndefinedFunctions = {
    # Verify that runTest is no longer exported (was removed)
    expr = builtins.hasAttr "runTest" testSystem;
    expected = false;
  };

  testTestUtilsExported = {
    expr = builtins.all (name: builtins.hasAttr name testSystem) [
      "mkTestReporter"
      "mkTestDiscovery"
      "mkEnhancedTestRunner"
      "mkTestSuite"
    ];
    expected = true;
  };

  testConfigStructure = {
    expr = builtins.attrNames testSystem.testConfig;
    expected = [
      "defaultTimeout"
      "discoveryPatterns"
      "parallelSettings"
      "reportingOptions"
    ];
  };

  testMetadataComplete = {
    expr = {
      hasVersion = builtins.hasAttr "version" testSystem;
      hasDescription = builtins.hasAttr "description" testSystem;
      hasSupportedTypes = builtins.hasAttr "supportedTestTypes" testSystem;
    };
    expected = {
      hasVersion = true;
      hasDescription = true;
      hasSupportedTypes = true;
    };
  };

  # Additional Cross-Platform Validation
  testCrossPlatformLibEvaluation = {
    expr = builtins.tryEval (
      import ./lib-test.nix {
        inherit lib;
        pkgs = { };
        system = builtins.elemAt allTestPlatforms 3; # aarch64-darwin
        nixtest = null;
        self = null;
      }
    );
    expected.success = true;
  };

  testCrossPlatformIntegration = {
    expr = builtins.tryEval (
      import ../integration/cross-platform-test.nix {
        inherit lib;
        pkgs = { };
        system = builtins.head allTestPlatforms; # x86_64-linux
        nixtest = null;
      }
    );
    expected.success = true;
  };
}
