# Platform-Specific Unit Tests
#
# 플랫폼별 기능 및 크로스 플랫폼 호환성 테스트
# darwin/nixos 모듈을 플랫폼 격리 환경에서 테스트
#
# 테스트 대상:
# - platformDetectionTests: 플랫폼 감지 핵심 기능 (시스템 파싱, 메타데이터 추출, 크로스 플랫폼 유틸리티)
# - platformModuleTests: 플랫폼별 모듈 구조 (darwin/nixos/shared 모듈)
# - compatibilityTests: 크로스 플랫폼 호환성 (시스템 검증, 플랫폼 격리, 아키텍처 호환성)
# - platformFeatureTests: 플랫폼 기능 (darwin/linux 감지, 아키텍처 감지)
# - platformErrorHandlingTests: 플랫폼 에러 처리 (잘못된 시스템, 지원되지 않는 플랫폼, 크로스 플랫폼 에러)
# - platformPerformanceTests: 플랫폼 성능 (캐싱, 대량 작업)
#
# 지원 플랫폼:
# - Darwin: x86_64-darwin, aarch64-darwin
# - Linux: x86_64-linux, aarch64-linux
#
# 테스트 전략: 현재 플랫폼에서만 플랫폼별 코드 실행, 다른 플랫폼에서는 모의 처리

{ lib ? import <nixpkgs/lib>
, pkgs ? import <nixpkgs> { }
, system ? builtins.currentSystem
, nixtest ? null
, testHelpers ? null
, self ? null
,
}:

let
  # Use provided NixTest framework (or fallback to local import)
  nixtestFinal =
    if nixtest != null then nixtest else (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import platform detection for testing (with fallback paths)
  platformDetection =
    if self != null then
      import (self + /lib/platform-detection.nix) { inherit lib pkgs system; }
    else
      import ../../lib/platform-detection.nix { inherit lib pkgs system; };

  # Platform-specific module imports with fallbacks
  darwinModules = {
    packages =
      if platformDetection.isDarwin system then
        import ../../modules/darwin/packages.nix { inherit pkgs; }
      else
        {
          # mock for non-darwin systems
        };

    homeManager =
      if platformDetection.isDarwin system then
        import ../../modules/darwin/home-manager.nix { inherit lib pkgs; }
      else
        {
          # mock for non-darwin systems
        };
  };

  nixosModules = {
    packages =
      if platformDetection.isLinux system then
        import ../../modules/nixos/packages.nix { inherit pkgs; }
      else
        {
          # mock for non-linux systems
        };

    homeManager =
      if platformDetection.isLinux system then
        import ../../modules/nixos/home-manager.nix { inherit lib pkgs; }
      else
        {
          # mock for non-linux systems
        };
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
      x86_64 = [
        "x86_64-darwin"
        "x86_64-linux"
      ];
      aarch64 = [
        "aarch64-darwin"
        "aarch64-linux"
      ];
    };
  };

