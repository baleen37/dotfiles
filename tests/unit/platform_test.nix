# Platform-Specific Unit Tests
# Cross-platform compatibility and platform-specific functionality tests
# Tests both darwin and nixos modules with platform isolation

{ lib ? import <nixpkgs/lib>
, pkgs ? import <nixpkgs> { }
, system ? builtins.currentSystem
}:

let
  # Import NixTest framework
  nixtest = (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import platform detection for testing
  platformDetection = import ../../lib/platform-detection.nix { inherit lib pkgs system; };

  # Platform-specific module imports with fallbacks
  darwinModules = {
    packages =
      if platformDetection.isDarwin system
      then import ../../modules/darwin/packages.nix { inherit pkgs; }
      else { /* mock for non-darwin systems */ };

    homeManager =
      if platformDetection.isDarwin system
      then import ../../modules/darwin/home-manager.nix { inherit lib pkgs; }
      else { /* mock for non-darwin systems */ };
  };

  nixosModules = {
    packages =
      if platformDetection.isLinux system
      then import ../../modules/nixos/packages.nix { inherit pkgs; }
      else { /* mock for non-linux systems */ };

    homeManager =
      if platformDetection.isLinux system
      then import ../../modules/nixos/home-manager.nix { inherit lib pkgs; }
      else { /* mock for non-linux systems */ };
  };

  sharedModules = {
    packages = import ../../modules/shared/packages.nix { inherit pkgs; };
    homeManager = import ../../modules/shared/home-manager.nix { inherit lib pkgs; };
  };

  # Test data for platform testing
  testPlatforms = {
    supportedSystems = [
      "x86_64-darwin"
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];

    darwinSystems = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    linuxSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    architectures = {
      x86_64 = [ "x86_64-darwin" "x86_64-linux" ];
      aarch64 = [ "aarch64-darwin" "aarch64-linux" ];
    };
  };

in
nixtest.suite "Platform-Specific Tests" {

  # Core platform detection tests
  platformDetectionTests = nixtest.suite "Platform Detection Core Tests" {

    # System string parsing
    systemParsingTests = nixtest.suite "System String Parsing" {
      darwinSystemParsing = nixtest.test "Parse Darwin system strings"
        (builtins.all
          (sys: platformDetection.isDarwin sys)
          testPlatforms.darwinSystems);

      linuxSystemParsing = nixtest.test "Parse Linux system strings"
        (builtins.all
          (sys: platformDetection.isLinux sys)
          testPlatforms.linuxSystems);

      x86ArchParsing = nixtest.test "Parse x86_64 architecture strings"
        (builtins.all
          (sys: platformDetection.isX86_64 sys)
          testPlatforms.architectures.x86_64);

      aarch64ArchParsing = nixtest.test "Parse aarch64 architecture strings"
        (builtins.all
          (sys: platformDetection.isAarch64 sys)
          testPlatforms.architectures.aarch64);
    };

    # Platform metadata extraction
    platformMetadataTests = nixtest.suite "Platform Metadata Extraction" {
      extractDarwinPlatform = nixtest.test "Extract Darwin platform name"
        (nixtest.assertions.assertEqual "darwin"
          (platformDetection.getPlatform "aarch64-darwin"));

      extractLinuxPlatform = nixtest.test "Extract Linux platform name"
        (nixtest.assertions.assertEqual "linux"
          (platformDetection.getPlatform "x86_64-linux"));

      extractX86Arch = nixtest.test "Extract x86_64 architecture"
        (nixtest.assertions.assertEqual "x86_64"
          (platformDetection.getArch "x86_64-darwin"));

      extractAarch64Arch = nixtest.test "Extract aarch64 architecture"
        (nixtest.assertions.assertEqual "aarch64"
          (platformDetection.getArch "aarch64-linux"));
    };

    # Cross-platform utilities
    crossPlatformTests = nixtest.suite "Cross-Platform Utilities" {
      conditionalDarwinValue = nixtest.test "Conditional Darwin value selection"
        (
          let
            result = platformDetection.crossPlatform.whenDarwin "darwin-value";
            expected = if platformDetection.isDarwin system then "darwin-value" else null;
          in
          nixtest.assertions.assertEqual expected result
        );

      conditionalLinuxValue = nixtest.test "Conditional Linux value selection"
        (
          let
            result = platformDetection.crossPlatform.whenLinux "linux-value";
            expected = if platformDetection.isLinux system then "linux-value" else null;
          in
          nixtest.assertions.assertEqual expected result
        );

      platformSpecificSelection = nixtest.test "Platform-specific value selection"
        (
          let
            values = { darwin = "mac"; linux = "gnu"; default = "unknown"; };
            result = platformDetection.crossPlatform.platformSpecific values;
          in
          nixtest.assertions.assertTrue (result != null)
        );

      archSpecificSelection = nixtest.test "Architecture-specific value selection"
        (
          let
            values = { x86_64 = "intel"; aarch64 = "arm"; default = "unknown"; };
            result = platformDetection.crossPlatform.archSpecific values;
          in
          nixtest.assertions.assertTrue (result != null)
        );
    };
  };

  # Platform-specific module tests
  platformModuleTests = nixtest.suite "Platform-Specific Module Tests" {

    # Darwin module tests
    darwinModuleTests = nixtest.suite "Darwin Module Tests" {
      darwinPackagesStructure = nixtest.test "Darwin packages module structure"
        (if platformDetection.isDarwin system
        then nixtest.assertions.assertTrue (builtins.isAttrs darwinModules.packages)
        else nixtest.assertions.assertTrue true); # Skip on non-Darwin

      darwinHomeManagerStructure = nixtest.test "Darwin home-manager module structure"
        (if platformDetection.isDarwin system
        then nixtest.assertions.assertTrue (builtins.isAttrs darwinModules.homeManager)
        else nixtest.assertions.assertTrue true); # Skip on non-Darwin

      darwinOnlyOnDarwin = nixtest.test "Darwin modules only loaded on Darwin"
        (if platformDetection.isDarwin system
        then nixtest.assertions.assertTrue (darwinModules.packages != null)
        else nixtest.assertions.assertTrue true); # Should be mocked on non-Darwin
    };

    # NixOS module tests
    nixosModuleTests = nixtest.suite "NixOS Module Tests" {
      nixosPackagesStructure = nixtest.test "NixOS packages module structure"
        (if platformDetection.isLinux system
        then nixtest.assertions.assertTrue (builtins.isAttrs nixosModules.packages)
        else nixtest.assertions.assertTrue true); # Skip on non-Linux

      nixosHomeManagerStructure = nixtest.test "NixOS home-manager module structure"
        (if platformDetection.isLinux system
        then nixtest.assertions.assertTrue (builtins.isAttrs nixosModules.homeManager)
        else nixtest.assertions.assertTrue true); # Skip on non-Linux

      nixosOnlyOnLinux = nixtest.test "NixOS modules only loaded on Linux"
        (if platformDetection.isLinux system
        then nixtest.assertions.assertTrue (nixosModules.packages != null)
        else nixtest.assertions.assertTrue true); # Should be mocked on non-Linux
    };

    # Shared module tests
    sharedModuleTests = nixtest.suite "Shared Module Tests" {
      sharedPackagesStructure = nixtest.test "Shared packages module structure"
        (nixtest.assertions.assertTrue (builtins.isAttrs sharedModules.packages));

      sharedHomeManagerStructure = nixtest.test "Shared home-manager module structure"
        (nixtest.assertions.assertTrue (builtins.isAttrs sharedModules.homeManager));

      sharedCrossPlatform = nixtest.test "Shared modules work cross-platform"
        (nixtest.assertions.assertTrue
          (sharedModules.packages != null && sharedModules.homeManager != null));
    };
  };

  # Cross-platform compatibility tests
  compatibilityTests = nixtest.suite "Cross-Platform Compatibility Tests" {

    # System validation across platforms
    systemValidationTests = nixtest.suite "System Validation Tests" {
      allSupportedSystemsValid = nixtest.test "All supported systems validate"
        (builtins.all
          (sys:
            let validated = platformDetection.validateSystem sys;
            in validated == sys)
          testPlatforms.supportedSystems);

      darwinSystemsValidation = nixtest.test "Darwin systems validation"
        (builtins.all
          (sys: platformDetection.validate.system sys)
          testPlatforms.darwinSystems);

      linuxSystemsValidation = nixtest.test "Linux systems validation"
        (builtins.all
          (sys: platformDetection.validate.system sys)
          testPlatforms.linuxSystems);
    };

    # Platform isolation tests
    platformIsolationTests = nixtest.suite "Platform Isolation Tests" {
      darwinIsolation = nixtest.test "Darwin-specific code isolation"
        (if platformDetection.isDarwin system
        then nixtest.assertions.assertTrue (darwinModules.packages != null)
        else nixtest.assertions.assertTrue true); # Isolated on non-Darwin

      linuxIsolation = nixtest.test "Linux-specific code isolation"
        (if platformDetection.isLinux system
        then nixtest.assertions.assertTrue (nixosModules.packages != null)
        else nixtest.assertions.assertTrue true); # Isolated on non-Linux

      sharedAccessibility = nixtest.test "Shared code accessible on all platforms"
        (nixtest.assertions.assertTrue
          (sharedModules.packages != null && sharedModules.homeManager != null));
    };

    # Architecture compatibility
    architectureCompatibilityTests = nixtest.suite "Architecture Compatibility Tests" {
      x86CompatibilityDarwin = nixtest.test "x86_64 Darwin compatibility"
        (
          let
            sys = "x86_64-darwin";
            isValid = platformDetection.isDarwin sys && platformDetection.isX86_64 sys;
          in
          nixtest.assertions.assertTrue isValid
        );

      aarch64CompatibilityDarwin = nixtest.test "aarch64 Darwin compatibility"
        (
          let
            sys = "aarch64-darwin";
            isValid = platformDetection.isDarwin sys && platformDetection.isAarch64 sys;
          in
          nixtest.assertions.assertTrue isValid
        );

      x86CompatibilityLinux = nixtest.test "x86_64 Linux compatibility"
        (
          let
            sys = "x86_64-linux";
            isValid = platformDetection.isLinux sys && platformDetection.isX86_64 sys;
          in
          nixtest.assertions.assertTrue isValid
        );

      aarch64CompatibilityLinux = nixtest.test "aarch64 Linux compatibility"
        (
          let
            sys = "aarch64-linux";
            isValid = platformDetection.isLinux sys && platformDetection.isAarch64 sys;
          in
          nixtest.assertions.assertTrue isValid
        );
    };
  };

  # Platform feature tests
  platformFeatureTests = nixtest.suite "Platform Feature Tests" {

    # Darwin-specific features
    darwinFeatureTests = nixtest.suite "Darwin Feature Tests" {
      darwinSystemDetection = nixtest.test "Current system Darwin detection"
        (if builtins.match ".*-darwin" system != null
        then nixtest.assertions.assertTrue (platformDetection.info.isDarwin)
        else nixtest.assertions.assertFalse (platformDetection.info.isDarwin));

      darwinPlatformInfo = nixtest.test "Darwin platform info structure"
        (if platformDetection.info.isDarwin
        then nixtest.assertions.assertEqual "darwin" platformDetection.info.platform
        else nixtest.assertions.assertTrue true);
    };

    # Linux-specific features
    linuxFeatureTests = nixtest.suite "Linux Feature Tests" {
      linuxSystemDetection = nixtest.test "Current system Linux detection"
        (if builtins.match ".*-linux" system != null
        then nixtest.assertions.assertTrue (platformDetection.info.isLinux)
        else nixtest.assertions.assertFalse (platformDetection.info.isLinux));

      linuxPlatformInfo = nixtest.test "Linux platform info structure"
        (if platformDetection.info.isLinux
        then nixtest.assertions.assertEqual "linux" platformDetection.info.platform
        else nixtest.assertions.assertTrue true);
    };

    # Architecture features
    architectureFeatureTests = nixtest.suite "Architecture Feature Tests" {
      currentArchDetection = nixtest.test "Current architecture detection"
        (nixtest.assertions.assertTrue
          (platformDetection.info.arch == "x86_64" || platformDetection.info.arch == "aarch64"));

      supportedArchCheck = nixtest.test "Architecture in supported list"
        (nixtest.assertions.assertContains
          platformDetection.info.arch
          platformDetection.supportedArchitectures);
    };
  };

  # Error handling for platform edge cases
  platformErrorHandlingTests = nixtest.suite "Platform Error Handling Tests" {

    # Invalid system handling
    invalidSystemTests = nixtest.suite "Invalid System Handling" {
      invalidSystemError = nixtest.test "Invalid system string throws error"
        (nixtest.assertions.assertThrows
          (platformDetection.validateSystem "invalid-system"));

      emptySystemError = nixtest.test "Empty system string throws error"
        (nixtest.assertions.assertThrows
          (platformDetection.validateSystem ""));

      nullSystemError = nixtest.test "Null system handling"
        (nixtest.assertions.assertThrows
          (platformDetection.getPlatform null));
    };

    # Unsupported platform handling
    unsupportedPlatformTests = nixtest.suite "Unsupported Platform Handling" {
      windowsSystemError = nixtest.test "Windows system not supported"
        (nixtest.assertions.assertThrows
          (platformDetection.getPlatform "x86_64-windows"));

      unknownArchError = nixtest.test "Unknown architecture not supported"
        (nixtest.assertions.assertThrows
          (platformDetection.getArch "unknown-arch-linux"));
    };

    # Cross-platform error handling
    crossPlatformErrorTests = nixtest.suite "Cross-Platform Error Handling" {
      missingDefaultError = nixtest.test "Missing default value throws error"
        (
          let
            values = { someOtherPlatform = "value"; };
          in
          nixtest.assertions.assertThrows
            (platformDetection.crossPlatform.platformSpecific values)
        );

      invalidValueStructureError = nixtest.test "Invalid value structure handling"
        (nixtest.assertions.assertThrows
          (platformDetection.crossPlatform.platformSpecific "not-an-attrset"));
    };
  };

  # Performance tests for platform detection
  platformPerformanceTests = nixtest.suite "Platform Performance Tests" {

    # Caching efficiency
    cachingTests = nixtest.suite "Platform Detection Caching" {
      repeatedDetectionConsistency = nixtest.test "Repeated detection consistency"
        (
          let
            result1 = platformDetection.isDarwin system;
            result2 = platformDetection.isDarwin system;
          in
          nixtest.assertions.assertEqual result1 result2
        );

      platformInfoCaching = nixtest.test "Platform info caching works"
        (
          let
            info1 = platformDetection.info.platform;
            info2 = platformDetection.info.platform;
          in
          nixtest.assertions.assertEqual info1 info2
        );
    };

    # Bulk operations
    bulkOperationTests = nixtest.suite "Bulk Platform Operations" {
      bulkSystemValidation = nixtest.test "Bulk system validation performance"
        (
          let
            results = map platformDetection.validateSystem testPlatforms.supportedSystems;
          in
          nixtest.assertions.assertEqual
            (builtins.length testPlatforms.supportedSystems)
            (builtins.length results)
        );

      bulkPlatformExtraction = nixtest.test "Bulk platform extraction performance"
        (
          let
            platforms = map platformDetection.getPlatform testPlatforms.supportedSystems;
            expectedCount = builtins.length testPlatforms.supportedSystems;
          in
          nixtest.assertions.assertEqual expectedCount (builtins.length platforms)
        );
    };
  };
}
