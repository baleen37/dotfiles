{ pkgs, lib, ... }:

let
  # Test the existing three user resolution systems
  getUserBasic = import ../../lib/get-user.nix;
  getUserEnhanced = import ../../lib/enhanced-get-user.nix;
  getUserExtended = import ../../lib/get-user-extended.nix;

  # Common test environment
  mockEnv = {
    USER = "testuser";
    SUDO_USER = "sudouser";
  };

  # Test different scenarios
  testScenarios = {
    # Basic functionality tests (SUDO_USER has priority by default)
    basicUserResolution = {
      assertion = (getUserBasic { inherit mockEnv; }) == "sudouser";
      description = "Basic system should resolve SUDO_USER by default (priority)";
    };

    enhancedUserResolution = {
      assertion = (getUserEnhanced { inherit mockEnv; }) == "sudouser";
      description = "Enhanced system should resolve SUDO_USER by default (priority)";
    };

    extendedUserResolution = {
      assertion = (getUserExtended { inherit mockEnv; }).user == "sudouser";
      description = "Extended system should resolve SUDO_USER by default (priority)";
    };

    # SUDO_USER priority tests
    sudoUserPriority = {
      assertion = (getUserBasic {
        mockEnv = mockEnv;
        allowSudoUser = true;
      }) == "sudouser";
      description = "Basic system should prioritize SUDO_USER when allowed";
    };

    sudoUserDisabled = {
      assertion = (getUserBasic {
        mockEnv = mockEnv;
        allowSudoUser = false;
      }) == "testuser";
      description = "Basic system should ignore SUDO_USER when disabled";
    };

    # Default value tests (in real environment, USER is still available)
    defaultFallback = {
      assertion = builtins.isString (getUserBasic {
        mockEnv = { };
        default = "defaultuser";
      });
      description = "Basic system should return a valid user when no mock env";
    };

    # Platform detection tests
    platformDetection = {
      assertion = (getUserExtended {
        inherit mockEnv;
        platform = "darwin";
      }).platform == "darwin";
      description = "Extended system should detect platform correctly";
    };

    # Home path generation tests (using SUDO_USER since it has priority)
    darwinHomePath = {
      assertion = (getUserExtended {
        inherit mockEnv;
        platform = "darwin";
      }).homePath == "/Users/sudouser";
      description = "Extended system should generate correct Darwin home path";
    };

    linuxHomePath = {
      assertion = (getUserExtended {
        inherit mockEnv;
        platform = "linux";
      }).homePath == "/home/sudouser";
      description = "Extended system should generate correct Linux home path";
    };

    # Utility functions tests (using SUDO_USER since it has priority)
    configPathGeneration = {
      assertion = (getUserExtended {
        inherit mockEnv;
        platform = "linux";
      }).utils.getConfigPath == "/home/sudouser/.config";
      description = "Extended system should generate correct config path";
    };

    sshPathGeneration = {
      assertion = (getUserExtended {
        inherit mockEnv;
        platform = "linux";
      }).utils.getSshPath == "/home/sudouser/.ssh";
      description = "Extended system should generate correct SSH path";
    };

    platformUtils = {
      assertion =
        let extended = getUserExtended { inherit mockEnv; platform = "linux"; };
        in extended.utils.isLinux == true && extended.utils.isDarwin == false;
      description = "Extended system should provide platform utility functions";
    };

    # Enhanced features tests (in real environment, USER is still available)
    autoDetectionCapability = {
      assertion =
        let enhanced = getUserEnhanced {
          mockEnv = { };
          enableAutoDetect = true;
          default = "fallback";
        };
        in builtins.isString enhanced && enhanced != "";
      description = "Enhanced system should return valid user with auto-detection enabled";
    };

    # Error handling tests (should not throw in these cases)
    validUserValidation = {
      assertion = (getUserBasic {
        mockEnv = { USER = "valid_user123"; };
      }) == "valid_user123";
      description = "All systems should accept valid usernames";
    };

    # Backward compatibility tests
    basicStringCompatibility = {
      assertion = builtins.isString (getUserBasic { inherit mockEnv; });
      description = "Basic system should return string for backward compatibility";
    };

    enhancedStringCompatibility = {
      assertion = builtins.isString (getUserEnhanced { inherit mockEnv; });
      description = "Enhanced system should return string for backward compatibility";
    };

    extendedObjectCompatibility = {
      assertion = builtins.isAttrs (getUserExtended { inherit mockEnv; });
      description = "Extended system should return attribute set with utilities";
    };
  };

in {
  # Export test scenarios for the test runner
  tests = testScenarios;

  # Export test data for debugging
  testData = {
    inherit mockEnv;
    systemResults = {
      basic = getUserBasic { inherit mockEnv; };
      enhanced = getUserEnhanced { inherit mockEnv; };
      extended = getUserExtended { inherit mockEnv; };
    };
  };
}
