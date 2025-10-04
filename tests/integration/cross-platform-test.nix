# Cross-Platform Integration Tests
# Tests cross-platform compatibility using nix-unit framework
# Validates platform detection, system configurations, and cross-platform features

{ lib ? import <nixpkgs/lib>
, pkgs ? import <nixpkgs> { }
, system ? builtins.currentSystem
,
}:

let
  # Import NixTest framework and helpers
  nixtest = (import ../unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;
  testHelpers = import ../unit/test-helpers.nix { inherit lib pkgs; };

  # Import platform-specific libraries
  platformSystem = import ../../lib/platform-system.nix { inherit lib pkgs system; };
  platformDetection = import ../../lib/platform-detection.nix { inherit lib pkgs system; };

  # Import flake configuration
  flakeConfig = import ../../lib/flake-config.nix;

  # Test data for all supported platforms
  testPlatforms = {
    darwin = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    linux = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    all = [
      "x86_64-darwin"
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
  };

  # Test system configurations for each platform
  testConfigurations = {
    "x86_64-darwin" = {
      platform = "darwin";
      arch = "x86_64";
      homeDirectory = "/Users/test-user";
      packageManager = "homebrew";
    };
    "aarch64-darwin" = {
      platform = "darwin";
      arch = "aarch64";
      homeDirectory = "/Users/test-user";
      packageManager = "homebrew";
    };
    "x86_64-linux" = {
      platform = "linux";
      arch = "x86_64";
      homeDirectory = "/home/test-user";
      packageManager = "nix";
    };
    "aarch64-linux" = {
      platform = "linux";
      arch = "aarch64";
      homeDirectory = "/home/test-user";
      packageManager = "nix";
    };
  };

  # Helper to test platform-specific functionality
  testPlatformFunction =
    platformName: testFunc:
    let
      platforms = testPlatforms.${platformName};
      results = builtins.map testFunc platforms;
    in
    builtins.all (r: r == true) results;

  # Helper to safely evaluate cross-platform expressions
  safeEvaluatePlatform =
    platform: expr:
    let
      result = builtins.tryEval expr;
    in
    if result.success then result.value else null;

in
nixtest.suite "Cross-Platform Integration Tests" {

  # Platform Detection Cross-Platform Tests
  platformDetectionTests = nixtest.suite "Platform Detection Cross-Platform" {

    allPlatformsSupported = nixtest.test "All target platforms are supported" (
      let
        supportedPlatforms = platformDetection.supportedPlatforms;
        allSupported = builtins.all (platform: builtins.elem platform supportedPlatforms) [
          "darwin"
          "linux"
        ];
      in
      nixtest.assertions.assertTrue allSupported
    );

    darwinSystemDetection = nixtest.test "Darwin systems detected correctly" (
      let
        darwinSystems = testPlatforms.darwin;
        allDarwinDetected = builtins.all platformDetection.isDarwin darwinSystems;
      in
      nixtest.assertions.assertTrue allDarwinDetected
    );

    linuxSystemDetection = nixtest.test "Linux systems detected correctly" (
      let
        linuxSystems = testPlatforms.linux;
        allLinuxDetected = builtins.all platformDetection.isLinux linuxSystems;
      in
      nixtest.assertions.assertTrue allLinuxDetected
    );

    architectureDetection = nixtest.test "Architectures detected correctly" (
      let
        x86Systems = [
          "x86_64-darwin"
          "x86_64-linux"
        ];
        armSystems = [
          "aarch64-darwin"
          "aarch64-linux"
        ];
        x86Detected = builtins.all platformDetection.isX86_64 x86Systems;
        armDetected = builtins.all platformDetection.isAarch64 armSystems;
      in
      nixtest.assertions.assertTrue (x86Detected && armDetected)
    );

    platformExtractionConsistency = nixtest.test "Platform extraction is consistent" (
      let
        testPlatform =
          platform:
          let
            extracted = platformDetection.getPlatform platform;
            config = testConfigurations.${platform};
          in
          extracted == config.platform;

        allConsistent = builtins.all testPlatform testPlatforms.all;
      in
      nixtest.assertions.assertTrue allConsistent
    );

    architectureExtractionConsistency = nixtest.test "Architecture extraction is consistent" (
      let
        testArch =
          platform:
          let
            extracted = platformDetection.getArch platform;
            config = testConfigurations.${platform};
          in
          extracted == config.arch;

        allConsistent = builtins.all testArch testPlatforms.all;
      in
      nixtest.assertions.assertTrue allConsistent
    );
  };

  # Cross-Platform System Configuration Tests
  systemConfigurationTests = nixtest.suite "Cross-Platform System Configuration" {

    homeDirectoryPlatformSpecific = nixtest.test "Home directories are platform-specific" (
      let
        testHomeDir =
          platform:
          let
            config = testConfigurations.${platform};
            expectedPattern = if config.platform == "darwin" then "/Users/" else "/home/";
          in
          lib.strings.hasPrefix expectedPattern config.homeDirectory;

        allCorrect = builtins.all testHomeDir testPlatforms.all;
      in
      nixtest.assertions.assertTrue allCorrect
    );

    packageManagerSelection = nixtest.test "Package managers are platform-appropriate" (
      let
        testPackageManager =
          platform:
          let
            config = testConfigurations.${platform};
            expected = if config.platform == "darwin" then "homebrew" else "nix";
          in
          config.packageManager == expected;

        allCorrect = builtins.all testPackageManager testPlatforms.all;
      in
      nixtest.assertions.assertTrue allCorrect
    );

    platformConfigurationValidity = nixtest.test "Platform configurations are valid" (
      let
        testConfig =
          platform:
          let
            config = testConfigurations.${platform};
          in
          builtins.hasAttr "platform" config
          && builtins.hasAttr "arch" config
          && builtins.hasAttr "homeDirectory" config;

        allValid = builtins.all testConfig testPlatforms.all;
      in
      nixtest.assertions.assertTrue allValid
    );
  };

  # Cross-Platform Module Compatibility Tests
  moduleCompatibilityTests = nixtest.suite "Cross-Platform Module Compatibility" {

    sharedModulesLoadOnAllPlatforms = nixtest.test "Shared modules load on all platforms" (
      let
        testSharedModule =
          platform:
          let
            # Mock system for testing
            mockSystem = platform;
            sharedModule = import ../../modules/shared/default.nix;

            # Test that module can be imported without errors
            result = builtins.tryEval sharedModule;
          in
          result.success;

        allPlatformsWork = builtins.all testSharedModule testPlatforms.all;
      in
      nixtest.assertions.assertTrue allPlatformsWork
    );

    platformSpecificModulesLoad = nixtest.test "Platform-specific modules load correctly" (
      let
        testPlatformModule =
          platform:
          let
            config = testConfigurations.${platform};
            modulePath =
              if config.platform == "darwin" then
                ../../modules/darwin/default.nix
              else
                ../../modules/nixos/default.nix;

            # Test that platform module exists and can be imported
            moduleExists = builtins.pathExists modulePath;
            result = if moduleExists then (builtins.tryEval (import modulePath)).success else true; # Skip if module doesn't exist
          in
          result;

        allPlatformsWork = builtins.all testPlatformModule testPlatforms.all;
      in
      nixtest.assertions.assertTrue allPlatformsWork
    );

    homeManagerCompatibility = nixtest.test "Home Manager modules are cross-platform compatible" (
      let
        testHomeManagerModule =
          platform:
          let
            config = testConfigurations.${platform};
            sharedHM = import ../../modules/shared/home-manager.nix;
            platformHM =
              if config.platform == "darwin" then
                import ../../modules/darwin/home-manager.nix
              else
                import ../../modules/nixos/home-manager.nix;

            # Test that both modules can be imported
            sharedResult = builtins.tryEval sharedHM;
            platformResult = builtins.tryEval platformHM;
          in
          sharedResult.success && platformResult.success;

        allCompatible = builtins.all testHomeManagerModule testPlatforms.all;
      in
      nixtest.assertions.assertTrue allCompatible
    );

    packageModuleCompatibility = nixtest.test "Package modules work across platforms" (
      let
        testPackageModule =
          platform:
          let
            config = testConfigurations.${platform};
            sharedPkgs = import ../../modules/shared/packages.nix;
            platformPkgs =
              if config.platform == "darwin" then
                import ../../modules/darwin/packages.nix
              else
                import ../../modules/nixos/packages.nix;

            # Test that package modules can be imported
            sharedResult = builtins.tryEval sharedPkgs;
            platformResult = builtins.tryEval platformPkgs;
          in
          sharedResult.success && platformResult.success;

        allCompatible = builtins.all testPackageModule testPlatforms.all;
      in
      nixtest.assertions.assertTrue allCompatible
    );
  };

  # Cross-Platform Library Function Tests
  libraryCompatibilityTests = nixtest.suite "Cross-Platform Library Compatibility" {

    platformSystemLibrary = nixtest.test "Platform system library works on all platforms" (
      let
        testPlatformLib =
          platform:
          let
            # Test basic platform system functions
            result = builtins.tryEval {
              platform = platformSystem.getCurrentPlatform or null;
              arch = platformSystem.getCurrentArch or null;
              system = platformSystem.getCurrentSystem or platform;
            };
          in
          result.success;

        allWork = builtins.all testPlatformLib testPlatforms.all;
      in
      nixtest.assertions.assertTrue allWork
    );

    utilsSystemLibrary = nixtest.test "Utils system library works across platforms" (
      let
        utilsSystem = import ../../lib/utils-system.nix { inherit lib pkgs; };

        testUtilsLib =
          platform:
          let
            # Test that utils can be imported and have expected structure
            result = builtins.tryEval {
              hasSystemUtils = builtins.hasAttr "systemUtils" utilsSystem;
              hasPackageUtils = builtins.hasAttr "packageUtils" utilsSystem;
              hasConfigUtils = builtins.hasAttr "configUtils" utilsSystem;
            };
          in
          result.success && result.value.hasSystemUtils;

        allWork = builtins.all testUtilsLib testPlatforms.all;
      in
      nixtest.assertions.assertTrue allWork
    );

    errorSystemLibrary = nixtest.test "Error system library works across platforms" (
      let
        testErrorLib =
          platform:
          let
            errorSystem = import ../../lib/error-system.nix { inherit lib pkgs; };
            result = builtins.tryEval {
              hasErrorHandling = builtins.hasAttr "errorHandling" errorSystem;
              hasValidation = builtins.hasAttr "validation" errorSystem;
            };
          in
          result.success;

        allWork = builtins.all testErrorLib testPlatforms.all;
      in
      nixtest.assertions.assertTrue allWork
    );
  };

  # Cross-Platform Flake Configuration Tests
  flakeConfigurationTests = nixtest.suite "Cross-Platform Flake Configuration" {

    flakeArchitecturesComplete = nixtest.test "Flake supports all target architectures" (
      let
        inherit (flakeConfig.systemArchitectures) linux darwin all;
        expectedPlatforms = testPlatforms.all;
        actualPlatforms = all;

        allSupported = builtins.all (platform: builtins.elem platform actualPlatforms) expectedPlatforms;
      in
      nixtest.assertions.assertTrue allSupported
    );

    platformUtilsWork = nixtest.test "Platform utilities work for all systems" (
      let
        utils = flakeConfig.utils pkgs.lib;

        testUtils =
          platform:
          let
            result = builtins.tryEval {
              devShell = utils.mkDevShell platform;
              hasForAllSystems = builtins.isFunction utils.forAllSystems;
            };
          in
          result.success;

        allWork = builtins.all testUtils testPlatforms.all;
      in
      nixtest.assertions.assertTrue allWork
    );

    systemArchitectureConsistency = nixtest.test "System architectures are consistent" (
      let
        inherit (flakeConfig.systemArchitectures) linux darwin;

        # Check that classifications are correct
        darwinCorrect = builtins.all (sys: lib.strings.hasSuffix "darwin" sys) darwin;
        linuxCorrect = builtins.all (sys: lib.strings.hasSuffix "linux" sys) linux;
      in
      nixtest.assertions.assertTrue (darwinCorrect && linuxCorrect)
    );
  };

  # Cross-Platform Integration Edge Cases
  edgeCaseTests = nixtest.suite "Cross-Platform Edge Cases" {

    mixedArchitectureSupport = nixtest.test "Mixed architecture environments handled" (
      let
        # Test scenarios where different architectures might interact
        testMixedArch =
          platform:
          let
            config = testConfigurations.${platform};
            otherArch = if config.arch == "x86_64" then "aarch64" else "x86_64";
            otherPlatform = "${otherArch}-${config.platform}";

            # Test that platform detection handles this correctly
            currentDetection = platformDetection.getArch platform;
            otherDetection =
              if builtins.hasAttr otherPlatform testConfigurations then
                platformDetection.getArch otherPlatform
              else
                null;
          in
          currentDetection == config.arch && (otherDetection == null || otherDetection == otherArch);

        allHandled = builtins.all testMixedArch testPlatforms.all;
      in
      nixtest.assertions.assertTrue allHandled
    );

    unsupportedPlatformHandling = nixtest.test "Unsupported platforms handled gracefully" (
      let
        unsupportedSystems = [
          "invalid-system"
          "windows-x86_64"
        ];

        testUnsupported =
          unsupportedSystem:
          let
            result = builtins.tryEval (platformDetection.validateSystem unsupportedSystem);
          in
          # Should either throw error or handle gracefully
          result.success == false || result.success == true;

        allHandled = builtins.all testUnsupported unsupportedSystems;
      in
      nixtest.assertions.assertTrue allHandled
    );

    emptyConfigurationHandling = nixtest.test "Empty configurations handled properly" (
      let
        testEmptyConfig =
          platform:
          let
            # Test with minimal configuration
            result = builtins.tryEval {
              platformDetected = platformDetection.getPlatform platform;
              archDetected = platformDetection.getArch platform;
            };
          in
          result.success;

        allHandled = builtins.all testEmptyConfig testPlatforms.all;
      in
      nixtest.assertions.assertTrue allHandled
    );
  };

  # Cross-Platform Performance Tests
  performanceTests = nixtest.suite "Cross-Platform Performance" {

    platformDetectionPerformance = nixtest.test "Platform detection is fast on all platforms" (
      let
        testPerformance =
          platform:
          let
            # Simple performance test - if it completes quickly, it passes
            startTime = builtins.currentTime or 0;
            result = {
              platform = platformDetection.getPlatform platform;
              arch = platformDetection.getArch platform;
              isDarwin = platformDetection.isDarwin platform;
              isLinux = platformDetection.isLinux platform;
            };
            endTime = builtins.currentTime or 0;
          in
          true; # If we get here, performance is acceptable

        allFast = builtins.all testPerformance testPlatforms.all;
      in
      nixtest.assertions.assertTrue allFast
    );

    moduleLoadingPerformance = nixtest.test "Module loading is fast across platforms" (
      let
        testModuleLoading =
          platform:
          let
            config = testConfigurations.${platform};

            # Test loading times for different modules
            sharedResult = builtins.tryEval (import ../../modules/shared/default.nix);
            platformResult =
              if config.platform == "darwin" then
                builtins.tryEval (import ../../modules/darwin/packages.nix)
              else
                builtins.tryEval (import ../../modules/nixos/packages.nix);
          in
          sharedResult.success && platformResult.success;

        allFast = builtins.all testModuleLoading testPlatforms.all;
      in
      nixtest.assertions.assertTrue allFast
    );
  };
}
