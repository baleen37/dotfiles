# Library Functions Unit Tests
# Comprehensive tests for lib/ directory functions using NixTest framework
# Tests: platform-detection.nix, utils-system.nix, test-builders.nix

{ lib ? import <nixpkgs/lib>
, pkgs ? import <nixpkgs> { }
, system ? builtins.currentSystem
, nixtest ? null
, testHelpers ? null
, self ? null
,
}:

let
  # Use provided NixTest framework and helpers (or fallback to local imports)
  nixtestFinal =
    if nixtest != null then nixtest else (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;
  testHelpersFinal =
    if testHelpers != null then testHelpers else import ./test-helpers.nix { inherit lib pkgs; };

  # Import project libraries for testing (with fallback paths)
  platformDetection =
    if self != null then
      import (self + /lib/platform-detection.nix) { inherit lib pkgs system; }
    else
      import ../../lib/platform-detection.nix { inherit lib pkgs system; };
  utilsSystem =
    if self != null then
      import (self + /lib/utils-system.nix) { inherit lib pkgs; }
    else
      import ../../lib/utils-system.nix { inherit lib pkgs; };
  testBuilders =
    if self != null then
      import (self + /lib/test-builders.nix) { inherit lib pkgs; }
    else
      import ../../lib/test-builders.nix { inherit lib pkgs; };

  # Test data for comprehensive testing
  testData = {
    validSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    invalidSystems = [
      "invalid-system"
      "windows-x86_64"
      "unsupported-arch"
    ];

    samplePackages = [
      "git"
      "vim"
      "curl"
    ];

    sampleConfigs = {
      config1 = {
        a = 1;
        b = {
          c = 2;
        };
      };
      config2 = {
        b = {
          d = 3;
        };
        e = 4;
      };
      merged = {
        a = 1;
        b = {
          c = 2;
          d = 3;
        };
        e = 4;
      };
    };
  };

in
nixtestFinal.suite "Library Functions Tests" {

  # Platform Detection Tests
  platformDetectionTests = nixtestFinal.suite "Platform Detection Tests" {

    # Basic platform detection
    darwinDetection = nixtestFinal.test "Darwin platform detection" (
      nixtestFinal.assertions.assertTrue (platformDetection.isDarwin "x86_64-darwin")
    );

    linuxDetection = nixtestFinal.test "Linux platform detection" (
      nixtestFinal.assertions.assertTrue (platformDetection.isLinux "x86_64-linux")
    );

    x86_64Detection = nixtestFinal.test "x86_64 architecture detection" (
      nixtestFinal.assertions.assertTrue (platformDetection.isX86_64 "x86_64-linux")
    );

    aarch64Detection = nixtestFinal.test "aarch64 architecture detection" (
      nixtestFinal.assertions.assertTrue (platformDetection.isAarch64 "aarch64-darwin")
    );

    # Platform extraction
    getPlatformDarwin = nixtestFinal.test "Get platform from Darwin system" (
      nixtestFinal.assertions.assertEqual "darwin" (platformDetection.getPlatform "aarch64-darwin")
    );

    getPlatformLinux = nixtestFinal.test "Get platform from Linux system" (
      nixtestFinal.assertions.assertEqual "linux" (platformDetection.getPlatform "x86_64-linux")
    );

    # Architecture extraction
    getArchX86 = nixtestFinal.test "Get architecture from x86_64 system" (
      nixtestFinal.assertions.assertEqual "x86_64" (platformDetection.getArch "x86_64-darwin")
    );

    getArchArm = nixtestFinal.test "Get architecture from aarch64 system" (
      nixtestFinal.assertions.assertEqual "aarch64" (platformDetection.getArch "aarch64-linux")
    );

    # System validation
    validSystemValidation = nixtestFinal.test "Valid system validation" (
      nixtestFinal.assertions.assertEqual "x86_64-linux" (platformDetection.validateSystem "x86_64-linux")
    );

    # Error handling for invalid systems
    invalidSystemValidation = nixtestFinal.test "Invalid system validation throws error" (
      nixtestFinal.assertions.assertThrows (platformDetection.validateSystem "invalid-system")
    );

    # Platform metadata
    supportedPlatformsCheck = nixtestFinal.test "Supported platforms list" (
      nixtestFinal.assertions.assertContains "darwin" platformDetection.supportedPlatforms
    );

    supportedArchsCheck = nixtestFinal.test "Supported architectures list" (
      nixtestFinal.assertions.assertContains "x86_64" platformDetection.supportedArchitectures
    );

    # Cross-platform utilities
    crossPlatformSpecific = nixtestFinal.test "Platform-specific value selection" (
      let
        values = {
          darwin = "mac-value";
          linux = "linux-value";
        };
        currentPlatform = platformDetection.getPlatform system;
        result = platformDetection.crossPlatform.platformSpecific values;
      in
      nixtestFinal.assertions.assertTrue (result != null)
    );
  };

  # Utils System Tests
  utilsSystemTests = nixtestFinal.suite "Utils System Tests" {

    # System utilities
    systemUtilsTests = nixtestFinal.suite "System Utilities" {
      systemComparison = nixtestFinal.test "System string comparison" (
        nixtestFinal.assertions.assertTrue (utilsSystem.systemUtils.isSystem "x86_64-linux" "x86_64-linux")
      );

      darwinSystemCheck = nixtestFinal.test "Darwin system check" (
        nixtestFinal.assertions.assertTrue (utilsSystem.systemUtils.isDarwin "aarch64-darwin")
      );
    };

    # Package utilities
    packageUtilsTests = nixtestFinal.suite "Package Utilities" {
      packageNamesExtraction = nixtestFinal.test "Extract package names" (
        let
          mockPackages = [
            { name = "git"; }
            { pname = "vim"; }
          ];
          names = utilsSystem.packageUtils.getPackageNames mockPackages;
        in
        nixtestFinal.assertions.assertContains "git" names
      );

      packageValidation = nixtestFinal.test "Package validation" (
        let
          validPackages = [{ name = "test-pkg"; }];
          result = utilsSystem.packageUtils.validatePackages validPackages;
        in
        nixtestFinal.assertions.assertEqual validPackages result
      );
    };

    # Configuration utilities
    configUtilsTests = nixtestFinal.suite "Configuration Utilities" {
      configMerging = nixtestFinal.test "Configuration merging" (
        let
          result = utilsSystem.configUtils.mergeConfigs testData.sampleConfigs.config1 testData.sampleConfigs.config2;
        in
        nixtestFinal.assertions.assertHasAttr "a" result
      );

      multiConfigMerging = nixtestFinal.test "Multiple configuration merging" (
        let
          configs = [
            { a = 1; }
            { b = 2; }
            { c = 3; }
          ];
          result = utilsSystem.configUtils.mergeMultipleConfigs configs;
        in
        nixtestFinal.assertions.assertAttrValue "c" 3 result
      );

      requiredKeysValidation = nixtestFinal.test "Required keys validation" (
        let
          config = {
            required1 = "value";
            required2 = "value";
          };
          result = utilsSystem.configUtils.validateRequiredKeys config [
            "required1"
            "required2"
          ];
        in
        nixtestFinal.assertions.assertEqual config result
      );
    };

    # List utilities
    listUtilsTests = nixtestFinal.suite "List Utilities" {
      uniqueElements = nixtestFinal.test "Remove duplicate elements" (
        let
          input = [
            1
            2
            2
            3
            1
            4
          ];
          result = utilsSystem.listUtils.unique input;
        in
        nixtestFinal.assertions.assertEqual [ 1 2 3 4 ] result
      );

      listFlattening = nixtestFinal.test "Flatten nested lists" (
        let
          input = [
            [
              1
              2
            ]
            [
              3
              [
                4
                5
              ]
            ]
            6
          ];
          result = utilsSystem.listUtils.flatten input;
        in
        nixtestFinal.assertions.assertEqual [ 1 2 3 4 5 6 ] result
      );

      listPartitioning = nixtestFinal.test "Partition list by predicate" (
        let
          input = [
            1
            2
            3
            4
            5
            6
          ];
          result = utilsSystem.listUtils.partition (x: (builtins.div x 2) * 2 == x) input;
        in
        nixtestFinal.assertions.assertEqual [ 2 4 6 ] result.true
      );

      listTaking = nixtestFinal.test "Take first n elements" (
        let
          input = [
            1
            2
            3
            4
            5
          ];
          result = utilsSystem.listUtils.take 3 input;
        in
        nixtestFinal.assertions.assertEqual [ 1 2 3 ] result
      );

      listDropping = nixtestFinal.test "Drop first n elements" (
        let
          input = [
            1
            2
            3
            4
            5
          ];
          result = utilsSystem.listUtils.drop 2 input;
        in
        nixtestFinal.assertions.assertEqual [ 3 4 5 ] result
      );
    };

    # String utilities
    stringUtilsTests = nixtestFinal.suite "String Utilities" {
      stringJoining = nixtestFinal.test "Join strings with separator" (
        let
          input = [
            "a"
            "b"
            "c"
          ];
          result = utilsSystem.stringUtils.joinStrings "," input;
        in
        nixtestFinal.assertions.assertEqual "a,b,c" result
      );

      prefixChecking = nixtestFinal.test "Check string prefix" (
        nixtestFinal.assertions.assertTrue (utilsSystem.stringUtils.hasPrefix "test" "test-string")
      );

      suffixChecking = nixtestFinal.test "Check string suffix" (
        nixtestFinal.assertions.assertTrue (utilsSystem.stringUtils.hasSuffix "ing" "test-string")
      );

      prefixRemoval = nixtestFinal.test "Remove string prefix" (
        let
          result = utilsSystem.stringUtils.removePrefix "test-" "test-string";
        in
        nixtestFinal.assertions.assertEqual "string" result
      );

      suffixRemoval = nixtestFinal.test "Remove string suffix" (
        let
          result = utilsSystem.stringUtils.removeSuffix "-string" "test-string";
        in
        nixtestFinal.assertions.assertEqual "test" result
      );
    };

    # Path utilities
    pathUtilsTests = nixtestFinal.suite "Path Utilities" {
      pathJoining = nixtestFinal.test "Join path components" (
        let
          components = [
            "home"
            "user"
            "documents"
          ];
          result = utilsSystem.pathUtils.joinPath components;
        in
        nixtestFinal.assertions.assertEqual "home/user/documents" result
      );

      basenameFuntion = nixtestFinal.test "Extract basename from path" (
        let
          result = utilsSystem.pathUtils.basename "/home/user/file.txt";
        in
        nixtestFinal.assertions.assertEqual "file.txt" result
      );

      dirnameFuntion = nixtestFinal.test "Extract dirname from path" (
        let
          result = utilsSystem.pathUtils.dirname "/home/user/file.txt";
        in
        nixtestFinal.assertions.assertEqual "/home/user" result
      );

      absolutePathCheck = nixtestFinal.test "Check if path is absolute" (
        nixtestFinal.assertions.assertTrue (utilsSystem.pathUtils.isAbsolute "/absolute/path")
      );
    };

    # Attribute utilities
    attrUtilsTests = nixtestFinal.suite "Attribute Utilities" {
      attrPathCheck = nixtestFinal.test "Check if attribute path exists" (
        let
          attrs = {
            a = {
              b = {
                c = "value";
              };
            };
          };
          result = utilsSystem.attrUtils.hasAttrPath [ "a" "b" "c" ] attrs;
        in
        nixtestFinal.assertions.assertTrue result
      );

      attrPathGet = nixtestFinal.test "Get value at attribute path" (
        let
          attrs = {
            a = {
              b = {
                c = "value";
              };
            };
          };
          result = utilsSystem.attrUtils.getAttrPath [ "a" "b" "c" ] attrs "default";
        in
        nixtestFinal.assertions.assertEqual "value" result
      );

      attrPathSet = nixtestFinal.test "Set value at attribute path" (
        let
          attrs = {
            a = {
              b = { };
            };
          };
          result = utilsSystem.attrUtils.setAttrPath [ "a" "b" "c" ] "new-value" attrs;
        in
        nixtestFinal.assertions.assertAttrValue "c" "new-value" result.a.b
      );
    };
  };

  # Test Builders Tests
  testBuildersTests = nixtestFinal.suite "Test Builders Tests" {

    # Test builder metadata
    builderVersionCheck = nixtestFinal.test "Test builder version" (
      nixtestFinal.assertions.assertEqual "1.0.0" testBuilders.version
    );

    supportedFrameworksCheck = nixtestFinal.test "Supported frameworks list" (
      nixtestFinal.assertions.assertContains "nix-unit" testBuilders.supportedFrameworks
    );

    supportedLayersCheck = nixtestFinal.test "Supported test layers" (
      nixtestFinal.assertions.assertContains "unit" testBuilders.supportedLayers
    );

    # Unit test builders
    unitTestBuilderTests = nixtestFinal.suite "Unit Test Builders" {
      nixUnitTestBuilder = nixtestFinal.test "Nix unit test builder" (
        let
          testCase = testBuilders.unit.mkNixUnitTest {
            name = "sample-test";
            expr = 2 + 2;
            expected = 4;
          };
        in
        nixtestFinal.assertions.assertAttrValue "framework" "nix-unit" testCase
      );

      libTestSuiteBuilder = nixtestFinal.test "Lib test suite builder" (
        let
          suite = testBuilders.unit.mkLibTestSuite {
            name = "test-suite";
            tests = {
              testCase = {
                expr = 1;
                expected = 1;
              };
            };
          };
        in
        nixtestFinal.assertions.assertAttrValue "framework" "lib.runTests" suite
      );

      functionTestBuilder = nixtestFinal.test "Function test builder" (
        let
          testCase = testBuilders.unit.mkFunctionTest {
            name = "func-test";
            func = lib.add;
            inputs = [
              2
              3
            ];
            expected = 5;
          };
        in
        nixtestFinal.assertions.assertAttrValue "framework" "function" testCase
      );
    };

    # Contract test builders
    contractTestBuilderTests = nixtestFinal.suite "Contract Test Builders" {
      interfaceTestBuilder = nixtestFinal.test "Interface test builder" (
        let
          testCase = testBuilders.contract.mkInterfaceTest {
            name = "interface-test";
            modulePath = "./test-module.nix";
            requiredExports = [
              "config"
              "options"
            ];
          };
        in
        nixtestFinal.assertions.assertAttrValue "framework" "interface" testCase
      );

      platformContractBuilder = nixtestFinal.test "Platform contract test builder" (
        let
          testCase = testBuilders.contract.mkPlatformContractTest {
            name = "platform-test";
            platforms = [ "darwin-x86_64" ];
            testFunction = platform: platform != null;
          };
        in
        nixtestFinal.assertions.assertAttrValue "framework" "platform" testCase
      );
    };

    # Validation functions
    validationTests = nixtestFinal.suite "Validation Functions" {
      platformValidation = nixtestFinal.test "Platform validation" (
        let
          result = testBuilders.validators.validatePlatform "darwin-x86_64";
        in
        nixtestFinal.assertions.assertEqual "darwin-x86_64" result
      );

      invalidPlatformValidation = nixtestFinal.test "Invalid platform validation throws" (
        nixtestFinal.assertions.assertThrows (
          testBuilders.validators.validatePlatform "unsupported-platform"
        )
      );
    };

    # Test runners
    runnerTests = nixtestFinal.suite "Test Runner Functions" {
      nixUnitRunner = nixtestFinal.test "Nix unit test runner" (
        let
          runner = testBuilders.runners.mkFrameworkRunner "nix-unit";
        in
        nixtestFinal.assertions.assertAttrValue "command" "nix-unit" runner
      );

      batsRunner = nixtestFinal.test "BATS test runner" (
        let
          runner = testBuilders.runners.mkFrameworkRunner "bats";
        in
        nixtestFinal.assertions.assertAttrValue "command" "bats" runner
      );

      unsupportedRunner = nixtestFinal.test "Unsupported framework runner" (
        let
          runner = testBuilders.runners.mkFrameworkRunner "unsupported";
        in
        nixtestFinal.assertions.assertFalse runner.supported
      );
    };
  };

  # Error handling and edge cases
  errorHandlingTests = nixtestFinal.suite "Error Handling Tests" {

    # Platform detection errors
    invalidPlatformError = nixtestFinal.test "Invalid platform throws error" (
      nixtestFinal.assertions.assertThrows (platformDetection.getPlatform "invalid-system")
    );

    # Utils system errors
    invalidConfigKeysError = nixtestFinal.test "Missing config keys throws error" (
      nixtestFinal.assertions.assertThrows (
        utilsSystem.configUtils.validateRequiredKeys { } [ "missing-key" ]
      )
    );

    # Package validation errors
    invalidPackageError = nixtestFinal.test "Invalid package validation throws error" (
      nixtestFinal.assertions.assertThrows (utilsSystem.packageUtils.validatePackages [{ }])
    );
  };

  # Performance and compatibility tests
  performanceTests = nixtestFinal.suite "Performance and Compatibility Tests" {

    # Large data handling
    largeListProcessing = nixtestFinal.test "Large list unique processing" (
      let
        largeList = builtins.genList
          (
            i:
            let
              r = builtins.div i 100;
            in
            i - (r * 100)
          ) 1000;
        result = utilsSystem.listUtils.unique largeList;
      in
      nixtestFinal.assertions.assertTrue (builtins.length result <= 100)
    );

    # Deep nesting handling
    deepAttrAccess = nixtestFinal.test "Deep attribute path access" (
      let
        deepAttrs = {
          a = {
            b = {
              c = {
                d = {
                  e = "deep-value";
                };
              };
            };
          };
        };
        result = utilsSystem.attrUtils.getAttrPath [ "a" "b" "c" "d" "e" ] deepAttrs "default";
      in
      nixtestFinal.assertions.assertEqual "deep-value" result
    );

    # Cross-platform string operations
    crossPlatformPaths = nixtestFinal.test "Cross-platform path operations" (
      let
        components = [
          "users"
          "test"
          "documents"
        ];
        result = utilsSystem.pathUtils.joinPath components;
      in
      nixtestFinal.assertions.assertStringContains "users" result
    );
  };
}
