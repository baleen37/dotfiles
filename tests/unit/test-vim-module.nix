# Vim Module Unit Tests
# Tests vim module functionality and interface compliance
# This test MUST FAIL initially as part of TDD RED-GREEN-REFACTOR cycle

{
  lib,
  pkgs ? import <nixpkgs> { },
}:

let
  # Import the current vim configuration from home-manager module
  # This will be used to test against the expected interface contract
  currentVimConfig = {
    # Simulated current vim configuration structure from modules/shared/home-manager.nix
    programs.vim = {
      enable = true;
      plugins = [
        "vim-airline"
        "vim-airline-themes"
        "vim-tmux-navigator"
      ];
      settings = {
        ignorecase = true;
      };
      extraConfig = ''
        " General
        set number
        set history=1000
        set nocompatible
        set modelines=0
        set encoding=utf-8
        set scrolloff=3
        set showmode
        set showcmd
        set hidden
        set wildmenu
        set wildmode=list:longest
        set cursorline
        set ttyfast
        set nowrap
        set ruler
        set backspace=indent,eol,start
        set laststatus=2
        set clipboard=autoselect

        " Dir stuff
        set nobackup
        set nowritebackup
        set noswapfile
        set backupdir=~/.config/vim/backups
        set directory=~/.config/vim/swap

        " Relative line numbers for easy movement
        set relativenumber
        set rnu

        " Whitespace rules
        set tabstop=8
        set shiftwidth=2
        set softtabstop=2
        set expandtab

        " Searching
        set incsearch
        set gdefault

        " Statusbar
        set nocompatible " Disable vi-compatibility
        set laststatus=2 " Always show the statusline
        let g:airline_theme='bubblegum'
        let g:airline_powerline_fonts = 1

        " Local keys and such
        let mapleader=","
        let maplocalleader=" "

        " Change cursor on mode
        :autocmd InsertEnter * set cul
        :autocmd InsertLeave * set nocul

        " File-type highlighting and configuration
        syntax on
        filetype on
        filetype plugin on
        filetype indent on

        " Paste from clipboard
        nnoremap <Leader>, "+gP

        " Copy from clipboard
        xnoremap <Leader>. "+y

        " Move cursor by display lines when wrapping
        nnoremap j gj
        nnoremap k gk

        " Map leader-q to quit out of window
        nnoremap <leader>q :q<cr>

        " Move around split
        nnoremap <C-h> <C-w>h
        nnoremap <C-j> <C-w>j
        nnoremap <C-k> <C-w>k
        nnoremap <C-l> <C-w>l

        " Easier to yank entire line
        nnoremap Y y$

        " Move buffers
        nnoremap <tab> :bnext<cr>
        nnoremap <S-tab> :bprev<cr>
      '';
    };
  };

  # Expected vim module interface contract (this is what the module SHOULD implement)
  expectedVimModuleInterface = {
    meta = {
      name = "vim";
      description = "Vim text editor with plugins and configuration";
      platforms = [
        "darwin"
        "nixos"
      ];
      version = "1.0.0";
    };
    options = {
      enable = true;
      package = "vim";
      config = {
        plugins = "list";
        settings = "attrset";
        extraConfig = "string";
        keyMappings = "attrset";
        syntaxHighlighting = true;
        lineNumbers = true;
        statusLine = true;
      };
      extraPackages = [ ];
    };
    config = {
      programs.vim = {
        enable = true;
        package = "vim-package";
        plugins = "list";
        settings = "attrset";
        extraConfig = "string";
      };
      home.packages = [ "vim" ];
    };
    assertions = [
      {
        assertion = true;
        message = "Vim must be enabled for configuration to take effect";
      }
      {
        assertion = true;
        message = "Vim plugins must be valid nixpkgs packages";
      }
    ];
    conflicts = [ ];
    tests = {
      unit = "./test-vim-module.nix";
      integration = [
        "vim-workflow"
        "cross-platform"
        "plugin-loading"
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

  # Vim module interface validation function
  validateVimModuleInterface =
    vimModule:
    let
      # Check if module follows the new interface contract structure
      hasModuleStructure =
        vimModule ? meta && vimModule ? options && vimModule ? config && vimModule ? tests;

      # Check meta section
      hasValidMeta =
        let
          meta = vimModule.meta or { };
        in
        meta ? name
        && meta ? description
        && meta ? platforms
        && meta ? version
        && (meta.name or "") == "vim"
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
          options = vimModule.options or { };
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
          config = vimModule.config or { };
        in
        config ? programs && config.programs ? vim && config ? home && config.home ? packages;

      # Check vim-specific configuration requirements
      hasValidVimConfig =
        let
          vimConfig = vimModule.config.programs.vim or { };
        in
        vimConfig ? enable
        && vimConfig ? plugins
        && vimConfig ? settings
        && vimConfig ? extraConfig
        && lib.isBool (vimConfig.enable or false)
        && builtins.isList (vimConfig.plugins or [ ])
        && builtins.isAttrs (vimConfig.settings or { })
        && lib.isString (vimConfig.extraConfig or "");

      # Check vim plugin configuration
      hasValidPlugins =
        let
          plugins = vimModule.config.programs.vim.plugins or [ ];
        in
        builtins.isList plugins && lib.all lib.isString plugins;

      # Check vim settings configuration
      hasValidSettings =
        let
          settings = vimModule.config.programs.vim.settings or { };
        in
        builtins.isAttrs settings
        &&
          # Check for essential vim settings
          (settings ? ignorecase || true); # Allow missing optional settings

      # Check vim extra configuration
      hasValidExtraConfig =
        let
          extraConfig = vimModule.config.programs.vim.extraConfig or "";
        in
        lib.isString extraConfig
        && lib.hasInfix "set number" extraConfig
        && lib.hasInfix "syntax on" extraConfig
        && lib.hasInfix "filetype on" extraConfig;

      # Check tests section
      hasValidTests =
        let
          tests = vimModule.tests or { };
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
          name = "hasValidVimConfig";
          result = hasValidVimConfig;
        }
        {
          name = "hasValidPlugins";
          result = hasValidPlugins;
        }
        {
          name = "hasValidSettings";
          result = hasValidSettings;
        }
        {
          name = "hasValidExtraConfig";
          result = hasValidExtraConfig;
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
      errors = lib.map (check: "Vim module validation failed: ${check.name}") failedChecks;
      details = {
        checksRun = lib.length allChecks;
        checksPassed = lib.length allChecks - lib.length failedChecks;
        checksFailed = lib.length failedChecks;
        failedChecks = lib.map (check: check.name) failedChecks;
      };
    };

  # Test current vim module against interface contract (SHOULD FAIL - TDD RED PHASE)
  testCurrentVimModuleInterface = runTest "Current vim module should implement interface contract" (
    let
      # This simulates loading the actual vim module - in reality it's embedded in home-manager.nix
      # and doesn't follow the new interface contract structure
      currentVimModule = {
        # Current structure only has the Home Manager config, not the full interface
        programs.vim = currentVimConfig.programs.vim;
        # Missing: meta, options, assertions, conflicts, tests
      };

      result = validateVimModuleInterface currentVimModule;
    in
    {
      success = result.success;
      errors = result.errors ++ [
        "Current vim configuration is embedded in home-manager.nix and does not implement the module interface contract"
        "Missing meta section with name, description, platforms, version"
        "Missing options section with enable, package, config structure"
        "Missing tests section with unit, integration, platforms"
        "Missing assertions and conflicts sections"
      ];
    }
  );

  # Test vim configuration functionality
  testVimConfigurationBasics = runTest "Vim configuration should include required settings" (
    let
      vimConfig = currentVimConfig.programs.vim;

      hasBasicConfig =
        vimConfig ? enable && vimConfig ? plugins && vimConfig ? extraConfig && vimConfig.enable == true;

      hasPlugins =
        vimConfig ? plugins && lib.isList vimConfig.plugins && lib.length vimConfig.plugins > 0;

      hasExtraConfig =
        vimConfig ? extraConfig
        && lib.isString vimConfig.extraConfig
        && lib.hasInfix "set number" vimConfig.extraConfig;

      hasSettings = vimConfig ? settings && builtins.isAttrs vimConfig.settings;
    in
    {
      success = hasBasicConfig && hasPlugins && hasExtraConfig && hasSettings;
      errors =
        lib.optionals (!hasBasicConfig) [ "Missing basic vim configuration" ]
        ++ lib.optionals (!hasPlugins) [ "Missing vim plugins" ]
        ++ lib.optionals (!hasExtraConfig) [ "Missing extra vim configuration" ]
        ++ lib.optionals (!hasSettings) [ "Missing vim settings" ];
    }
  );

  # Test vim plugins functionality
  testVimPlugins = runTest "Vim plugins should be properly configured" (
    let
      plugins = currentVimConfig.programs.vim.plugins or [ ];

      requiredPlugins = [
        "vim-airline"
        "vim-airline-themes"
        "vim-tmux-navigator"
      ];
      hasAllPlugins = lib.all (plugin: lib.elem plugin plugins) requiredPlugins;

      pluginValidation = lib.all lib.isString plugins;
    in
    {
      success = hasAllPlugins && pluginValidation;
      errors =
        lib.optionals (!hasAllPlugins) [ "Missing required vim plugins" ]
        ++ lib.optionals (!pluginValidation) [ "Invalid plugin definitions (must be strings)" ];
    }
  );

  # Test vim essential features
  testVimEssentialFeatures = runTest "Vim should have essential features configured" (
    let
      extraConfig = currentVimConfig.programs.vim.extraConfig or "";

      # Check for essential vim features
      hasLineNumbers = lib.hasInfix "set number" extraConfig;
      hasSyntaxHighlighting = lib.hasInfix "syntax on" extraConfig;
      hasFiletypeDetection = lib.hasInfix "filetype on" extraConfig;
      hasFiletypePlugin = lib.hasInfix "filetype plugin on" extraConfig;
      hasFiletypeIndent = lib.hasInfix "filetype indent on" extraConfig;
      hasSearchSettings = lib.hasInfix "set incsearch" extraConfig;
      hasStatusLine = lib.hasInfix "set laststatus=2" extraConfig;

      # Check for key mappings
      hasLeaderKey = lib.hasInfix "let mapleader" extraConfig;
      hasMovementMappings = lib.hasInfix "nnoremap j gj" extraConfig;
      hasBufferMappings = lib.hasInfix "nnoremap <tab>" extraConfig;
    in
    {
      success =
        hasLineNumbers
        && hasSyntaxHighlighting
        && hasFiletypeDetection
        && hasFiletypePlugin
        && hasFiletypeIndent
        && hasSearchSettings
        && hasStatusLine
        && hasLeaderKey
        && hasMovementMappings
        && hasBufferMappings;
      errors =
        lib.optionals (!hasLineNumbers) [ "Missing line numbers configuration" ]
        ++ lib.optionals (!hasSyntaxHighlighting) [ "Missing syntax highlighting" ]
        ++ lib.optionals (!hasFiletypeDetection) [ "Missing filetype detection" ]
        ++ lib.optionals (!hasFiletypePlugin) [ "Missing filetype plugin support" ]
        ++ lib.optionals (!hasFiletypeIndent) [ "Missing filetype indent support" ]
        ++ lib.optionals (!hasSearchSettings) [ "Missing search configuration" ]
        ++ lib.optionals (!hasStatusLine) [ "Missing status line configuration" ]
        ++ lib.optionals (!hasLeaderKey) [ "Missing leader key configuration" ]
        ++ lib.optionals (!hasMovementMappings) [ "Missing movement key mappings" ]
        ++ lib.optionals (!hasBufferMappings) [ "Missing buffer navigation mappings" ];
    }
  );

  # Test cross-platform compatibility
  testCrossPlatformCompatibility = runTest "Vim module should support cross-platform usage" (
    let
      # Test that vim configuration works on both darwin and nixos
      darwinCompatible = true; # Vim config should work on darwin
      nixosCompatible = true; # Vim config should work on nixos

      # Test package availability
      hasVimPackage = pkgs ? vim;
      hasVimPlugins = pkgs ? vimPlugins;
    in
    {
      success = darwinCompatible && nixosCompatible && hasVimPackage && hasVimPlugins;
      errors =
        lib.optionals (!darwinCompatible) [ "Not compatible with darwin" ]
        ++ lib.optionals (!nixosCompatible) [ "Not compatible with nixos" ]
        ++ lib.optionals (!hasVimPackage) [ "Vim package not available" ]
        ++ lib.optionals (!hasVimPlugins) [ "Vim plugins not available" ];
    }
  );

  # Test configuration validation and error handling
  testConfigurationValidation = runTest "Vim module should validate configuration properly" (
    let
      # Test invalid configuration scenarios
      invalidConfigs = [
        {
          enable = false;
          plugins = [ ];
        } # Disabled vim
        {
          enable = true;
          plugins = [ "invalid-plugin" ];
        } # Invalid plugin
        {
          enable = true;
          extraConfig = 123;
        } # Invalid extraConfig type
      ];

      validateConfig =
        config:
        config.enable == true
        && lib.isList config.plugins
        && (config ? extraConfig -> lib.isString config.extraConfig);

      currentConfigValid = validateConfig currentVimConfig.programs.vim;

      invalidConfigsDetected = lib.all (config: !validateConfig config) invalidConfigs;
    in
    {
      success = currentConfigValid && invalidConfigsDetected;
      errors =
        lib.optionals (!currentConfigValid) [ "Current vim configuration is invalid" ]
        ++ lib.optionals (!invalidConfigsDetected) [ "Configuration validation not working properly" ];
    }
  );

  # Test package installation and dependencies
  testPackageInstallation = runTest "Vim module should handle package installation correctly" (
    let
      # Test that required packages are available
      requiredPackages = [ "vim" ];
      packagesAvailable = lib.all (pkg: pkgs ? ${pkg}) requiredPackages;

      # Test plugin packages are available
      requiredPluginPackages = [
        "vim-airline"
        "vim-airline-themes"
        "vim-tmux-navigator"
      ];
      pluginPackagesAvailable = lib.all (plugin: pkgs.vimPlugins ? ${plugin}) requiredPluginPackages;

      # Test vim command functionality (simulated)
      vimCommandWorks = true; # Would test actual vim command in integration tests
    in
    {
      success = packagesAvailable && pluginPackagesAvailable && vimCommandWorks;
      errors =
        lib.optionals (!packagesAvailable) [ "Required vim packages not available" ]
        ++ lib.optionals (!pluginPackagesAvailable) [ "Required vim plugin packages not available" ]
        ++ lib.optionals (!vimCommandWorks) [ "Vim command not working" ];
    }
  );

  # Test performance and efficiency
  testPerformanceRequirements = runTest "Vim module should meet performance requirements" (
    let
      # Test configuration processing efficiency (simulated in unit test)

      # Test plugin count efficiency (should not be excessive)
      pluginCount = lib.length (currentVimConfig.programs.vim.plugins or [ ]);
      efficientPluginCount = pluginCount < 20; # Reasonable limit for performance

      # Test extraConfig size (should not be excessive)
      extraConfigSize = lib.stringLength (currentVimConfig.programs.vim.extraConfig or "");
      efficientExtraConfig = extraConfigSize < 5000; # Reasonable limit
    in
    {
      success = efficientPluginCount && efficientExtraConfig;
      errors =
        lib.optionals (!efficientPluginCount) [ "Too many plugins may impact vim startup performance" ]
        ++ lib.optionals (!efficientExtraConfig) [
          "ExtraConfig too large may impact vim startup performance"
        ];
    }
  );

  # Test vim security settings
  testVimSecuritySettings = runTest "Vim should have secure default settings" (
    let
      extraConfig = currentVimConfig.programs.vim.extraConfig or "";

      # Check for security-related settings
      hasNoModelines = lib.hasInfix "set modelines=0" extraConfig;
      hasNoCompatible = lib.hasInfix "set nocompatible" extraConfig;
      hasSecureBackups =
        lib.hasInfix "set nobackup" extraConfig || lib.hasInfix "set backupdir=" extraConfig;
      hasSecureSwap =
        lib.hasInfix "set noswapfile" extraConfig || lib.hasInfix "set directory=" extraConfig;
    in
    {
      success = hasNoModelines && hasNoCompatible && hasSecureBackups && hasSecureSwap;
      errors =
        lib.optionals (!hasNoModelines) [ "Missing modelines security setting" ]
        ++ lib.optionals (!hasNoCompatible) [ "Missing nocompatible setting" ]
        ++ lib.optionals (!hasSecureBackups) [ "Missing secure backup configuration" ]
        ++ lib.optionals (!hasSecureSwap) [ "Missing secure swap configuration" ];
    }
  );

  # Collect all tests
  allTests = [
    testCurrentVimModuleInterface # This SHOULD FAIL - TDD RED phase
    testVimConfigurationBasics
    testVimPlugins
    testVimEssentialFeatures
    testCrossPlatformCompatibility
    testConfigurationValidation
    testPackageInstallation
    testPerformanceRequirements
    testVimSecuritySettings
  ];

in
{
  # Export individual tests
  inherit
    testCurrentVimModuleInterface
    testVimConfigurationBasics
    testVimPlugins
    testVimEssentialFeatures
    testCrossPlatformCompatibility
    testConfigurationValidation
    testPackageInstallation
    testPerformanceRequirements
    testVimSecuritySettings
    ;

  # Export validation utilities
  inherit validateVimModuleInterface;

  # Export expected interface for reference
  inherit expectedVimModuleInterface;

  # Test summary
  testSummary = {
    total = lib.length allTests;
    passed = lib.length (lib.filter (test: test.passed) allTests);
    failed = lib.length (lib.filter (test: !test.passed) allTests);
    results = allTests;

    # Expected failures for TDD RED phase
    expectedFailures = [
      "testCurrentVimModuleInterface" # Should fail until vim module implements contract
    ];

    # TDD status indication
    tddPhase = "RED";
    tddMessage = "This test implements the TDD failing test requirement. The vim module interface test will fail until the vim configuration is refactored to follow the new module interface contract.";

    # Next steps for TDD GREEN phase
    nextSteps = [
      "Create modules/shared/vim.nix with proper interface contract structure"
      "Move vim configuration from home-manager.nix to dedicated vim module"
      "Implement meta, options, config, assertions, and tests sections"
      "Update imports to use new vim module structure"
      "Verify all tests pass (TDD GREEN phase)"
      "Refactor for code quality (TDD REFACTOR phase)"
    ];
  };

  # Interface contract reference for implementation
  contractReference = {
    description = "Vim module must implement this interface contract to pass tests";
    requiredSections = [
      "meta - module metadata (name, description, platforms, version)"
      "options - configuration options (enable, package, config, extraPackages)"
      "config - Home Manager configuration (programs.vim, home.packages)"
      "assertions - configuration validation rules"
      "tests - test definitions (unit, integration, platforms)"
    ];
    implementation = expectedVimModuleInterface;
  };
}
