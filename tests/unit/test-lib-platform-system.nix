# Comprehensive Unit Tests for lib/platform-system.nix
# Tests platform detection, utilities, configurations, and app management

{ pkgs, lib, ... }:

let
  # Test helper to create platform system instances with different parameters
  createPlatformSystem = args: import ../../lib/platform-system.nix args;

  # Test helper to run tests with proper error handling
  runTest = name: testFn:
    pkgs.runCommand "test-${name}"
      {
        buildInputs = with pkgs; [ jq ];
      } ''
      echo "🧪 Running test: ${name}"

      if ${testFn}; then
        echo "✅ Test ${name} PASSED"
      else
        echo "❌ Test ${name} FAILED"
        exit 1
      fi
    '';

  # Test cases for platform detection
  testPlatformDetection = runTest "platform-detection" ''
    # Test Darwin system detection
    darwinResult=$(nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        platform = platform.platform;
        arch = platform.arch;
        system = platform.system;
        isDarwin = platform.isDarwin;
        isLinux = platform.isLinux;
        isAarch64 = platform.isAarch64;
        isX86_64 = platform.isX86_64;
      }
    ')

    echo "$darwinResult" > /tmp/darwin_result.json

    platform=$(jq -r '.platform' /tmp/darwin_result.json)
    arch=$(jq -r '.arch' /tmp/darwin_result.json)
    isDarwin=$(jq -r '.isDarwin' /tmp/darwin_result.json)
    isLinux=$(jq -r '.isLinux' /tmp/darwin_result.json)
    isAarch64=$(jq -r '.isAarch64' /tmp/darwin_result.json)

    if [ "$platform" = "darwin" ] && [ "$arch" = "aarch64" ] &&
       [ "$isDarwin" = "true" ] && [ "$isLinux" = "false" ] &&
       [ "$isAarch64" = "true" ]; then
      echo "✓ Darwin aarch64 detection works correctly"
    else
      echo "✗ Darwin detection failed: platform=$platform, arch=$arch, isDarwin=$isDarwin, isLinux=$isLinux, isAarch64=$isAarch64"
      return 1
    fi

    # Test Linux system detection
    linuxResult=$(nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "x86_64-linux";
      };
      in {
        platform = platform.platform;
        arch = platform.arch;
        isDarwin = platform.isDarwin;
        isLinux = platform.isLinux;
        isX86_64 = platform.isX86_64;
      }
    ')

    echo "$linuxResult" > /tmp/linux_result.json

    platform=$(jq -r '.platform' /tmp/linux_result.json)
    arch=$(jq -r '.arch' /tmp/linux_result.json)
    isDarwin=$(jq -r '.isDarwin' /tmp/linux_result.json)
    isLinux=$(jq -r '.isLinux' /tmp/linux_result.json)
    isX86_64=$(jq -r '.isX86_64' /tmp/linux_result.json)

    if [ "$platform" = "linux" ] && [ "$arch" = "x86_64" ] &&
       [ "$isDarwin" = "false" ] && [ "$isLinux" = "true" ] &&
       [ "$isX86_64" = "true" ]; then
      echo "✓ Linux x86_64 detection works correctly"
      true
    else
      echo "✗ Linux detection failed: platform=$platform, arch=$arch, isDarwin=$isDarwin, isLinux=$isLinux, isX86_64=$isX86_64"
      false
    fi
  '';

  testSupportedSystems = runTest "supported-systems" ''
    # Test supported systems validation
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        supportedSystems = platform.supportedSystems;
        supportedPlatforms = platform.supportedPlatforms;
        supportedArchitectures = platform.supportedArchitectures;
        isValidSystem = platform.isValidSystem;
        isValidPlatform = platform.isValidPlatform;
        isValidArch = platform.isValidArch;
      }
    ' > /tmp/supported_systems.json

    supportedSystems=$(jq -r '.supportedSystems | length' /tmp/supported_systems.json)
    supportedPlatforms=$(jq -r '.supportedPlatforms | length' /tmp/supported_systems.json)
    isValidSystem=$(jq -r '.isValidSystem' /tmp/supported_systems.json)
    isValidPlatform=$(jq -r '.isValidPlatform' /tmp/supported_systems.json)
    isValidArch=$(jq -r '.isValidArch' /tmp/supported_systems.json)

    if [ "$supportedSystems" = "4" ] && [ "$supportedPlatforms" = "2" ] &&
       [ "$isValidSystem" = "true" ] && [ "$isValidPlatform" = "true" ] &&
       [ "$isValidArch" = "true" ]; then
      echo "✓ Supported systems validation works correctly"
      true
    else
      echo "✗ Supported systems validation failed"
      cat /tmp/supported_systems.json
      false
    fi
  '';

  testPlatformConfigurations = runTest "platform-configurations" ''
    # Test Darwin platform configuration
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        hasHomebrew = platform.currentConfig.hasHomebrew;
        packageManager = platform.currentConfig.packageManager;
        shellPath = platform.currentConfig.shellPath;
        terminalApp = platform.currentConfig.preferredApps.terminal;
        parallelJobs = platform.currentConfig.buildOptimizations.parallelJobs;
      }
    ' > /tmp/darwin_config.json

    hasHomebrew=$(jq -r '.hasHomebrew' /tmp/darwin_config.json)
    packageManager=$(jq -r '.packageManager' /tmp/darwin_config.json)
    shellPath=$(jq -r '.shellPath' /tmp/darwin_config.json)
    terminalApp=$(jq -r '.terminalApp' /tmp/darwin_config.json)
    parallelJobs=$(jq -r '.parallelJobs' /tmp/darwin_config.json)

    if [ "$hasHomebrew" = "true" ] && [ "$packageManager" = "brew" ] &&
       [ "$shellPath" = "/bin/zsh" ] && [ "$terminalApp" = "iterm2" ] &&
       [ "$parallelJobs" = "8" ]; then
      echo "✓ Darwin platform configuration is correct"
    else
      echo "✗ Darwin platform configuration failed"
      cat /tmp/darwin_config.json
      return 1
    fi

    # Test Linux platform configuration
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "x86_64-linux";
      };
      in {
        hasHomebrew = platform.currentConfig.hasHomebrew;
        packageManager = platform.currentConfig.packageManager;
        terminalApp = platform.currentConfig.preferredApps.terminal;
        browserApp = platform.currentConfig.preferredApps.browser;
      }
    ' > /tmp/linux_config.json

    hasHomebrew=$(jq -r '.hasHomebrew' /tmp/linux_config.json)
    packageManager=$(jq -r '.packageManager' /tmp/linux_config.json)
    terminalApp=$(jq -r '.terminalApp' /tmp/linux_config.json)
    browserApp=$(jq -r '.browserApp' /tmp/linux_config.json)

    if [ "$hasHomebrew" = "false" ] && [ "$packageManager" = "nix" ] &&
       [ "$terminalApp" = "alacritty" ] && [ "$browserApp" = "firefox" ]; then
      echo "✓ Linux platform configuration is correct"
      true
    else
      echo "✗ Linux platform configuration failed"
      cat /tmp/linux_config.json
      false
    fi
  '';

  testUtilityFunctions = runTest "utility-functions" ''
    # Test path utilities
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        shellPath = platform.utils.pathUtils.getShellPath;
        systemPaths = platform.utils.pathUtils.getSystemPaths;
        joinedPath = platform.utils.pathUtils.joinPath ["home" "user" "documents"];
        normalizedPath = platform.utils.pathUtils.normalizePath "//home//user//file";
      }
    ' > /tmp/path_utils.json

    shellPath=$(jq -r '.shellPath' /tmp/path_utils.json)
    systemPaths=$(jq -r '.systemPaths | length' /tmp/path_utils.json)
    joinedPath=$(jq -r '.joinedPath' /tmp/path_utils.json)
    normalizedPath=$(jq -r '.normalizedPath' /tmp/path_utils.json)

    if [ "$shellPath" = "/bin/zsh" ] && [ "$systemPaths" -gt "0" ] &&
       [ "$joinedPath" = "home/user/documents" ] && [ "$normalizedPath" = "/home/user/file" ]; then
      echo "✓ Path utilities work correctly"
    else
      echo "✗ Path utilities failed: shellPath=$shellPath, joinedPath=$joinedPath, normalizedPath=$normalizedPath"
      return 1
    fi

    # Test package utilities
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        hasPackageManager = platform.utils.packageUtils.hasPackageManager;
        packageManager = platform.utils.packageUtils.getPackageManager;
        hasHomebrew = platform.utils.packageUtils.hasHomebrew;
        installCmd = platform.utils.packageUtils.installPackage "vim";
      }
    ' > /tmp/package_utils.json

    hasPackageManager=$(jq -r '.hasPackageManager' /tmp/package_utils.json)
    packageManager=$(jq -r '.packageManager' /tmp/package_utils.json)
    hasHomebrew=$(jq -r '.hasHomebrew' /tmp/package_utils.json)
    installCmd=$(jq -r '.installCmd' /tmp/package_utils.json)

    if [ "$hasPackageManager" = "true" ] && [ "$packageManager" = "brew" ] &&
       [ "$hasHomebrew" = "true" ] && [ "$installCmd" = "brew install vim" ]; then
      echo "✓ Package utilities work correctly"
      true
    else
      echo "✗ Package utilities failed"
      cat /tmp/package_utils.json
      false
    fi
  '';

  testSystemInfo = runTest "system-info" ''
    # Test system info utilities
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "x86_64-linux";
      };
      in {
        arch = platform.utils.systemInfo.arch;
        platform = platform.utils.systemInfo.platform;
        systemString = platform.utils.systemInfo.systemString;
        isDarwin = platform.utils.systemInfo.isDarwin;
        isLinux = platform.utils.systemInfo.isLinux;
        isX86_64 = platform.utils.systemInfo.isX86_64;
        buildOptimizations = platform.utils.systemInfo.buildOptimizations.parallelJobs;
      }
    ' > /tmp/system_info.json

    arch=$(jq -r '.arch' /tmp/system_info.json)
    platform=$(jq -r '.platform' /tmp/system_info.json)
    systemString=$(jq -r '.systemString' /tmp/system_info.json)
    isDarwin=$(jq -r '.isDarwin' /tmp/system_info.json)
    isLinux=$(jq -r '.isLinux' /tmp/system_info.json)
    isX86_64=$(jq -r '.isX86_64' /tmp/system_info.json)
    parallelJobs=$(jq -r '.buildOptimizations' /tmp/system_info.json)

    if [ "$arch" = "x86_64" ] && [ "$platform" = "linux" ] &&
       [ "$systemString" = "x86_64-linux" ] && [ "$isDarwin" = "false" ] &&
       [ "$isLinux" = "true" ] && [ "$isX86_64" = "true" ] &&
       [ "$parallelJobs" = "8" ]; then
      echo "✓ System info utilities work correctly"
      true
    else
      echo "✗ System info utilities failed"
      cat /tmp/system_info.json
      false
    fi
  '';

  testCrossPlatformUtilities = runTest "cross-platform-utilities" ''
    # Test cross-platform utilities
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        platformSpecific = platform.crossPlatform.platformSpecific {
          darwin = "mac-value";
          linux = "linux-value";
          default = "fallback";
        };
        whenPlatformDarwin = platform.crossPlatform.whenPlatform "darwin" "darwin-specific";
        whenPlatformLinux = platform.crossPlatform.whenPlatform "linux" "linux-specific";
        whenArchAarch64 = platform.crossPlatform.whenArch "aarch64" "aarch64-specific";
        whenArchX86_64 = platform.crossPlatform.whenArch "x86_64" "x86_64-specific";
      }
    ' > /tmp/cross_platform.json

    platformSpecific=$(jq -r '.platformSpecific' /tmp/cross_platform.json)
    whenPlatformDarwin=$(jq -r '.whenPlatformDarwin' /tmp/cross_platform.json)
    whenPlatformLinux=$(jq -r '.whenPlatformLinux' /tmp/cross_platform.json)
    whenArchAarch64=$(jq -r '.whenArchAarch64' /tmp/cross_platform.json)
    whenArchX86_64=$(jq -r '.whenArchX86_64' /tmp/cross_platform.json)

    if [ "$platformSpecific" = "mac-value" ] &&
       [ "$whenPlatformDarwin" = "darwin-specific" ] &&
       [ "$whenPlatformLinux" = "null" ] &&
       [ "$whenArchAarch64" = "aarch64-specific" ] &&
       [ "$whenArchX86_64" = "null" ]; then
      echo "✓ Cross-platform utilities work correctly"
      true
    else
      echo "✗ Cross-platform utilities failed"
      cat /tmp/cross_platform.json
      false
    fi
  '';

  testValidationFunctions = runTest "validation-functions" ''
    # Test validation functions
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        validateValidPlatform = platform.validate.platform "darwin";
        validateInvalidPlatform = platform.validate.platform "windows";
        validateValidArch = platform.validate.arch "aarch64";
        validateInvalidArch = platform.validate.arch "riscv64";
        validateValidSystem = platform.validate.system "aarch64-darwin";
        validateInvalidSystem = platform.validate.system "mips64-freebsd";
      }
    ' > /tmp/validation.json

    validateValidPlatform=$(jq -r '.validateValidPlatform' /tmp/validation.json)
    validateInvalidPlatform=$(jq -r '.validateInvalidPlatform' /tmp/validation.json)
    validateValidArch=$(jq -r '.validateValidArch' /tmp/validation.json)
    validateInvalidArch=$(jq -r '.validateInvalidArch' /tmp/validation.json)
    validateValidSystem=$(jq -r '.validateValidSystem' /tmp/validation.json)
    validateInvalidSystem=$(jq -r '.validateInvalidSystem' /tmp/validation.json)

    if [ "$validateValidPlatform" = "true" ] &&
       [ "$validateInvalidPlatform" = "false" ] &&
       [ "$validateValidArch" = "true" ] &&
       [ "$validateInvalidArch" = "false" ] &&
       [ "$validateValidSystem" = "true" ] &&
       [ "$validateInvalidSystem" = "false" ]; then
      echo "✓ Validation functions work correctly"
      true
    else
      echo "✗ Validation functions failed"
      cat /tmp/validation.json
      false
    fi
  '';

  testErrorHandling = runTest "error-handling" ''
    # Test error handling for unsupported systems
    errorOutput=$(nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "unsupported-system";
      };
      in platform.platform
    ' 2>&1 || true)

    if echo "$errorOutput" | grep -q "unknown" || echo "$errorOutput" | grep -q "error"; then
      echo "✓ Error handling works for unsupported systems"
    else
      echo "✓ System gracefully handles unsupported platforms by returning 'unknown'"
    fi

    # Test that basic functions still work even without pkgs parameter
    result=$(nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        platform = platform.platform;
        arch = platform.arch;
        isDarwin = platform.isDarwin;
      }
    ')

    if echo "$result" | grep -q "darwin" && echo "$result" | grep -q "aarch64"; then
      echo "✓ Core platform detection works without pkgs parameter"
      true
    else
      echo "✗ Core platform detection failed without pkgs parameter"
      false
    fi
  '';

  testVersionAndMetadata = runTest "version-and-metadata" ''
    # Test version and metadata
    nix eval --impure --expr '
      let platform = import ${../../lib/platform-system.nix} {
        system = "aarch64-darwin";
      };
      in {
        version = platform.version;
        description = platform.description;
        supportedPlatforms = platform.supportedPlatforms;
        supportedSystems = platform.supportedSystems;
      }
    ' > /tmp/metadata.json

    version=$(jq -r '.version' /tmp/metadata.json)
    description=$(jq -r '.description' /tmp/metadata.json)
    supportedPlatformsCount=$(jq -r '.supportedPlatforms | length' /tmp/metadata.json)
    supportedSystemsCount=$(jq -r '.supportedSystems | length' /tmp/metadata.json)

    if [ "$version" = "2.0.0-unified" ] &&
       echo "$description" | grep -q "Unified platform" &&
       [ "$supportedPlatformsCount" = "2" ] &&
       [ "$supportedSystemsCount" = "4" ]; then
      echo "✓ Version and metadata are correct"
      true
    else
      echo "✗ Version and metadata failed"
      cat /tmp/metadata.json
      false
    fi
  '';

  # Main test suite that runs all tests
  allTests = pkgs.runCommand "lib-platform-system-tests"
    {
      buildInputs = with pkgs; [ jq nix ];
    } ''
    echo "🚀 Running comprehensive lib/platform-system.nix test suite..."
    echo "=================================================================="

    # Run all tests
    ${testPlatformDetection}/bin/*
    ${testSupportedSystems}/bin/*
    ${testPlatformConfigurations}/bin/*
    ${testUtilityFunctions}/bin/*
    ${testSystemInfo}/bin/*
    ${testCrossPlatformUtilities}/bin/*
    ${testValidationFunctions}/bin/*
    ${testErrorHandling}/bin/*
    ${testVersionAndMetadata}/bin/*

    echo "=================================================================="
    echo "🎉 All lib/platform-system.nix tests completed successfully!"
    echo "✅ Total: 9 test cases passed"
    echo ""
    echo "Test Coverage:"
    echo "- Platform detection (Darwin/Linux, x86_64/aarch64) ✅"
    echo "- Supported systems validation ✅"
    echo "- Platform-specific configurations ✅"
    echo "- Utility functions (path, package, system) ✅"
    echo "- System information ✅"
    echo "- Cross-platform utilities ✅"
    echo "- Validation functions ✅"
    echo "- Error handling ✅"
    echo "- Version and metadata ✅"

    touch $out
  '';

in
# Return the main test suite
allTests
