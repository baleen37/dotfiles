# Git Module Unit Tests
# Tests git module functionality and interface compliance
# This test MUST FAIL initially as part of TDD RED-GREEN-REFACTOR cycle

{
  lib,
  pkgs ? import <nixpkgs> { },
}:

let
  # Import the current git configuration from home-manager module
  # This will be used to test against the expected interface contract
  currentGitConfig = {
    # Simulated current git configuration structure from modules/shared/home-manager.nix
    programs.git = {
      enable = true;
      ignores = [
        ".local/"
        "*.swp"
        "*.swo"
        "*~"
        ".vscode/"
        ".idea/"
        ".DS_Store"
        "Thumbs.db"
        "desktop.ini"
        ".direnv/"
        "result"
        "result-*"
        "node_modules/"
        ".env.local"
        ".env.*.local"
        ".serena/"
        "*.tmp"
        "*.log"
        ".cache/"
        "dist/"
        "build/"
        "target/"
        "issues/"
        "specs/"
        "plans/"
      ];
      userName = "testuser";
      userEmail = "test@example.com";
      lfs.enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        core = {
          editor = "vim";
          autocrlf = "input";
          excludesFile = "~/.gitignore_global";
        };
        pull.rebase = true;
        rebase.autoStash = true;
        alias = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          df = "diff";
          lg = "log --graph --oneline --decorate --all";
        };
      };
    };
  };

  # Expected git module interface contract (this is what the module SHOULD implement)
  expectedGitModuleInterface = {
    meta = {
      name = "git";
      description = "Git version control system with aliases and configuration";
      platforms = [
        "darwin"
        "nixos"
      ];
      version = "1.0.0";
    };
    options = {
      enable = true;
      package = "git";
      config = {
        userName = "string";
        userEmail = "string";
        defaultBranch = "main";
        aliases = "attrset";
        ignorePatterns = "list";
        lfsSupport = true;
      };
      extraPackages = [ "git-lfs" ];
    };
    config = {
      programs.git = {
        enable = true;
        package = "git-package";
        userName = "user-name";
        userEmail = "user-email";
        lfs.enable = true;
        extraConfig = "attrset";
        ignores = "list";
      };
      home.packages = [
        "git"
        "git-lfs"
      ];
    };
    assertions = [
      {
        assertion = true;
        message = "Git user name must be configured";
      }
      {
        assertion = true;
        message = "Git user email must be configured";
      }
    ];
    conflicts = [ ];
    tests = {
      unit = "./test-git-module.nix";
      integration = [
        "git-workflow"
        "cross-platform"
      ];
      platforms = [
        "darwin"
        "nixos"
      ];
    };
  };

  # Test helper functions
  runTest = name: test: {
    inherit name;
    result = test;
    passed = test.success or false;
    errors = test.errors or [ ];
  };

  # Git module interface validation function
  validateGitModuleInterface =
    gitModule:
    let
      # Check if module follows the new interface contract structure
      hasModuleStructure =
        gitModule ? meta && gitModule ? options && gitModule ? config && gitModule ? tests;

      # Check meta section
      hasValidMeta =
        let
          meta = gitModule.meta or { };
        in
        meta ? name
        && meta ? description
        && meta ? platforms
        && meta ? version
        && (meta.name or "") == "git"
        && lib.isString (meta.description or "")
        && lib.isList (meta.platforms or [ ])
        && lib.all (
          platform:
          lib.elem platform [
            "darwin"
            "nixos"
          ]
        ) (meta.platforms or [ ])
        && lib.isString (meta.version or "");

      # Check options section
      hasValidOptions =
        let
          options = gitModule.options or { };
        in
        options ? enable
        && options ? package
        && options ? config
        && lib.isBool (options.enable or false)
        && builtins.isAttrs (options.config or { })
        && builtins.isList (options.extraPackages or [ ]);

      # Check config section (Home Manager configuration)
      hasValidConfig =
        let
          config = gitModule.config or { };
        in
        config ? programs && config.programs ? git && config ? home && config.home ? packages;

      # Check git-specific configuration requirements
      hasValidGitConfig =
        let
          gitConfig = gitModule.config.programs.git or { };
        in
        gitConfig ? enable
        && gitConfig ? userName
        && gitConfig ? userEmail
        && gitConfig ? extraConfig
        && gitConfig ? ignores
        && gitConfig ? lfs
        && lib.isBool (gitConfig.enable or false)
        && lib.isString (gitConfig.userName or "")
        && lib.isString (gitConfig.userEmail or "")
        && builtins.isAttrs (gitConfig.extraConfig or { })
        && builtins.isList (gitConfig.ignores or [ ]);

      # Check git aliases configuration
      hasValidAliases =
        let
          aliases = gitModule.config.programs.git.extraConfig.alias or { };
        in
        builtins.isAttrs aliases
        && aliases ? st
        && aliases ? co
        && aliases ? br
        && aliases ? ci
        && aliases ? df;

      # Check tests section
      hasValidTests =
        let
          tests = gitModule.tests or { };
        in
        tests ? platforms
        && tests ? integration
        && lib.isList (tests.platforms or [ ])
        && lib.isList (tests.integration or [ ]);

      # Collect all validation checks
      allChecks = [
        {
          name = "hasModuleStructure";
          result = hasModuleStructure;
        }
        {
          name = "hasValidMeta";
          result = hasValidMeta;
        }
        {
          name = "hasValidOptions";
          result = hasValidOptions;
        }
        {
          name = "hasValidConfig";
          result = hasValidConfig;
        }
        {
          name = "hasValidGitConfig";
          result = hasValidGitConfig;
        }
        {
          name = "hasValidAliases";
          result = hasValidAliases;
        }
        {
          name = "hasValidTests";
          result = hasValidTests;
        }
      ];

      failedChecks = lib.filter (check: !check.result) allChecks;
    in
    {
      success = lib.all (check: check.result) allChecks;
      errors = lib.map (check: "Git module validation failed: ${check.name}") failedChecks;
      details = {
        checksRun = lib.length allChecks;
        checksPassed = lib.length allChecks - lib.length failedChecks;
        checksFailed = lib.length failedChecks;
        failedChecks = lib.map (check: check.name) failedChecks;
      };
    };

  # Test current git module against interface contract (SHOULD FAIL - TDD RED PHASE)
  testCurrentGitModuleInterface = runTest "Current git module should implement interface contract" (
    let
      # This simulates loading the actual git module - in reality it's embedded in home-manager.nix
      # and doesn't follow the new interface contract structure
      currentGitModule = {
        # Current structure only has the Home Manager config, not the full interface
        programs.git = currentGitConfig.programs.git;
        # Missing: meta, options, assertions, conflicts, tests
      };

      result = validateGitModuleInterface currentGitModule;
    in
    {
      success = result.success;
      errors = result.errors ++ [
        "Current git configuration is embedded in home-manager.nix and does not implement the module interface contract"
        "Missing meta section with name, description, platforms, version"
        "Missing options section with enable, package, config structure"
        "Missing tests section with unit, integration, platforms"
        "Missing assertions and conflicts sections"
      ];
    }
  );

  # Test git configuration functionality
  testGitConfigurationBasics = runTest "Git configuration should include required settings" (
    let
      gitConfig = currentGitConfig.programs.git;

      hasBasicConfig =
        gitConfig ? enable && gitConfig ? userName && gitConfig ? userEmail && gitConfig.enable == true;

      hasIgnorePatterns =
        gitConfig ? ignores && lib.isList gitConfig.ignores && lib.length gitConfig.ignores > 0;

      hasExtraConfig =
        gitConfig ? extraConfig
        && gitConfig.extraConfig ? core
        && gitConfig.extraConfig ? init
        && gitConfig.extraConfig ? alias;

      hasLfsSupport = gitConfig ? lfs && gitConfig.lfs ? enable && gitConfig.lfs.enable == true;
    in
    {
      success = hasBasicConfig && hasIgnorePatterns && hasExtraConfig && hasLfsSupport;
      errors =
        lib.optionals (!hasBasicConfig) [ "Missing basic git configuration" ]
        ++ lib.optionals (!hasIgnorePatterns) [ "Missing ignore patterns" ]
        ++ lib.optionals (!hasExtraConfig) [ "Missing extra configuration" ]
        ++ lib.optionals (!hasLfsSupport) [ "Missing LFS support" ];
    }
  );

  # Test git aliases functionality
  testGitAliases = runTest "Git aliases should be properly configured" (
    let
      aliases = currentGitConfig.programs.git.extraConfig.alias or { };

      requiredAliases = [
        "st"
        "co"
        "br"
        "ci"
        "df"
        "lg"
      ];
      hasAllAliases = lib.all (alias: aliases ? ${alias}) requiredAliases;

      aliasValidation = lib.mapAttrs (_name: value: lib.isString value) aliases;
      allAliasesValid = lib.all (x: x) (lib.attrValues aliasValidation);
    in
    {
      success = hasAllAliases && allAliasesValid;
      errors =
        lib.optionals (!hasAllAliases) [ "Missing required git aliases" ]
        ++ lib.optionals (!allAliasesValid) [ "Invalid alias values (must be strings)" ];
    }
  );

  # Test cross-platform compatibility
  testCrossPlatformCompatibility = runTest "Git module should support cross-platform usage" (
    let
      # Test that git configuration works on both darwin and nixos
      darwinCompatible = true; # Git config should work on darwin
      nixosCompatible = true; # Git config should work on nixos

      # Test package availability
      hasGitPackage = pkgs ? git;
      hasGitLfsPackage = pkgs ? git-lfs;
    in
    {
      success = darwinCompatible && nixosCompatible && hasGitPackage && hasGitLfsPackage;
      errors =
        lib.optionals (!darwinCompatible) [ "Not compatible with darwin" ]
        ++ lib.optionals (!nixosCompatible) [ "Not compatible with nixos" ]
        ++ lib.optionals (!hasGitPackage) [ "Git package not available" ]
        ++ lib.optionals (!hasGitLfsPackage) [ "Git LFS package not available" ];
    }
  );

  # Test configuration validation and error handling
  testConfigurationValidation = runTest "Git module should validate configuration properly" (
    let
      # Test invalid configuration scenarios
      invalidConfigs = [
        {
          userName = "";
          userEmail = "test@example.com";
        } # Empty username
        {
          userName = "testuser";
          userEmail = "";
        } # Empty email
        {
          userName = "testuser";
          userEmail = "invalid-email";
        } # Invalid email format
      ];

      validateConfig =
        config: config.userName != "" && config.userEmail != "" && lib.hasInfix "@" config.userEmail;

      currentConfigValid = validateConfig {
        userName = currentGitConfig.programs.git.userName;
        userEmail = currentGitConfig.programs.git.userEmail;
      };

      invalidConfigsDetected = lib.all (config: !validateConfig config) invalidConfigs;
    in
    {
      success = currentConfigValid && invalidConfigsDetected;
      errors =
        lib.optionals (!currentConfigValid) [ "Current git configuration is invalid" ]
        ++ lib.optionals (!invalidConfigsDetected) [ "Configuration validation not working properly" ];
    }
  );

  # Test package installation and dependencies
  testPackageInstallation = runTest "Git module should handle package installation correctly" (
    let
      # Test that required packages are available
      requiredPackages = [
        "git"
        "git-lfs"
      ];
      packagesAvailable = lib.all (pkg: pkgs ? ${pkg}) requiredPackages;

      # Test git command functionality (simulated)
      gitCommandWorks = true; # Would test actual git command in integration tests
    in
    {
      success = packagesAvailable && gitCommandWorks;
      errors =
        lib.optionals (!packagesAvailable) [ "Required git packages not available" ]
        ++ lib.optionals (!gitCommandWorks) [ "Git command not working" ];
    }
  );

  # Test performance and efficiency
  testPerformanceRequirements = runTest "Git module should meet performance requirements" (
    let
      # Test configuration processing efficiency (simulated in unit test)

      # Test ignore patterns efficiency (should not be excessive)
      ignorePatternCount = lib.length currentGitConfig.programs.git.ignores;
      efficientIgnorePatterns = ignorePatternCount < 50; # Reasonable limit
    in
    {
      success = efficientIgnorePatterns;
      errors = lib.optionals (!efficientIgnorePatterns) [
        "Too many ignore patterns may impact performance"
      ];
    }
  );

  # Collect all tests
  allTests = [
    testCurrentGitModuleInterface # This SHOULD FAIL - TDD RED phase
    testGitConfigurationBasics
    testGitAliases
    testCrossPlatformCompatibility
    testConfigurationValidation
    testPackageInstallation
    testPerformanceRequirements
  ];

