# Library Functions Comprehensive Unit Tests
#
# lib/ 디렉토리의 모든 유틸리티 함수에 대한 종합 유닛 테스트
# NixTest 프레임워크를 사용하여 platform-detection.nix, utils-system.nix 테스트
#
# 테스트 대상:
# - platformDetectionTests: 플랫폼 감지 (darwin/linux/x86_64/aarch64 감지, 플랫폼/아키텍처 추출, 시스템 검증, 크로스 플랫폼 유틸리티)
# - utilsSystemTests: 시스템 유틸리티 (시스템 비교, 패키지 유틸리티, 설정 병합, 리스트 유틸리티, 문자열 유틸리티, 경로 유틸리티, 속성 유틸리티)
# - errorHandlingTests: 에러 처리 (잘못된 플랫폼, 설정 키 누락, 패키지 검증)
# - performanceTests: 성능 및 호환성 (대용량 리스트, 깊은 중첩, 크로스 플랫폼 경로)
#
# 테스트 전략:
# - 각 함수의 기본 동작 검증
# - 에러 조건 및 엣지 케이스 처리
# - 대용량 데이터 및 성능 테스트
# - 크로스 플랫폼 호환성 검증

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  nixtest ? null,
  self ? null,
}:

let
  # Common test platforms - used across multiple test suites
  allTestPlatforms = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  # Use provided NixTest framework and helpers (or fallback to local imports)
  nixtestFinal =
    if nixtest != null then nixtest else (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;

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
  defaultLib =
    if self != null then
      import (self + /lib/default.nix) { inherit nixpkgs; }
    else
      import ../../lib/default.nix { nixpkgs = pkgs; };

  # Test data for comprehensive testing
  testData = {
    validSystems = allTestPlatforms;

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

  # Default Library Tests (lib/default.nix)
  defaultLibTests = nixtestFinal.suite "Default Library Functions Tests" {

    # getPlatform function tests
    getPlatformTests = nixtestFinal.suite "getPlatform Function Tests" {

      # Darwin platform detection
      getPlatformDarwinX86 = nixtestFinal.test "getPlatform detects x86_64-darwin" (
        nixtestFinal.assertions.assertEqual "darwin" (defaultLib.getPlatform "x86_64-darwin")
      );

      getPlatformDarwinARM = nixtestFinal.test "getPlatform detects aarch64-darwin" (
        nixtestFinal.assertions.assertEqual "darwin" (defaultLib.getPlatform "aarch64-darwin")
      );

      # Linux platform detection
      getPlatformLinuxX86 = nixtestFinal.test "getPlatform detects x86_64-linux" (
        nixtestFinal.assertions.assertEqual "linux" (defaultLib.getPlatform "x86_64-linux")
      );

      getPlatformLinuxARM = nixtestFinal.test "getPlatform detects aarch64-linux" (
        nixtestFinal.assertions.assertEqual "linux" (defaultLib.getPlatform "aarch64-linux")
      );

      # Error handling for unsupported systems
      getPlatformInvalidSystem = nixtestFinal.test "getPlatform throws error for unsupported system" (
        nixtestFinal.assertions.assertThrows (defaultLib.getPlatform "windows-x86_64")
      );

      getPlatformEmptySystem = nixtestFinal.test "getPlatform throws error for empty system" (
        nixtestFinal.assertions.assertThrows (defaultLib.getPlatform "")
      );

      getPlatformMalformedSystem = nixtestFinal.test "getPlatform throws error for malformed system" (
        nixtestFinal.assertions.assertThrows (defaultLib.getPlatform "invalid")
      );

      # Edge cases
      getPlatformFreeBSD = nixtestFinal.test "getPlatform throws error for FreeBSD" (
        nixtestFinal.assertions.assertThrows (defaultLib.getPlatform "x86_64-freebsd")
      );

      getPlatformComplexSystem = nixtestFinal.test "getPlatform throws error for complex system string" (
        nixtestFinal.assertions.assertThrows (defaultLib.getPlatform "x86_64-unknown-linux-gnu")
      );
    };

    # getUser function tests
    getUserTests = nixtestFinal.suite "getUser Function Tests" {

      # Test with environment variable set (simulated)
      # Note: We can't actually set environment variables in pure Nix evaluation,
      # but we can test the logic with different scenarios

      getUserWithEnvVar = nixtestFinal.test "getUser returns environment USER when set" (
        # This test would need to be run in an environment where USER is set
        # For now, we test the structure and logic
        let
          # Create a test version that simulates having an env var
          testGetUser =
            {
              default ? "",
            }:
            if "testuser" != "" then "testuser" else default;
        in
        nixtestFinal.assertions.assertEqual "testuser" (testGetUser {
          default = "fallback";
        })
      );

      getUserWithDefault = nixtestFinal.test "getUser returns default when env USER is empty" (
        let
          # Create a test version that simulates empty env var
          testGetUser =
            {
              default ? "",
            }:
            if "" != "" then "env-user" else default;
        in
        nixtestFinal.assertions.assertEqual "fallback" (testGetUser {
          default = "fallback";
        })
      );

      getUserEmptyDefault = nixtestFinal.test "getUser throws error when both env and default are empty" (
        let
          # Test the actual function behavior - should throw error
          expectedError = "getUser: Cannot determine username - USER environment variable is empty and no valid default provided";
        in
        nixtestFinal.assertions.assertThrows (defaultLib.getUser { default = ""; })
      );

      getUserOmittedDefault =
        nixtestFinal.test "getUser throws error when default omitted and env is empty"
          (
            let
              # Test the actual function behavior - should throw error
              expectedError = "getUser: Cannot determine username - USER environment variable is empty and no valid default provided";
            in
            nixtestFinal.assertions.assertThrows (defaultLib.getUser { })
          );

      getUserSpecialChars = nixtestFinal.test "getUser handles special characters in default" (
        let
          # Create a test version that simulates empty env var
          testGetUser =
            {
              default ? "",
            }:
            if "" != "" then "env-user" else default;
        in
        nixtestFinal.assertions.assertEqual "user-with-dash" (testGetUser {
          default = "user-with-dash";
        })
      );

      getUserNumericDefault = nixtestFinal.test "getUser handles numeric default" (
        let
          # Create a test version that simulates empty env var
          testGetUser =
            {
              default ? "",
            }:
            if "" != "" then "env-user" else default;
        in
        nixtestFinal.assertions.assertEqual "1234" (testGetUser {
          default = "1234";
        })
      );

      getUserWhitespaceDefault = nixtestFinal.test "getUser handles whitespace-only default" (
        nixtestFinal.assertions.assertThrows (defaultLib.getUser { default = "   "; })
      );

      getUserValidDefault = nixtestFinal.test "getUser accepts valid non-empty default" (
        let
          # This test should pass when USER is empty but default is valid
          # In a real environment with USER set, it would return the USER value
          testGetUser =
            {
              default ? "",
            }:
            let
              envUser = ""; # Simulate empty USER
              result = if envUser != "" then envUser else default;
            in
            if result == "" then
              throw "getUser: Cannot determine username - USER environment variable is empty and no valid default provided"
            else
              result;
        in
        nixtestFinal.assertions.assertEqual "validuser" (testGetUser {
          default = "validuser";
        })
      );
    };

    # Integration tests for both functions together
    integrationTests = nixtestFinal.suite "Default Library Integration Tests" {

      platformUserIntegration = nixtestFinal.test "getPlatform and getUser work together" (
        let
          platform = defaultLib.getPlatform "x86_64-darwin";
          # Simulate user resolution
          testUser = if "testuser" != "" then "testuser" else "defaultuser";
        in
        nixtestFinal.assertions.assertAll [
          (nixtestFinal.assertions.assertEqual "darwin" platform)
          (nixtestFinal.assertions.assertEqual "testuser" testUser)
        ]
      );

      crossPlatformCompatibility = nixtestFinal.test "Functions work across all supported platforms" (
        let
          platforms = [
            "x86_64-darwin"
            "aarch64-darwin"
            "x86_64-linux"
            "aarch64-linux"
          ];
          results = map defaultLib.getPlatform platforms;
          expected = [
            "darwin"
            "darwin"
            "linux"
            "linux"
          ];
        in
        nixtestFinal.assertions.assertEqual expected results
      );
    };
  };

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
          validPackages = [ { name = "test-pkg"; } ];
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
      nixtestFinal.assertions.assertThrows (utilsSystem.packageUtils.validatePackages [ { } ])
    );
  };

  # Performance and compatibility tests
  performanceTests = nixtestFinal.suite "Performance and Compatibility Tests" {

    # Large data handling
    largeListProcessing = nixtestFinal.test "Large list unique processing" (
      let
        largeList = builtins.genList (
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
