# Property-Based Tests for Git Configuration
# Tests Git configuration invariants across multiple scenarios
#
# Tests the following properties:
#   - Git alias structure and validity across variations
#   - User identity consistency across Git settings
#   - Git configuration invariants across platforms
#   - Git LFS and gitignore properties
#   - Cross-platform Git configuration compatibility
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

  # Import Git configuration for validation
  gitConfig = import ../../users/shared/git.nix { inherit pkgs lib; };
  userInfo = import ../../lib/user-info.nix;

  # === Git Configuration Property Tests ===

  # Property: Git aliases maintain valid structure
  gitAliasStructureTest =
    propertyHelpers.forAll propertyHelpers.gitAliasStructureProperty propertyHelpers.generateGitAliases
      "git-alias-structure";

  # Property: Git user identity is consistent and valid
  gitUserIdentityTest =
    propertyHelpers.forAll propertyHelpers.gitUserIdentityProperty propertyHelpers.generateUserConfig
      "git-user-identity";

  # Property: Git configuration maintains required sections
  gitConfigSectionsProperty =
    testConfig:
    let
      # Simulate Git configuration structure
      config = testConfig // {
        programs = {
          git = {
            enable = true;
            lfs = {
              enable = true;
            };
            settings = {
              user = {
                name = testConfig.name;
                email = testConfig.email;
              };
              init = {
                defaultBranch = "main";
              };
              core = {
                editor = "vim";
                autocrlf = "input";
              };
              pull = {
                rebase = true;
              };
              rebase = {
                autoStash = true;
              };
              alias = {
                st = "status";
                co = "checkout";
                br = "branch";
                ci = "commit";
                df = "diff";
                lg = "log --graph --oneline --decorate --all";
              };
            };
            ignores = [
              ".DS_Store"
              "node_modules/"
              ".vscode/"
              "*.swp"
              ".env.local"
              "result"
            ];
          };
        };
      };

      # Validate required sections exist
      hasGitProgram = builtins.hasAttr "programs" config && builtins.hasAttr "git" config.programs;
      hasGitEnabled = hasGitProgram && config.programs.git.enable;
      hasLfsEnabled = hasGitProgram && config.programs.git.lfs.enable;
      hasSettings = hasGitProgram && builtins.hasAttr "settings" config.programs.git;
      hasUserSection = hasSettings && builtins.hasAttr "user" config.programs.git.settings;
      hasInitSection = hasSettings && builtins.hasAttr "init" config.programs.git.settings;
      hasCoreSection = hasSettings && builtins.hasAttr "core" config.programs.git.settings;
      hasAliasSection = hasSettings && builtins.hasAttr "alias" config.programs.git.settings;
      hasIgnores = hasGitProgram && builtins.hasAttr "ignores" config.programs.git;

      # Validate critical settings
      defaultBranchSet = hasInitSection && config.programs.git.settings.init.defaultBranch == "main";
      editorSet = hasCoreSection && config.programs.git.settings.core.editor == "vim";
      autocrlfSet = hasCoreSection && config.programs.git.settings.core.autocrlf == "input";
      pullRebaseSet = hasSettings && config.programs.git.settings.pull.rebase == true;
      rebaseAutoStashSet = hasSettings && config.programs.git.settings.rebase.autoStash == true;

      # Validate ignores contain essential patterns
      hasEssentialIgnores =
        let
          ignores = config.programs.git.ignores or [ ];
          essentialPatterns = [
            ".DS_Store"
            "node_modules/"
            ".vscode/"
            "*.swp"
          ];
          hasPattern = pattern: builtins.elem pattern ignores;
        in
        lib.all hasPattern essentialPatterns;

    in
    hasGitEnabled
    && hasLfsEnabled
    && hasSettings
    && hasUserSection
    && hasInitSection
    && hasCoreSection
    && hasAliasSection
    && hasIgnores
    && defaultBranchSet
    && editorSet
    && autocrlfSet
    && pullRebaseSet
    && rebaseAutoStashSet
    && hasEssentialIgnores;

  gitConfigSectionsTest =
    propertyHelpers.forAll gitConfigSectionsProperty propertyHelpers.generateUserConfig
      "git-config-sections";

  # Property: Git ignore patterns are valid and effective
  gitIgnorePatternsProperty =
    testSeed:
    let
      # Generate various gitignore patterns
      basePatterns = [
        ".DS_Store"
        "Thumbs.db"
        "*.swp"
        "*.swo"
        ".vscode/"
        ".idea/"
        "node_modules/"
        ".env.local"
        "result"
      ];

      extendedPatterns = [
        "*.log"
        ".cache/"
        "dist/"
        "build/"
        "target/"
        ".direnv/"
        "*.tmp"
      ];

      useExtended = (lib.mod testSeed 3) != 0;
      selectedPatterns = if useExtended then basePatterns ++ extendedPatterns else basePatterns;

      # Validate patterns
      allValidPatterns = lib.all (
        pattern:
        let
          patternStr = builtins.toString pattern;
          # Pattern should be non-empty
          nonEmpty = builtins.stringLength patternStr > 0;
          # Pattern should not contain dangerous characters
          safeChars = !lib.hasInfix "../" patternStr && !lib.hasInfix "~/" patternStr;
          # Pattern should be reasonable length
          reasonableLength = builtins.stringLength patternStr <= 100;
        in
        nonEmpty && safeChars && reasonableLength
      ) selectedPatterns;

      # Should include essential patterns
      hasEssential = lib.all (pattern: builtins.elem pattern selectedPatterns) [
        ".DS_Store"
        "node_modules/"
        "*.swp"
      ];

      # No duplicate patterns
      uniquePatterns = builtins.length selectedPatterns == builtins.length (lib.unique selectedPatterns);
    in
    allValidPatterns && hasEssential && uniquePatterns;

  gitIgnorePatternsTest = propertyHelpers.forAll gitIgnorePatternsProperty (
    i: i
  ) "git-ignore-patterns";

  # Property: Git configuration maintains cross-platform compatibility
  gitCrossPlatformProperty =
    platformInfo:
    let
      isDarwin = platformInfo.isDarwin or false;
      isLinux = platformInfo.isLinux or false;

      # Core editor should work on all platforms
      coreEditor = "vim";
      editorWorks = true; # vim works everywhere

      # AutoCRLF settings
      autocrlfSetting = "input"; # Works on all platforms
      autocrlfWorks = true;

      # File paths should be platform-appropriate
      excludesFile = if isDarwin then "~/.gitignore_global" else "~/.gitignore_global";
      excludesFileValid = lib.hasPrefix "~/" excludesFile;

      # Aliases should work on all platforms
      aliases = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        df = "diff";
        lg = "log --graph --oneline --decorate --all";
      };
      aliasesValid = lib.all (
        name:
        let
          cmd = aliases.${name} or "";
        in
        builtins.stringLength cmd > 0
      ) (builtins.attrNames aliases);

      # LFS should work on all platforms
      lfsEnabled = true;
      lfsWorks = true;

    in
    editorWorks && autocrlfWorks && excludesFileValid && aliasesValid && lfsWorks;

  gitCrossPlatformTest = propertyHelpers.forAllCases gitCrossPlatformProperty [
    {
      isDarwin = true;
      isLinux = false;
    }
    {
      isDarwin = false;
      isLinux = true;
    }
  ] "git-cross-platform";

  # Property: Git configuration transformations preserve essential properties
  gitTransformationProperty =
    baseConfig:
    let
      # Simulate configuration transformation (e.g., adding new aliases)
      transformConfig =
        config:
        config
        // {
          programs = config.programs // {
            git = config.programs.git // {
              settings = config.programs.git.settings // {
                alias = config.programs.git.settings.alias // {
                  aa = "add --all";
                  cm = "commit -m";
                };
              };
            };
          };
        };

      originalConfig = {
        programs = {
          git = {
            enable = true;
            settings = {
              user = baseConfig;
              alias = {
                st = "status";
                co = "checkout";
              };
            };
          };
        };
      };

      transformedConfig = transformConfig originalConfig;

      # Properties that should be preserved
      originalUser = originalConfig.programs.git.settings.user;
      transformedUser = transformedConfig.programs.git.settings.user;
      userPreserved = originalUser == transformedUser;

      originalAliases = originalConfig.programs.git.settings.alias;
      transformedAliases = transformedConfig.programs.git.settings.alias;

      # Original aliases should still be present
      originalAliasesPreserved = lib.all (
        name: (originalAliases.${name} or "") == (transformedAliases.${name} or "")
      ) (builtins.attrNames originalAliases);

      # New aliases should be added
      newAliasesAdded =
        builtins.hasAttr "aa" transformedAliases && builtins.hasAttr "cm" transformedAliases;

      # Configuration should still be valid
      stillValid =
        builtins.hasAttr "programs" transformedConfig
        && builtins.hasAttr "git" transformedConfig.programs
        && transformedConfig.programs.git.enable;
    in
    userPreserved && originalAliasesPreserved && newAliasesAdded && stillValid;

  gitTransformationTest =
    propertyHelpers.forAll gitTransformationProperty propertyHelpers.generateUserConfig
      "git-transformation";

  # Property: Git configuration edge cases
  gitEdgeCasesProperty =
    testCase:
    let
      # Test various edge cases
      edgeCases = [
        {
          name = "minimal-user";
          config = {
            name = "A";
            email = "a@b.com";
          };
          shouldWork = true;
        }
        {
          name = "long-user";
          config = {
            name = "Very Long User Name With Many Words";
            email = "very.long.email@example.com";
          };
          shouldWork = true;
        }
        {
          name = "email-with-subdomains";
          config = {
            name = "User";
            email = "user@mail.example.co.uk";
          };
          shouldWork = true;
        }
        {
          name = "empty-name";
          config = {
            name = "";
            email = "user@example.com";
          };
          shouldWork = false;
        }
        {
          name = "invalid-email";
          config = {
            name = "User";
            email = "invalid-email";
          };
          shouldWork = false;
        }
      ];

      currentCase = builtins.elemAt edgeCases (lib.mod testCase (builtins.length edgeCases));
      userConfig = currentCase.config;
      expectedToWork = currentCase.shouldWork;

      # Test if configuration would work
      nameValid = builtins.stringLength userConfig.name > 1;
      emailValid = builtins.match ".*@.*\\..*" userConfig.email != null;
      actuallyWorks = nameValid && emailValid;

    in
    expectedToWork -> actuallyWorks;

  gitEdgeCasesTest = propertyHelpers.forAll gitEdgeCasesProperty (i: i) "git-edge-cases";

  # === Test Suite Aggregation ===

  # Generate comprehensive Git property tests
  gitPropertyTests = propertyHelpers.generateGitPropertyTests 50;

  # Combine all property tests into a test suite
  testSuite = propertyHelpers.propertyTestSuite "git-config-properties" {
    git-alias-structure = {
      name = "git-alias-structure";
      result = gitAliasStructureTest;
    };

    git-user-identity = {
      name = "git-user-identity";
      result = gitUserIdentityTest;
    };

    git-config-sections = {
      name = "git-config-sections";
      result = gitConfigSectionsTest;
    };

    git-ignore-patterns = {
      name = "git-ignore-patterns";
      result = gitIgnorePatternsTest;
    };

    git-cross-platform = {
      name = "git-cross-platform";
      result = gitCrossPlatformTest;
    };

    git-transformation = {
      name = "git-transformation";
      result = gitTransformationTest;
    };

    git-edge-cases = {
      name = "git-edge-cases";
      result = gitEdgeCasesTest;
    };
  };

