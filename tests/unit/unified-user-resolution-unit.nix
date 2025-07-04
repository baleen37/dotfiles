{ pkgs, lib, ... }:

let
  # Test the new unified user resolution system
  getUserUnified = import ../../lib/user-resolution.nix;

  # Common test environment
  mockEnv = {
    USER = "testuser";
    SUDO_USER = "sudouser";
  };

  # Test the unified system against all previous functionality
  testScenarios = {
    # Basic functionality tests
    basicStringMode = {
      assertion = (getUserUnified { inherit mockEnv; }) == "sudouser";
      description = "Unified system should return string in default mode";
    };

    extendedObjectMode = {
      assertion = (getUserUnified {
        inherit mockEnv;
        returnFormat = "extended";
      }).user == "sudouser";
      description = "Unified system should return object in extended mode";
    };

    # Priority tests
    sudoUserPriority = {
      assertion = (getUserUnified {
        mockEnv = mockEnv;
        allowSudoUser = true;
      }) == "sudouser";
      description = "Unified system should prioritize SUDO_USER when allowed";
    };

    sudoUserDisabled = {
      assertion = (getUserUnified {
        mockEnv = mockEnv;
        allowSudoUser = false;
      }) == "testuser";
      description = "Unified system should ignore SUDO_USER when disabled";
    };

    # Extended functionality tests
    extendedHomePath = {
      assertion = (getUserUnified {
        inherit mockEnv;
        platform = "linux";
        returnFormat = "extended";
      }).homePath == "/home/sudouser";
      description = "Unified system should generate correct home path in extended mode";
    };

    extendedUtilities = {
      assertion = (getUserUnified {
        inherit mockEnv;
        platform = "linux";
        returnFormat = "extended";
      }).utils.getConfigPath == "/home/sudouser/.config";
      description = "Unified system should provide utility functions in extended mode";
    };

    # Platform detection
    platformDetection = {
      assertion = (getUserUnified {
        inherit mockEnv;
        platform = "darwin";
        returnFormat = "extended";
      }).platform == "darwin";
      description = "Unified system should detect platform correctly";
    };

    # Auto-detection capability
    autoDetectionFallback = {
      assertion =
        let result = getUserUnified {
          mockEnv = { };
          enableAutoDetect = true;
          default = "fallback";
        };
        in builtins.isString result && result != "";
      description = "Unified system should handle auto-detection gracefully";
    };

    # Backward compatibility tests
    stringCompatibility = {
      assertion = builtins.isString (getUserUnified { inherit mockEnv; });
      description = "Unified system should return string by default for backward compatibility";
    };

    extendedCompatibility = {
      assertion = builtins.isAttrs (getUserUnified {
        inherit mockEnv;
        returnFormat = "extended";
      });
      description = "Unified system should return attrs in extended mode";
    };

    # Validation tests
    validUserHandling = {
      assertion = (getUserUnified {
        mockEnv = { USER = "valid_user123"; };
      }) == "valid_user123";
      description = "Unified system should handle valid usernames correctly";
    };

    # Debug mode test
    debugModeSupport = {
      assertion = (getUserUnified {
        inherit mockEnv;
        debugMode = true;
      }) == "sudouser";
      description = "Unified system should support debug mode";
    };

    # Environment variable customization
    customEnvVar = {
      assertion = (getUserUnified {
        mockEnv = { CUSTOM_USER = "customuser"; };
        envVar = "CUSTOM_USER";
        allowSudoUser = false;
      }) == "customuser";
      description = "Unified system should support custom environment variables";
    };

    # All features integration test
    fullFeatureIntegration = {
      assertion =
        let result = getUserUnified {
          inherit mockEnv;
          platform = "darwin";
          returnFormat = "extended";
          debugMode = false;
          allowSudoUser = true;
        };
        in result.user == "sudouser" &&
           result.platform == "darwin" &&
           result.homePath == "/Users/sudouser" &&
           result.utils.isDarwin == true &&
           result.utils.isLinux == false;
      description = "Unified system should integrate all features correctly";
    };
  };

in {
  # Export test scenarios
  tests = testScenarios;

  # Export test data for debugging
  testData = {
    inherit mockEnv;
    unifiedResults = {
      string = getUserUnified { inherit mockEnv; };
      extended = getUserUnified { inherit mockEnv; returnFormat = "extended"; };
    };
  };
}
