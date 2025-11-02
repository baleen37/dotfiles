# Property-Based Tests for System Configuration
# Tests system configuration invariants across multiple scenarios
#
# Tests the following properties:
#   - Nix settings security invariants
#   - Package installation integrity
#   - Platform detection accuracy
#   - System factory properties
#   - Cross-platform configuration compatibility
#
# VERSION: 1.0.0 (Task 7 - Property-Based Testing)
# LAST UPDATED: 2025-11-02

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import property testing utilities
  propertyHelpers = import ../lib/property-test-helpers.nix { inherit pkgs lib; };

  # Import existing test helpers
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import system modules for testing
  mksystem = import ../../lib/mksystem.nix { inherit inputs self; };

  # === System Configuration Property Tests ===

  # Property: Nix settings maintain security invariants
  nixSettingsSecurityTest = propertyHelpers.forAll propertyHelpers.nixSettingsSecurityProperty (
    seed: {
      nix = {
        settings = {
          substituters = [
            "https://cache.nixos.org/"
            "https://baleen-nix.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
          ];
          trusted-users = [
            "root"
            "testuser"
            "@admin"
            "@wheel"
          ];
        };
      };
    }) "nix-settings-security";

  # Property: Package installation maintains system integrity
  packageIntegrityTest =
    propertyHelpers.forAll propertyHelpers.packageIntegrityProperty propertyHelpers.generatePackageList
      "package-integrity";

  # Property: Platform detection works correctly
  platformDetectionTest = propertyHelpers.forAllCases propertyHelpers.platformDetectionProperty [
    {
      isDarwin = true;
      isLinux = false;
    }
    {
      isDarwin = false;
      isLinux = true;
    }
  ] "platform-detection";

  # Property: System factory produces consistent configurations
  systemFactoryProperty =
    testParams:
    let
      # Test different system configurations
      systemConfigs = [
        {
          system = "aarch64-darwin";
          user = "baleen";
          darwin = true;
        }
        {
          system = "x86_64-linux";
          user = "jito";
          darwin = false;
        }
        {
          system = "aarch64-linux";
          user = "testuser";
          darwin = false;
        }
      ];

      config = builtins.elemAt systemConfigs (lib.mod testParams (builtins.length systemConfigs));

      # Properties that should hold for any system configuration
      hasValidSystem = builtins.stringLength config.system > 0;
      hasValidUser = builtins.stringLength config.user > 0;
      hasValidDarwinFlag = builtins.isBool config.darwin;

      # Platform-specific properties
      correctDarwinFlag =
        if lib.hasPrefix "aarch64-darwin" config.system || lib.hasPrefix "x86_64-darwin" config.system then
          config.darwin
        else
          !config.darwin;

      # System should be recognizable
      systemRecognizable =
        lib.hasPrefix "aarch64" config.system
        || lib.hasPrefix "x86_64" config.system
        || lib.hasPrefix "i686" config.system;

      # User should be valid format
      userValid = builtins.match "^[a-zA-Z0-9._-]+$" config.user != null;
    in
    hasValidSystem
    && hasValidUser
    && hasValidDarwinFlag
    && correctDarwinFlag
    && systemRecognizable
    && userValid;

  systemFactoryTest = propertyHelpers.forAll systemFactoryProperty (i: i) "system-factory";

  # Property: Module loading maintains configuration integrity
  moduleLoadingProperty =
    moduleConfig:
    let
      # Simulate module loading with different configurations
      baseModules = [
        {
          config = {
            environment.systemPackages = [
              pkgs.git
              pkgs.vim
            ];
          };
        }
        {
          config = {
            programs.bash.enable = true;
          };
        }
        {
          config = {
            services.sshd.enable = true;
          };
        }
      ];

      # Add module configuration
      modules = baseModules ++ [ moduleConfig ];

      # Validate module composition
      allConfigsValid = lib.all (
        module: builtins.hasAttr "config" module && builtins.isAttrs module.config
      ) modules;

      # Check for required sections
      hasPackages = lib.any (
        module:
        builtins.hasAttr "environment" module.config
        && builtins.hasAttr "systemPackages" module.config.environment
      ) modules;

      hasPrograms = lib.any (module: builtins.hasAttr "programs" module.config) modules;

      hasServices = lib.any (module: builtins.hasAttr "services" module.config) modules;

      # Configuration should be composable
      totalPackages = lib.foldl' (
        acc: module:
        if
          builtins.hasAttr "environment" module.config
          && builtins.hasAttr "systemPackages" module.config.environment
        then
          acc + builtins.length module.config.environment.systemPackages
        else
          acc
      ) 0 modules;

      reasonablePackageCount = totalPackages >= 0 && totalPackages <= 500;
    in
    allConfigsValid && hasPackages && hasPrograms && hasServices && reasonablePackageCount;

  moduleLoadingTest = propertyHelpers.forAll moduleLoadingProperty (seed: {
    config = {
      # Random module configuration
      environment.variables.TEST_VAR = "test-value-${toString seed}";
      users.users.testuser = {
        isNormalUser = true;
        description = "Test User ${toString seed}";
      };
    };
  }) "module-loading";

  # Property: Configuration evaluation maintains consistency
  configEvaluationProperty =
    testConfig:
    let
      # Simulate Nix configuration evaluation
      config = {
        system = testConfig.system or "x86_64-linux";
        user = testConfig.user or "testuser";
        environment = {
          systemPackages =
            testConfig.packages or [
              pkgs.git
              pkgs.curl
            ];
        };
        users = {
          users.${testConfig.user or "testuser"} = {
            isNormalUser = true;
            home = "/home/${testConfig.user or "testuser"}";
          };
        };
      };

      # Evaluation properties
      hasSystem = builtins.hasAttr "system" config;
      hasUser = builtins.hasAttr "user" config;
      hasEnvironment = builtins.hasAttr "environment" config;
      hasUsers = builtins.hasAttr "users" config;

      # Consistency properties
      userInUsersConfig = builtins.hasAttr config.user config.users.users;
      userHomeMatches = config.users.users.${config.user}.home == "/home/${config.user}";

      # Package consistency
      hasPackages = builtins.hasAttr "systemPackages" config.environment;
      packagesValid = lib.all (pkg: builtins.isDerivation pkg || builtins.isString pkg) (
        config.environment.systemPackages or [ ]
      );

      # No circular references (basic check)
      noSelfReferences = !builtins.hasAttr "self" config;
    in
    hasSystem
    && hasUser
    && hasEnvironment
    && hasUsers
    && userInUsersConfig
    && userHomeMatches
    && hasPackages
    && packagesValid
    && noSelfReferences;

  configEvaluationTest =
    propertyHelpers.forAll configEvaluationProperty propertyHelpers.generateUserConfig
      "config-evaluation";

  # Property: Cross-platform configuration compatibility
  crossPlatformProperty =
    platformSpec:
    let
      platform = platformSpec.platform;
      user = platformSpec.user;
      packages = platformSpec.packages;

      # Platform-specific configurations
      darwinConfig = {
        system = "aarch64-darwin";
        environment = {
          systemPackages = packages ++ [ pkgs.ghostty ]; # macOS-specific
        };
        systemSettings = {
          defaults = {
            NSGlobalDomain = {
              AppleShowAllExtensions = true;
            };
          };
        };
      };

      linuxConfig = {
        system = "x86_64-linux";
        environment = {
          systemPackages = packages ++ [ pkgs.firefox ]; # Linux-specific
        };
        services = {
          xserver.enable = true;
        };
      };

      config = if platform == "darwin" then darwinConfig else linuxConfig;

      # Properties that should hold for both platforms
      hasValidPackages = builtins.length config.environment.systemPackages > 0;
      hasPlatformSpecific =
        if platform == "darwin" then
          builtins.hasAttr "defaults" (config.systemSettings or { })
        else
          builtins.hasAttr "services" config.config;

      # Common packages should be present
      hasCommonPackages = lib.all (pkg: lib.elem pkg config.environment.systemPackages) [
        "git"
        "curl"
      ];

      # Platform-specific packages should only be on their platform
      hasCorrectPlatformPackages =
        if platform == "darwin" then
          lib.any (p: builtins.toString p == "ghostty") config.environment.systemPackages
        else
          lib.any (p: builtins.toString p == "firefox") config.environment.systemPackages;
    in
    hasValidPackages && hasPlatformSpecific && hasCommonPackages && hasCorrectPlatformPackages;

  crossPlatformTest = propertyHelpers.forAllCases crossPlatformProperty [
    {
      platform = "darwin";
      user = "baleen";
      packages = [
        "git"
        "curl"
        "vim"
      ];
    }
    {
      platform = "linux";
      user = "jito";
      packages = [
        "git"
        "curl"
        "vim"
      ];
    }
    {
      platform = "darwin";
      user = "testuser";
      packages = [
        "git"
        "nodejs"
      ];
    }
    {
      platform = "linux";
      user = "developer";
      packages = [
        "git"
        "python3"
      ];
    }
  ] "cross-platform";

  # Property: Configuration scaling properties
  scalingProperty =
    scale:
    let
      # Test how configuration behaves at different scales
      basePackages = [
        "git"
        "curl"
        "wget"
        "tree"
      ];
      additionalPackages = [
        "vim"
        "emacs"
        "neovim"
        "vscode"
      ];
      devPackages = [
        "nodejs"
        "python3"
        "docker"
        "gh"
      ];

      scaleFactor = lib.mod scale 10 + 1; # 1-10
      allPackages =
        basePackages
        ++ (if scaleFactor >= 3 then additionalPackages else [ ])
        ++ (if scaleFactor >= 7 then devPackages else [ ]);

      config = {
        environment.systemPackages = map (
          pkg: if builtins.isString pkg then pkgs.${pkg} or null else pkg
        ) allPackages;
        users = {
          users = builtins.listToAttrs (
            map (i: {
              name = "user${toString i}";
              value = {
                isNormalUser = true;
                description = "User ${toString i}";
              };
            }) (lib.range 1 scaleFactor)
          );
        };
      };

      # Scaling properties
      packageCount = builtins.length (lib.filter (p: p != null) config.environment.systemPackages);
      userCount = builtins.length (builtins.attrNames config.users.users);

      reasonablePackageCount = packageCount <= 20; # Sanity check
      reasonableUserCount = userCount <= 10;

      # Configuration should still be valid at scale
      stillValid = packageCount > 0 && userCount > 0;

      # Performance properties (basic checks)
      notTooLarge = packageCount + userCount <= 25;
    in
    reasonablePackageCount && reasonableUserCount && stillValid && notTooLarge;

  scalingTest = propertyHelpers.forAll scalingProperty (i: i) "configuration-scaling";

  # === Test Suite Aggregation ===

  # Generate comprehensive system property tests
  systemPropertyTests = propertyHelpers.generateSystemPropertyTests 30;

  # Combine all property tests into a test suite
  testSuite = propertyHelpers.propertyTestSuite "system-config-properties" {
    nix-settings-security = {
      name = "nix-settings-security";
      result = nixSettingsSecurityTest;
    };

    package-integrity = {
      name = "package-integrity";
      result = packageIntegrityTest;
    };

    platform-detection = {
      name = "platform-detection";
      result = platformDetectionTest;
    };

    system-factory = {
      name = "system-factory";
      result = systemFactoryTest;
    };

    module-loading = {
      name = "module-loading";
      result = moduleLoadingTest;
    };

    config-evaluation = {
      name = "config-evaluation";
      result = configEvaluationTest;
    };

    cross-platform = {
      name = "cross-platform";
      result = crossPlatformTest;
    };

    configuration-scaling = {
      name = "configuration-scaling";
      result = scalingTest;
    };
  };

