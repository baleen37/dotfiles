# Library Functions Unit Tests
# Comprehensive tests for lib/ directory functions using NixTest framework
# Tests: platform-detection.nix, utils-system.nix, test-builders.nix

{ lib ? import <nixpkgs/lib>
, pkgs ? import <nixpkgs> { }
, system ? builtins.currentSystem
}:

let
  # Import NixTest framework and helpers
  nixtest = (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;
  testHelpers = import ./test-helpers.nix { inherit lib pkgs; };

  # Import project libraries for testing
  platformDetection = import ../../lib/platform-detection.nix { inherit lib pkgs system; };
  utilsSystem = import ../../lib/utils-system.nix { inherit lib pkgs; };
  testBuilders = import ../../lib/test-builders.nix { inherit lib pkgs; };

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
      config1 = { a = 1; b = { c = 2; }; };
      config2 = { b = { d = 3; }; e = 4; };
      merged = { a = 1; b = { c = 2; d = 3; }; e = 4; };
    };
  };

in
nixtest.suite "Library Functions Tests" {

  # Platform Detection Tests
  platformDetectionTests = nixtest.suite "Platform Detection Tests" {

    # Basic platform detection
    darwinDetection = nixtest.test "Darwin platform detection"
      (nixtest.assertions.assertTrue
        (platformDetection.isDarwin "x86_64-darwin"));

    linuxDetection = nixtest.test "Linux platform detection"
      (nixtest.assertions.assertTrue
        (platformDetection.isLinux "x86_64-linux"));

    x86_64Detection = nixtest.test "x86_64 architecture detection"
      (nixtest.assertions.assertTrue
        (platformDetection.isX86_64 "x86_64-linux"));

    aarch64Detection = nixtest.test "aarch64 architecture detection"
      (nixtest.assertions.assertTrue
        (platformDetection.isAarch64 "aarch64-darwin"));

    # Platform extraction
    getPlatformDarwin = nixtest.test "Get platform from Darwin system"
      (nixtest.assertions.assertEqual "darwin"
        (platformDetection.getPlatform "aarch64-darwin"));

    getPlatformLinux = nixtest.test "Get platform from Linux system"
      (nixtest.assertions.assertEqual "linux"
        (platformDetection.getPlatform "x86_64-linux"));

    # Architecture extraction
    getArchX86 = nixtest.test "Get architecture from x86_64 system"
      (nixtest.assertions.assertEqual "x86_64"
        (platformDetection.getArch "x86_64-darwin"));

    getArchArm = nixtest.test "Get architecture from aarch64 system"
      (nixtest.assertions.assertEqual "aarch64"
        (platformDetection.getArch "aarch64-linux"));

    # System validation
    validSystemValidation = nixtest.test "Valid system validation"
      (nixtest.assertions.assertEqual "x86_64-linux"
        (platformDetection.validateSystem "x86_64-linux"));

    # Error handling for invalid systems
    invalidSystemValidation = nixtest.test "Invalid system validation throws error"
      (nixtest.assertions.assertThrows
        (platformDetection.validateSystem "invalid-system"));

    # Platform metadata
    supportedPlatformsCheck = nixtest.test "Supported platforms list"
      (nixtest.assertions.assertContains "darwin" platformDetection.supportedPlatforms);

    supportedArchsCheck = nixtest.test "Supported architectures list"
      (nixtest.assertions.assertContains "x86_64" platformDetection.supportedArchitectures);

    # Cross-platform utilities
    crossPlatformSpecific = nixtest.test "Platform-specific value selection"
      (
        let
          values = { darwin = "mac-value"; linux = "linux-value"; };
          currentPlatform = platformDetection.getPlatform system;
          result = platformDetection.crossPlatform.platformSpecific values;
        in
        nixtest.assertions.assertTrue (result != null)
      );
  };

  # Utils System Tests
  utilsSystemTests = nixtest.suite "Utils System Tests" {

    # System utilities
    systemUtilsTests = nixtest.suite "System Utilities" {
      systemComparison = nixtest.test "System string comparison"
        (nixtest.assertions.assertTrue
          (utilsSystem.systemUtils.isSystem "x86_64-linux" "x86_64-linux"));

      darwinSystemCheck = nixtest.test "Darwin system check"
        (nixtest.assertions.assertTrue
          (utilsSystem.systemUtils.isDarwin "aarch64-darwin"));
    };

    # Package utilities
    packageUtilsTests = nixtest.suite "Package Utilities" {
      packageNamesExtraction = nixtest.test "Extract package names"
        (
          let
            mockPackages = [
              { name = "git"; }
              { pname = "vim"; }
            ];
            names = utilsSystem.packageUtils.getPackageNames mockPackages;
          in
          nixtest.assertions.assertContains "git" names
        );

      packageValidation = nixtest.test "Package validation"
        (
          let
            validPackages = [{ name = "test-pkg"; }];
            result = utilsSystem.packageUtils.validatePackages validPackages;
          in
          nixtest.assertions.assertEqual validPackages result
        );
    };

    # Configuration utilities
    configUtilsTests = nixtest.suite "Configuration Utilities" {
      configMerging = nixtest.test "Configuration merging"
        (
          let
            result = utilsSystem.configUtils.mergeConfigs
              testData.sampleConfigs.config1
              testData.sampleConfigs.config2;
          in
          nixtest.assertions.assertHasAttr "a" result
        );

      multiConfigMerging = nixtest.test "Multiple configuration merging"
        (
          let
            configs = [
              { a = 1; }
              { b = 2; }
              { c = 3; }
            ];
            result = utilsSystem.configUtils.mergeMultipleConfigs configs;
          in
          nixtest.assertions.assertAttrValue "c" 3 result
        );

      requiredKeysValidation = nixtest.test "Required keys validation"
        (
          let
            config = { required1 = "value"; required2 = "value"; };
            result = utilsSystem.configUtils.validateRequiredKeys
              config [ "required1" "required2" ];
          in
          nixtest.assertions.assertEqual config result
        );
    };

    # List utilities
    listUtilsTests = nixtest.suite "List Utilities" {
      uniqueElements = nixtest.test "Remove duplicate elements"
        (
          let
            input = [ 1 2 2 3 1 4 ];
            result = utilsSystem.listUtils.unique input;
          in
          nixtest.assertions.assertEqual [ 1 2 3 4 ] result
        );

      listFlattening = nixtest.test "Flatten nested lists"
        (
          let
            input = [ [ 1 2 ] [ 3 [ 4 5 ] ] 6 ];
            result = utilsSystem.listUtils.flatten input;
          in
          nixtest.assertions.assertEqual [ 1 2 3 4 5 6 ] result
        );

      listPartitioning = nixtest.test "Partition list by predicate"
        (
          let
            input = [ 1 2 3 4 5 6 ];
            result = utilsSystem.listUtils.partition (x: x % 2 == 0) input;
          in
          nixtest.assertions.assertEqual [ 2 4 6 ] result.true
        );

      listTaking = nixtest.test "Take first n elements"
        (
          let
            input = [ 1 2 3 4 5 ];
            result = utilsSystem.listUtils.take 3 input;
          in
          nixtest.assertions.assertEqual [ 1 2 3 ] result
        );

      listDropping = nixtest.test "Drop first n elements"
        (
          let
            input = [ 1 2 3 4 5 ];
            result = utilsSystem.listUtils.drop 2 input;
          in
          nixtest.assertions.assertEqual [ 3 4 5 ] result
        );
    };

    # String utilities
    stringUtilsTests = nixtest.suite "String Utilities" {
      stringJoining = nixtest.test "Join strings with separator"
        (
          let
            input = [ "a" "b" "c" ];
            result = utilsSystem.stringUtils.joinStrings "," input;
          in
          nixtest.assertions.assertEqual "a,b,c" result
        );

      prefixChecking = nixtest.test "Check string prefix"
        (nixtest.assertions.assertTrue
          (utilsSystem.stringUtils.hasPrefix "test" "test-string"));

      suffixChecking = nixtest.test "Check string suffix"
        (nixtest.assertions.assertTrue
          (utilsSystem.stringUtils.hasSuffix "ing" "test-string"));

      prefixRemoval = nixtest.test "Remove string prefix"
        (
          let
            result = utilsSystem.stringUtils.removePrefix "test-" "test-string";
          in
          nixtest.assertions.assertEqual "string" result
        );

      suffixRemoval = nixtest.test "Remove string suffix"
        (
          let
            result = utilsSystem.stringUtils.removeSuffix "-string" "test-string";
          in
          nixtest.assertions.assertEqual "test" result
        );
    };

    # Path utilities
    pathUtilsTests = nixtest.suite "Path Utilities" {
      pathJoining = nixtest.test "Join path components"
        (
          let
            components = [ "home" "user" "documents" ];
            result = utilsSystem.pathUtils.joinPath components;
          in
          nixtest.assertions.assertEqual "home/user/documents" result
        );

      basenameFuntion = nixtest.test "Extract basename from path"
        (
          let
            result = utilsSystem.pathUtils.basename "/home/user/file.txt";
          in
          nixtest.assertions.assertEqual "file.txt" result
        );

      dirnameFuntion = nixtest.test "Extract dirname from path"
        (
          let
            result = utilsSystem.pathUtils.dirname "/home/user/file.txt";
          in
          nixtest.assertions.assertEqual "/home/user" result
        );

      absolutePathCheck = nixtest.test "Check if path is absolute"
        (nixtest.assertions.assertTrue
          (utilsSystem.pathUtils.isAbsolute "/absolute/path"));
    };

    # Attribute utilities
    attrUtilsTests = nixtest.suite "Attribute Utilities" {
      attrPathCheck = nixtest.test "Check if attribute path exists"
        (
          let
            attrs = { a = { b = { c = "value"; }; }; };
            result = utilsSystem.attrUtils.hasAttrPath [ "a" "b" "c" ] attrs;
          in
          nixtest.assertions.assertTrue result
        );

      attrPathGet = nixtest.test "Get value at attribute path"
        (
          let
            attrs = { a = { b = { c = "value"; }; }; };
            result = utilsSystem.attrUtils.getAttrPath [ "a" "b" "c" ] attrs "default";
          in
          nixtest.assertions.assertEqual "value" result
        );

      attrPathSet = nixtest.test "Set value at attribute path"
        (
          let
            attrs = { a = { b = { }; }; };
            result = utilsSystem.attrUtils.setAttrPath [ "a" "b" "c" ] "new-value" attrs;
          in
          nixtest.assertions.assertAttrValue "c" "new-value" result.a.b
        );
    };
  };

  # Test Builders Tests
  testBuildersTests = nixtest.suite "Test Builders Tests" {

    # Test builder metadata
    builderVersionCheck = nixtest.test "Test builder version"
      (nixtest.assertions.assertEqual "1.0.0" testBuilders.version);

    supportedFrameworksCheck = nixtest.test "Supported frameworks list"
      (nixtest.assertions.assertContains "nix-unit" testBuilders.supportedFrameworks);

    supportedLayersCheck = nixtest.test "Supported test layers"
      (nixtest.assertions.assertContains "unit" testBuilders.supportedLayers);

    # Unit test builders
    unitTestBuilderTests = nixtest.suite "Unit Test Builders" {
      nixUnitTestBuilder = nixtest.test "Nix unit test builder"
        (
          let
            testCase = testBuilders.unit.mkNixUnitTest {
              name = "sample-test";
              expr = 2 + 2;
              expected = 4;
            };
          in
          nixtest.assertions.assertAttrValue "framework" "nix-unit" testCase
        );

      libTestSuiteBuilder = nixtest.test "Lib test suite builder"
        (
          let
            suite = testBuilders.unit.mkLibTestSuite {
              name = "test-suite";
              tests = { testCase = { expr = 1; expected = 1; }; };
            };
          in
          nixtest.assertions.assertAttrValue "framework" "lib.runTests" suite
        );

      functionTestBuilder = nixtest.test "Function test builder"
        (
          let
            testCase = testBuilders.unit.mkFunctionTest {
              name = "func-test";
              func = lib.add;
              inputs = [ 2 3 ];
              expected = 5;
            };
          in
          nixtest.assertions.assertAttrValue "framework" "function" testCase
        );
    };

    # Contract test builders
    contractTestBuilderTests = nixtest.suite "Contract Test Builders" {
      interfaceTestBuilder = nixtest.test "Interface test builder"
        (
          let
            testCase = testBuilders.contract.mkInterfaceTest {
              name = "interface-test";
              modulePath = "./test-module.nix";
              requiredExports = [ "config" "options" ];
            };
          in
          nixtest.assertions.assertAttrValue "framework" "interface" testCase
        );

      platformContractBuilder = nixtest.test "Platform contract test builder"
        (
          let
            testCase = testBuilders.contract.mkPlatformContractTest {
              name = "platform-test";
              platforms = [ "darwin-x86_64" ];
              testFunction = platform: platform != null;
            };
          in
          nixtest.assertions.assertAttrValue "framework" "platform" testCase
        );
    };

    # Validation functions
    validationTests = nixtest.suite "Validation Functions" {
      platformValidation = nixtest.test "Platform validation"
        (
          let
            result = testBuilders.validators.validatePlatform "darwin-x86_64";
          in
          nixtest.assertions.assertEqual "darwin-x86_64" result
        );

      invalidPlatformValidation = nixtest.test "Invalid platform validation throws"
        (nixtest.assertions.assertThrows
          (testBuilders.validators.validatePlatform "unsupported-platform"));
    };

    # Test runners
    runnerTests = nixtest.suite "Test Runner Functions" {
      nixUnitRunner = nixtest.test "Nix unit test runner"
        (
          let
            runner = testBuilders.runners.mkFrameworkRunner "nix-unit";
          in
          nixtest.assertions.assertAttrValue "command" "nix-unit" runner
        );

      batsRunner = nixtest.test "BATS test runner"
        (
          let
            runner = testBuilders.runners.mkFrameworkRunner "bats";
          in
          nixtest.assertions.assertAttrValue "command" "bats" runner
        );

      unsupportedRunner = nixtest.test "Unsupported framework runner"
        (
          let
            runner = testBuilders.runners.mkFrameworkRunner "unsupported";
          in
          nixtest.assertions.assertFalse runner.supported
        );
    };
  };

  # Error handling and edge cases
  errorHandlingTests = nixtest.suite "Error Handling Tests" {

    # Platform detection errors
    invalidPlatformError = nixtest.test "Invalid platform throws error"
      (nixtest.assertions.assertThrows
        (platformDetection.getPlatform "invalid-system"));

    # Utils system errors
    invalidConfigKeysError = nixtest.test "Missing config keys throws error"
      (nixtest.assertions.assertThrows
        (utilsSystem.configUtils.validateRequiredKeys { } [ "missing-key" ]));

    # Package validation errors
    invalidPackageError = nixtest.test "Invalid package validation throws error"
      (nixtest.assertions.assertThrows
        (utilsSystem.packageUtils.validatePackages [{ }]));
  };

  # Performance and compatibility tests
  performanceTests = nixtest.suite "Performance and Compatibility Tests" {

    # Large data handling
    largeListProcessing = nixtest.test "Large list unique processing"
      (
        let
          largeList = builtins.genList (i: i % 100) 1000;
          result = utilsSystem.listUtils.unique largeList;
        in
        nixtest.assertions.assertTrue (builtins.length result <= 100)
      );

    # Deep nesting handling
    deepAttrAccess = nixtest.test "Deep attribute path access"
      (
        let
          deepAttrs = { a = { b = { c = { d = { e = "deep-value"; }; }; }; }; };
          result = utilsSystem.attrUtils.getAttrPath [ "a" "b" "c" "d" "e" ] deepAttrs "default";
        in
        nixtest.assertions.assertEqual "deep-value" result
      );

    # Cross-platform string operations
    crossPlatformPaths = nixtest.test "Cross-platform path operations"
      (
        let
          components = [ "users" "test" "documents" ];
          result = utilsSystem.pathUtils.joinPath components;
        in
        nixtest.assertions.assertStringContains "users" result
      );
  };
}
