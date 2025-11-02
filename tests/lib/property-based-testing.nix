# Property-Based Testing Framework for Nix Configurations
#
# Provides a framework for testing configuration properties across
# multiple scenarios and inputs, inspired by Haskell's QuickCheck.
#
# Usage:
#   testConfigProperty "git-config-roundtrip" gitRoundtripProperty gitConfigScenarios
#

{ lib }:

let
  inherit (lib)
    all
    any
    genList
    foldl'
    imap0
    mapAttrsToList
    ;

  # Property testing core framework
  inherit (import ./test-helpers.nix { inherit lib; }) assertTest;

  # Generate test scenarios with variations
  generateScenarios =
    baseConfig: variations:
    let
      applyVariation =
        variation: if builtins.isFunction variation then variation baseConfig else baseConfig // variation;
    in
    map applyVariation variations;

  # Property: Configuration round-trip (parse -> modify -> parse -> equals)
  roundtripProperty =
    {
      parser,
      modifier,
      validator,
    }:
    {
      config,
      name ? "roundtrip",
    }:
    let
      original = parser config;
      modified = modifier original;
      reparsed = parser modified;
      isValid = validator original reparsed;
    in
    assertTest "${name}-${config.identifier or "unknown"}" isValid;

  # Property: Configuration invariants (always true regardless of input)
  invariantProperty =
    {
      invariant,
      name ? "invariant",
    }:
    { config, ... }:
    let
      result = invariant config;
    in
    assertTest "${name}-${config.identifier or "unknown"}" result;

  # Property: Configuration idempotence (applying twice = same as once)
  idempotenceProperty =
    {
      transformer,
      name ? "idempotence",
    }:
    { config, ... }:
    let
      once = transformer config;
      twice = transformer once;
    in
    assertTest "${name}-${config.identifier or "unknown"}" (once == twice);

  # Property: Configuration composition (f ∘ g = h)
  compositionProperty =
    {
      f,
      g,
      expected,
      name ? "composition",
    }:
    { config, ... }:
    let
      composed = f (g config);
      direct = expected config;
    in
    assertTest "${name}-${config.identifier or "unknown"}" (composed == direct);

  # Property: Configuration monotonicity (adding options doesn't remove existing ones)
  monotonicityProperty =
    {
      enricher,
      checker,
      name ? "monotonicity",
    }:
    { config, ... }:
    let
      enriched = enricher config;
      isMonotonic = checker enriched config;
    in
    assertTest "${name}-${config.identifier or "unknown"}" isMonotonic;

  # Scenario generators for common configuration patterns
  scenarios = {
    # Generate user scenarios with different attributes
    users = [
      {
        identifier = "minimal-user";
        name = "test";
        email = "test@example.com";
      }
      {
        identifier = "full-user";
        name = "Full Name";
        email = "full@example.com";
        signingKey = "ABC123";
      }
      {
        identifier = "enterprise-user";
        name = "Corp User";
        email = "corp@company.com";
        signingKey = "XYZ789";
      }
    ];

    # Generate Git configuration scenarios
    gitConfigs = [
      {
        identifier = "basic-git";
        programs.git.enable = true;
      }
      {
        identifier = "git-with-aliases";
        programs.git.enable = true;
        programs.git.settings.aliases = {
          st = "status";
          co = "checkout";
        };
      }
      {
        identifier = "git-with-lfs";
        programs.git.enable = true;
        programs.git.lfs.enable = true;
      }
      {
        identifier = "git-with-pull-rebase";
        programs.git.enable = true;
        programs.git.settings.pull.rebase = true;
      }
    ];

    # Generate Vim configuration scenarios
    vimConfigs = [
      {
        identifier = "basic-vim";
        programs.vim.enable = true;
      }
      {
        identifier = "vim-with-plugins";
        programs.vim.enable = true;
        programs.vim.plugins = [ "vim-airline" ];
      }
      {
        identifier = "vim-with-custom-config";
        programs.vim.enable = true;
        programs.vim.extraConfig = "set number";
      }
    ];

    # Generate system configuration scenarios
    systemConfigs = [
      {
        identifier = "minimal-system";
        home.stateVersion = "23.11";
      }
      {
        identifier = "development-system";
        home.stateVersion = "23.11";
        programs.git.enable = true;
        programs.vim.enable = true;
      }
      {
        identifier = "full-system";
        home.stateVersion = "23.11";
        programs.git.enable = true;
        programs.vim.enable = true;
        programs.zsh.enable = true;
      }
    ];

    # Generate edge case scenarios
    edgeCases = [
      { identifier = "empty-config"; }
      {
        identifier = "null-values";
        programs.git.enable = null;
      }
      {
        identifier = "nested-structures";
        programs = {
          git = {
            enable = true;
            settings = {
              user = {
                name = "test";
                email = "test@example.com";
              };
            };
          };
        };
      }
    ];
  };

  # Built-in property tests for common patterns
  properties = {
    # Git configuration properties
    gitRoundtrip = roundtripProperty {
      name = "git-roundtrip";
      parser =
        config: if config.programs.git.enable or false then config.programs.git.settings or { } else { };
      modifier = settings: settings // { user = settings.user or { }; };
      validator =
        original: reparsed:
        # Should preserve user information if it existed
        (original.user or { } == reparsed.user or { });
    };

    gitInvariant = invariantProperty {
      name = "git-invariant";
      invariant =
        config:
        # Git should be either enabled or disabled, never undefined
        builtins.hasAttr "enable" (config.programs.git or { });
    };

    gitIdempotence = idempotenceProperty {
      name = "git-idempotence";
      transformer =
        config:
        if config.programs.git.enable or false then
          config // { programs.git.settings = config.programs.git.settings or { }; }
        else
          config;
    };

    # Vim configuration properties
    vimMonotonicity = monotonicityProperty {
      name = "vim-monotonicity";
      enricher =
        config:
        config
        // {
          programs.vim = (config.programs.vim or { }) // {
            plugins = (config.programs.vim.plugins or [ ]) ++ [ "new-plugin" ];
          };
        };
      checker =
        enriched: original:
        (enriched.programs.vim.plugins or [ ])
        == ((original.programs.vim.plugins or [ ]) ++ [ "new-plugin" ]);
    };

    # System configuration properties
    systemComposition = compositionProperty {
      name = "system-composition";
      f =
        config:
        config
        // {
          programs = (config.programs or { }) // {
            git.enable = true;
          };
        };
      g =
        config:
        config
        // {
          programs = (config.programs or { }) // {
            vim.enable = true;
          };
        };
      expected =
        config:
        config
        // {
          programs = (config.programs or { }) // {
            git.enable = true;
            vim.enable = true;
          };
        };
    };
  };

  # Main property testing runner
  runPropertyTest =
    property: scenarioList:
    let
      testResults = map (scenario: property { inherit scenario; }) scenarioList;
      allPassed = all (result: result) testResults;
    in
    allPassed;

  # Batch property testing with multiple properties
  runPropertySuite =
    propertySuite: scenarios:
    let
      testResults = mapAttrsToList (propName: property: runPropertyTest property scenarios) propertySuite;
      resultsStr = lib.concatMapStringsSep "\n" (
        result: if result then "✅ PASS" else "❌ FAIL"
      ) testResults;
    in
    {
      allPassed = all (result: result) testResults;
      results = resultsStr;
      count = builtins.length testResults;
      passed = builtins.length (lib.filter (x: x) testResults);
    };

in
{
  inherit
    # Core property types
    roundtripProperty
    invariantProperty
    idempotenceProperty
    compositionProperty
    monotonicityProperty
    ;

  inherit
    # Scenario generators
    scenarios
    generateScenarios
    ;

  inherit
    # Built-in properties
    properties
    ;

  inherit
    # Test runners
    runPropertyTest
    runPropertySuite
    ;

  # Helper functions for creating custom properties
  mkProperty =
    { type, ... }@args:
    if type == "roundtrip" then
      roundtripProperty args
    else if type == "invariant" then
      invariantProperty args
    else if type == "idempotence" then
      idempotenceProperty args
    else if type == "composition" then
      compositionProperty args
    else if type == "monotonicity" then
      monotonicityProperty args
    else
      throw "Unknown property type: ${type}";

  # Create custom scenario generators
  mkScenarios = baseConfig: variations: generateScenarios baseConfig variations;
}