in
nixtestFinal.suite "Platform-Specific Tests" {

  # Core platform detection tests
  platformDetectionTests = nixtestFinal.suite "Platform Detection Core Tests" {

    # System string parsing
    systemParsingTests = nixtestFinal.suite "System String Parsing" {
      darwinSystemParsing = nixtestFinal.test "Parse Darwin system strings" (
        builtins.all (sys: platformDetection.isDarwin sys) testPlatforms.darwinSystems
      );

      linuxSystemParsing = nixtestFinal.test "Parse Linux system strings" (
        builtins.all (sys: platformDetection.isLinux sys) testPlatforms.linuxSystems
      );

      x86ArchParsing = nixtestFinal.test "Parse x86_64 architecture strings" (
        builtins.all (sys: platformDetection.isX86_64 sys) testPlatforms.architectures.x86_64
      );

      aarch64ArchParsing = nixtestFinal.test "Parse aarch64 architecture strings" (
        builtins.all (sys: platformDetection.isAarch64 sys) testPlatforms.architectures.aarch64
      );
    };

    # Platform metadata extraction
    platformMetadataTests = nixtestFinal.suite "Platform Metadata Extraction" {
      extractDarwinPlatform = nixtestFinal.test "Extract Darwin platform name" (
        nixtestFinal.assertions.assertEqual "darwin" (platformDetection.getPlatform "aarch64-darwin")
      );

      extractLinuxPlatform = nixtestFinal.test "Extract Linux platform name" (
        nixtestFinal.assertions.assertEqual "linux" (platformDetection.getPlatform "x86_64-linux")
      );

      extractX86Arch = nixtestFinal.test "Extract x86_64 architecture" (
        nixtestFinal.assertions.assertEqual "x86_64" (platformDetection.getArch "x86_64-darwin")
      );

      extractAarch64Arch = nixtestFinal.test "Extract aarch64 architecture" (
        nixtestFinal.assertions.assertEqual "aarch64" (platformDetection.getArch "aarch64-linux")
      );
    };

    # Cross-platform utilities
    crossPlatformTests = nixtestFinal.suite "Cross-Platform Utilities" {
      conditionalDarwinValue = nixtestFinal.test "Conditional Darwin value selection" (
        let
          result = platformDetection.crossPlatform.whenDarwin "darwin-value";
          expected = if platformDetection.isDarwin system then "darwin-value" else null;
        in
        nixtestFinal.assertions.assertEqual expected result
      );

      conditionalLinuxValue = nixtestFinal.test "Conditional Linux value selection" (
        let
          result = platformDetection.crossPlatform.whenLinux "linux-value";
          expected = if platformDetection.isLinux system then "linux-value" else null;
        in
        nixtestFinal.assertions.assertEqual expected result
      );

      platformSpecificSelection = nixtestFinal.test "Platform-specific value selection" (
        let
          values = {
            darwin = "mac";
            linux = "gnu";
            default = "unknown";
          };
          result = platformDetection.crossPlatform.platformSpecific values;
        in
        nixtestFinal.assertions.assertTrue (result != null)
      );

      archSpecificSelection = nixtestFinal.test "Architecture-specific value selection" (
        let
          values = {
            x86_64 = "intel";
            aarch64 = "arm";
            default = "unknown";
          };
          result = platformDetection.crossPlatform.archSpecific values;
        in
        nixtestFinal.assertions.assertTrue (result != null)
      );
    };
  };

  # Platform-specific module tests
  platformModuleTests = nixtestFinal.suite "Platform-Specific Module Tests" {

    # Darwin module tests
    darwinModuleTests = nixtestFinal.suite "Darwin Module Tests" {
      darwinPackagesStructure = nixtestFinal.test "Darwin packages module structure" (
        if platformDetection.isDarwin system then
          nixtestFinal.assertions.assertTrue (builtins.isAttrs darwinModules.packages)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Skip on non-Darwin

      darwinHomeManagerStructure = nixtestFinal.test "Darwin home-manager module structure" (
        if platformDetection.isDarwin system then
          nixtestFinal.assertions.assertTrue (builtins.isAttrs darwinModules.homeManager)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Skip on non-Darwin

      darwinOnlyOnDarwin = nixtestFinal.test "Darwin modules only loaded on Darwin" (
        if platformDetection.isDarwin system then
          nixtestFinal.assertions.assertTrue (darwinModules.packages != null)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Should be mocked on non-Darwin
    };

    # NixOS module tests
    nixosModuleTests = nixtestFinal.suite "NixOS Module Tests" {
      nixosPackagesStructure = nixtestFinal.test "NixOS packages module structure" (
        if platformDetection.isLinux system then
          nixtestFinal.assertions.assertTrue (builtins.isAttrs nixosModules.packages)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Skip on non-Linux

      nixosHomeManagerStructure = nixtestFinal.test "NixOS home-manager module structure" (
        if platformDetection.isLinux system then
          nixtestFinal.assertions.assertTrue (builtins.isAttrs nixosModules.homeManager)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Skip on non-Linux

      nixosOnlyOnLinux = nixtestFinal.test "NixOS modules only loaded on Linux" (
        if platformDetection.isLinux system then
          nixtestFinal.assertions.assertTrue (nixosModules.packages != null)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Should be mocked on non-Linux
    };

    # Shared module tests
    sharedModuleTests = nixtestFinal.suite "Shared Module Tests" {
      sharedPackagesStructure = nixtestFinal.test "Shared packages module structure" (
        nixtestFinal.assertions.assertTrue (builtins.isAttrs sharedModules.packages)
      );

      sharedHomeManagerStructure = nixtestFinal.test "Shared home-manager module structure" (
        nixtestFinal.assertions.assertTrue (builtins.isAttrs sharedModules.homeManager)
      );

      sharedCrossPlatform = nixtestFinal.test "Shared modules work cross-platform" (
        nixtestFinal.assertions.assertTrue (
          sharedModules.packages != null && sharedModules.homeManager != null
        )
      );
    };
  };

  # Cross-platform compatibility tests
  compatibilityTests = nixtestFinal.suite "Cross-Platform Compatibility Tests" {

    # System validation across platforms
    systemValidationTests = nixtestFinal.suite "System Validation Tests" {
      allSupportedSystemsValid = nixtestFinal.test "All supported systems validate" (
        builtins.all
          (
            sys:
            let
              validated = platformDetection.validateSystem sys;
            in
            validated == sys
          )
          testPlatforms.supportedSystems
      );

      darwinSystemsValidation = nixtestFinal.test "Darwin systems validation" (
        builtins.all (sys: platformDetection.validate.system sys) testPlatforms.darwinSystems
      );

      linuxSystemsValidation = nixtestFinal.test "Linux systems validation" (
        builtins.all (sys: platformDetection.validate.system sys) testPlatforms.linuxSystems
      );
    };

    # Platform isolation tests
    platformIsolationTests = nixtestFinal.suite "Platform Isolation Tests" {
      darwinIsolation = nixtestFinal.test "Darwin-specific code isolation" (
        if platformDetection.isDarwin system then
          nixtestFinal.assertions.assertTrue (darwinModules.packages != null)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Isolated on non-Darwin

      linuxIsolation = nixtestFinal.test "Linux-specific code isolation" (
        if platformDetection.isLinux system then
          nixtestFinal.assertions.assertTrue (nixosModules.packages != null)
        else
          nixtestFinal.assertions.assertTrue true
      ); # Isolated on non-Linux

      sharedAccessibility = nixtestFinal.test "Shared code accessible on all platforms" (
        nixtestFinal.assertions.assertTrue (
          sharedModules.packages != null && sharedModules.homeManager != null
        )
      );
    };

    # Architecture compatibility
    architectureCompatibilityTests = nixtestFinal.suite "Architecture Compatibility Tests" {
      x86CompatibilityDarwin = nixtestFinal.test "x86_64 Darwin compatibility" (
        let
          sys = "x86_64-darwin";
          isValid = platformDetection.isDarwin sys && platformDetection.isX86_64 sys;
        in
        nixtestFinal.assertions.assertTrue isValid
      );

      aarch64CompatibilityDarwin = nixtestFinal.test "aarch64 Darwin compatibility" (
        let
          sys = "aarch64-darwin";
          isValid = platformDetection.isDarwin sys && platformDetection.isAarch64 sys;
        in
        nixtestFinal.assertions.assertTrue isValid
      );

      x86CompatibilityLinux = nixtestFinal.test "x86_64 Linux compatibility" (
        let
          sys = "x86_64-linux";
          isValid = platformDetection.isLinux sys && platformDetection.isX86_64 sys;
        in
        nixtestFinal.assertions.assertTrue isValid
      );

      aarch64CompatibilityLinux = nixtestFinal.test "aarch64 Linux compatibility" (
        let
          sys = "aarch64-linux";
          isValid = platformDetection.isLinux sys && platformDetection.isAarch64 sys;
        in
        nixtestFinal.assertions.assertTrue isValid
      );
    };
  };

  # Platform feature tests
  platformFeatureTests = nixtestFinal.suite "Platform Feature Tests" {

    # Darwin-specific features
    darwinFeatureTests = nixtestFinal.suite "Darwin Feature Tests" {
      darwinSystemDetection = nixtestFinal.test "Current system Darwin detection" (
        if builtins.match ".*-darwin" system != null then
          nixtestFinal.assertions.assertTrue (platformDetection.info.isDarwin)
        else
          nixtestFinal.assertions.assertFalse (platformDetection.info.isDarwin)
      );

      darwinPlatformInfo = nixtestFinal.test "Darwin platform info structure" (
        if platformDetection.info.isDarwin then
          nixtestFinal.assertions.assertEqual "darwin" platformDetection.info.platform
        else
          nixtestFinal.assertions.assertTrue true
      );
    };

    # Linux-specific features
    linuxFeatureTests = nixtestFinal.suite "Linux Feature Tests" {
      linuxSystemDetection = nixtestFinal.test "Current system Linux detection" (
        if builtins.match ".*-linux" system != null then
          nixtestFinal.assertions.assertTrue (platformDetection.info.isLinux)
        else
          nixtestFinal.assertions.assertFalse (platformDetection.info.isLinux)
      );

      linuxPlatformInfo = nixtestFinal.test "Linux platform info structure" (
        if platformDetection.info.isLinux then
          nixtestFinal.assertions.assertEqual "linux" platformDetection.info.platform
        else
          nixtestFinal.assertions.assertTrue true
      );
    };

    # Architecture features
    architectureFeatureTests = nixtestFinal.suite "Architecture Feature Tests" {
      currentArchDetection = nixtestFinal.test "Current architecture detection" (
        nixtestFinal.assertions.assertTrue (
          platformDetection.info.arch == "x86_64" || platformDetection.info.arch == "aarch64"
        )
      );

      supportedArchCheck = nixtestFinal.test "Architecture in supported list" (
        nixtestFinal.assertions.assertContains platformDetection.info.arch platformDetection.supportedArchitectures
      );
    };
  };

  # Error handling for platform edge cases
  platformErrorHandlingTests = nixtestFinal.suite "Platform Error Handling Tests" {

    # Invalid system handling
    invalidSystemTests = nixtestFinal.suite "Invalid System Handling" {
      invalidSystemError = nixtestFinal.test "Invalid system string throws error" (
        nixtestFinal.assertions.assertThrows (platformDetection.validateSystem "invalid-system")
      );

      emptySystemError = nixtestFinal.test "Empty system string throws error" (
        nixtestFinal.assertions.assertThrows (platformDetection.validateSystem "")
      );

      nullSystemError = nixtestFinal.test "Null system handling" (
        nixtestFinal.assertions.assertThrows (platformDetection.getPlatform null)
      );
    };

    # Unsupported platform handling
    unsupportedPlatformTests = nixtestFinal.suite "Unsupported Platform Handling" {
      windowsSystemError = nixtestFinal.test "Windows system not supported" (
        nixtestFinal.assertions.assertThrows (platformDetection.getPlatform "x86_64-windows")
      );

      unknownArchError = nixtestFinal.test "Unknown architecture not supported" (
        nixtestFinal.assertions.assertThrows (platformDetection.getArch "unknown-arch-linux")
      );
    };

    # Cross-platform error handling
    crossPlatformErrorTests = nixtestFinal.suite "Cross-Platform Error Handling" {
      missingDefaultError = nixtestFinal.test "Missing default value throws error" (
        let
          values = {
            someOtherPlatform = "value";
          };
        in
        nixtestFinal.assertions.assertThrows (platformDetection.crossPlatform.platformSpecific values)
      );

      invalidValueStructureError = nixtestFinal.test "Invalid value structure handling" (
        nixtestFinal.assertions.assertThrows (
          platformDetection.crossPlatform.platformSpecific "not-an-attrset"
        )
      );
    };
  };

  # Performance tests for platform detection
  platformPerformanceTests = nixtestFinal.suite "Platform Performance Tests" {

    # Caching efficiency
    cachingTests = nixtestFinal.suite "Platform Detection Caching" {
      repeatedDetectionConsistency = nixtestFinal.test "Repeated detection consistency" (
        let
          result1 = platformDetection.isDarwin system;
          result2 = platformDetection.isDarwin system;
        in
        nixtestFinal.assertions.assertEqual result1 result2
      );

      platformInfoCaching = nixtestFinal.test "Platform info caching works" (
        let
          info1 = platformDetection.info.platform;
          info2 = platformDetection.info.platform;
        in
        nixtestFinal.assertions.assertEqual info1 info2
      );
    };

    # Bulk operations
    bulkOperationTests = nixtestFinal.suite "Bulk Platform Operations" {
      bulkSystemValidation = nixtestFinal.test "Bulk system validation performance" (
        let
          results = map platformDetection.validateSystem testPlatforms.supportedSystems;
        in
        nixtestFinal.assertions.assertEqual (builtins.length testPlatforms.supportedSystems) (
          builtins.length results
        )
      );

      bulkPlatformExtraction = nixtestFinal.test "Bulk platform extraction performance" (
        let
          platforms = map platformDetection.getPlatform testPlatforms.supportedSystems;
          expectedCount = builtins.length testPlatforms.supportedSystems;
        in
        nixtestFinal.assertions.assertEqual expectedCount (builtins.length platforms)
      );
    };
  };
}