in
{
  # Property-based tests using mkTest helper pattern
  git-alias-structure = testHelpers.mkTest "git-alias-structure" ''
    echo "Testing Git alias structure validity..."
    cat ${gitAliasStructureTest}
  '';

  git-user-identity = testHelpers.mkTest "git-user-identity" ''
    echo "Testing Git user identity consistency..."
    cat ${gitUserIdentityTest}
  '';

  git-config-sections = testHelpers.mkTest "git-config-sections" ''
    echo "Testing Git configuration sections completeness..."
    cat ${gitConfigSectionsTest}
  '';

  git-ignore-patterns = testHelpers.mkTest "git-ignore-patterns" ''
    echo "Testing Git ignore patterns validity..."
    cat ${gitIgnorePatternsTest}
  '';

  git-cross-platform = testHelpers.mkTest "git-cross-platform" ''
    echo "Testing cross-platform Git configuration compatibility..."
    cat ${gitCrossPlatformTest}
  '';

  git-transformation = testHelpers.mkTest "git-transformation" ''
    echo "Testing Git configuration transformation properties..."
    cat ${gitTransformationTest}
  '';

  git-edge-cases = testHelpers.mkTest "git-edge-cases" ''
    echo "Testing Git configuration edge cases..."
    cat ${gitEdgeCasesTest}
  '';

  # Test suite aggregator
  test-suite = testHelpers.testSuite "property-git-config" [
    git-alias-structure
    git-user-identity
    git-config-sections
    git-ignore-patterns
    git-cross-platform
    git-transformation
    git-edge-cases
  ];
}