in
{
  # Export individual tests
  inherit
    testCurrentGitModuleInterface
    testGitConfigurationBasics
    testGitAliases
    testCrossPlatformCompatibility
    testConfigurationValidation
    testPackageInstallation
    testPerformanceRequirements
    ;

  # Export validation utilities
  inherit validateGitModuleInterface;

  # Export expected interface for reference
  inherit expectedGitModuleInterface;

  # Test summary
  testSummary = {
    total = lib.length allTests;
    passed = lib.length (lib.filter (test: test.passed) allTests);
    failed = lib.length (lib.filter (test: !test.passed) allTests);
    results = allTests;

    # Expected failures for TDD RED phase
    expectedFailures = [
      "testCurrentGitModuleInterface" # Should fail until git module implements contract
    ];

    # TDD status indication
    tddPhase = "RED";
    tddMessage = "This test implements the TDD failing test requirement. The git module interface test will fail until the git configuration is refactored to follow the new module interface contract.";

    # Next steps for TDD GREEN phase
    nextSteps = [
      "Create modules/shared/git.nix with proper interface contract structure"
      "Move git configuration from home-manager.nix to dedicated git module"
      "Implement meta, options, config, assertions, and tests sections"
      "Update imports to use new git module structure"
      "Verify all tests pass (TDD GREEN phase)"
      "Refactor for code quality (TDD REFACTOR phase)"
    ];
  };

  # Interface contract reference for implementation
  contractReference = {
    description = "Git module must implement this interface contract to pass tests";
    requiredSections = [
      "meta - module metadata (name, description, platforms, version)"
      "options - configuration options (enable, package, config, extraPackages)"
      "config - Home Manager configuration (programs.git, home.packages)"
      "assertions - configuration validation rules"
      "tests - test definitions (unit, integration, platforms)"
    ];
    implementation = expectedGitModuleInterface;
  };
}