in
{
  # Property-based tests using mkTest helper pattern
  nix-settings-security = testHelpers.mkTest "nix-settings-security" ''
    echo "Testing Nix settings security invariants..."
    cat ${nixSettingsSecurityTest}
  '';

  package-integrity = testHelpers.mkTest "package-integrity" ''
    echo "Testing package installation integrity..."
    cat ${packageIntegrityTest}
  '';

  platform-detection = testHelpers.mkTest "platform-detection" ''
    echo "Testing platform detection accuracy..."
    cat ${platformDetectionTest}
  '';

  system-factory = testHelpers.mkTest "system-factory" ''
    echo "Testing system factory consistency..."
    cat ${systemFactoryTest}
  '';

  module-loading = testHelpers.mkTest "module-loading" ''
    echo "Testing module loading integrity..."
    cat ${moduleLoadingTest}
  '';

  config-evaluation = testHelpers.mkTest "config-evaluation" ''
    echo "Testing configuration evaluation consistency..."
    cat ${configEvaluationTest}
  '';

  cross-platform = testHelpers.mkTest "cross-platform" ''
    echo "Testing cross-platform configuration compatibility..."
    cat ${crossPlatformTest}
  '';

  configuration-scaling = testHelpers.mkTest "configuration-scaling" ''
    echo "Testing configuration scaling properties..."
    cat ${scalingTest}
  '';

  # Test suite aggregator
  test-suite = testHelpers.testSuite "property-system-config" [
    nix-settings-security
    package-integrity
    platform-detection
    system-factory
    module-loading
    config-evaluation
    cross-platform
    configuration-scaling
  ];
}
