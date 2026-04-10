# Codebase Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split large files and eliminate duplication across darwin.nix, test-helpers.nix, zsh/default.nix, cache config, and E2E tests while maintaining full backward compatibility.

**Architecture:** Extract concerns from large files into focused sub-files. Parent files import and re-export sub-files so all external references remain valid. Cache duplication is guarded by a pre-commit hook. E2E test boilerplate is reduced via factory functions.

**Tech Stack:** Nix (NixOS/nix-darwin modules, Home Manager), Bash (scripts), pre-commit

---

## File Structure

### darwin.nix split

- **Modify:** `users/shared/darwin.nix` — remove homebrew + scripts sections, add imports
- **Create:** `users/shared/darwin-homebrew.nix` — homebrew configuration extracted from darwin.nix
- **Create:** `users/shared/darwin-scripts.nix` — activation scripts extracted from darwin.nix

### test-helpers.nix split

- **Modify:** `tests/lib/test-helpers.nix` — keep core assertions (lines 1-438), add imports + re-export
- **Create:** `tests/lib/test-helpers-darwin.nix` — macOS assertion helpers (lines 440-599)
- **Create:** `tests/lib/test-helpers-property.nix` — property testing (lines 223-388)
- **Create:** `tests/lib/test-helpers-advanced.nix` — advanced assertions (lines 390-438 + 601-1272)

### zsh/default.nix extraction

- **Modify:** `users/shared/zsh/default.nix` — replace inline sections with imports
- **Create:** `users/shared/zsh/env.nix` — environment/PATH setup
- **Create:** `users/shared/zsh/ssh-agent.nix` — 1Password SSH agent + ssh wrapper
- **Create:** `users/shared/zsh/functions.nix` — utility functions

### Cache sync verification

- **Create:** `scripts/check-cache-sync.sh` — compares flake.nix and lib/cache-config.nix
- **Modify:** `.pre-commit-config.yaml` — add check-cache-sync hook

### E2E test helpers

- **Modify:** `tests/e2e/helpers.nix` — add mkNixosTest and mkBaseNode factories
- **Modify:** `tests/e2e/test-template.nix` — use new factories
- **Modify:** `tests/e2e/build-switch-test.nix` — migrate to factories (example migration)

---

## Task 1: Split darwin.nix — Create darwin-homebrew.nix

**Files:**
- Create: `users/shared/darwin-homebrew.nix`

- [ ] **Step 1: Create darwin-homebrew.nix**

Extract the homebrew configuration from `users/shared/darwin.nix` (lines 25-71 for the cask list, lines 155-195 for the homebrew config block):

```nix
# Homebrew Configuration
#
# GUI applications and Mac App Store apps managed via Homebrew.
# Casks, brews, taps, and MAS apps.

{ ... }:

let
  # Homebrew Cask definitions (GUI applications)
  homebrew-casks = [
    # Development Tools
    "datagrip" # Database IDE from JetBrains
    "ghostty" # GPU-accelerated terminal emulator
    "intellij-idea"
    "utm" # Virtual machine manager for macOS

    # Fonts
    "font-jetbrains-mono" # JetBrains Mono font for terminal

    # Communication Tools
    "discord"
    "notion"
    "slack"
    "telegram"
    "zoom"
    "obsidian"

    # Utility Tools
    "alt-tab"
    "claude"
    "karabiner-elements" # Key remapping and modification tool
    "orbstack" # Docker and Linux VM management
    "tailscale-app" # VPN mesh network with GUI
    "teleport-connect" # Teleport GUI client for secure infrastructure access

    # Entertainment Tools
    "vlc"

    # Study Tools
    "anki"

    # Productivity Tools
    "alfred"
    "raycast"

    # Password Management
    "1password"
    "1password-cli"

    # Browsers
    "google-chrome"
    "brave-browser"
    "firefox"

    "hammerspoon"
  ];
in
{
  # Optimized Homebrew setup for development workflow with performance considerations
  homebrew = {
    enable = true;
    casks = homebrew-casks;

    # Development Services Configuration
    brews = [
      "im-select" # Switch input method from terminal (for Obsidian Vim IME control)
    ];

    # Performance Optimization: Selective Cleanup Strategy
    # Prevents unexpected interruptions during development while maintaining system hygiene
    onActivation = {
      autoUpdate = false; # Manual updates for predictability and control
      upgrade = false; # Avoid automatic upgrades during system rebuilds
      # cleanup = "uninstall";  # Commented for safety during development - enable when needed
    };

    # Optimized Global Homebrew Settings
    # Enhances package management efficiency and dependency tracking
    global = {
      brewfile = true; # Enable Brewfile support for reproducible setups
    };

    # Mac App Store Applications (Optimized Metadata)
    # Carefully selected apps for development productivity and system management
    # IDs obtained via: nix shell nixpkgs#mas && mas search <app name>
    masApps = {
      "Magnet" = 441258766; # Window management tool with multi-monitor support
      "WireGuard" = 1451685025; # Lightweight, secure VPN client
      "KakaoTalk" = 869223134; # Communication platform (if needed)
    };

    # Extended Package Repository Access
    # Additional Homebrew taps for specialized packages and development tools
    # Note: homebrew/cask is now built into Homebrew by default (since 2023)
    taps = [
      "daipeihust/tap" # im-select
    ];
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add users/shared/darwin-homebrew.nix
git commit -m "refactor(darwin): extract homebrew config to darwin-homebrew.nix"
```

## Task 2: Split darwin.nix — Create darwin-scripts.nix

**Files:**
- Create: `users/shared/darwin-scripts.nix`

- [ ] **Step 1: Create darwin-scripts.nix**

Extract activation scripts from `users/shared/darwin.nix` (lines 197-292):

```nix
# macOS Activation Scripts
#
# System activation scripts for:
# - Keyboard input source configuration (cmd+shift+space for Korean/English)
# - Automated cleanup of unused default macOS applications

{ ... }:

{
  # Keyboard Input Source Configuration Script
  # Configures cmd+shift+space for Korean/English input source switching
  system.activationScripts.configureKeyboard = {
    text = ''
      echo "Configuring keyboard input sources..." >&2

      sleep 2

      # Note: KeyRepeat and InitialKeyRepeat are now managed in system.defaults.NSGlobalDomain

      # cmd+shift+space for input source switching (hotkey 60)
      /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{
          enabled = 1;
          value = {
              type = standard;
              parameters = (49, 1048576, 131072);  # space(49), cmd, shift
          };
      }'

      # control+space as backup hotkey (61)
      /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{
          enabled = 1;
          value = {
              type = standard;
              parameters = (49, 262144, 0, 0);        # space, control
          };
      }'

      # Enable language indicator for visual feedback
      /usr/bin/defaults write kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled -bool true

      # Restart system services to apply changes
      if pgrep -x "SystemUIServer" > /dev/null; then
          killall SystemUIServer 2>/dev/null || true
      fi
      if pgrep -x "ControlCenter" > /dev/null; then
          killall ControlCenter 2>/dev/null || true
      fi

      echo "Keyboard configuration complete!" >&2
    '';
  };

  # macOS App Cleanup Activation Script
  # Automated storage optimization through removal of unused default macOS applications
  # Saves 6-8GB of storage space and reduces system resource consumption
  system.activationScripts.cleanupMacOSApps = {
    text = ''
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "Removing unused macOS default apps..." >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

      # 제거할 앱 목록
      apps=(
        "GarageBand.app"
        "iMovie.app"
        "TV.app"
        "Podcasts.app"
        "News.app"
        "Stocks.app"
        "Freeform.app"
      )

      removed_count=0
      skipped_count=0

      for app in "''${apps[@]}"; do
        app_path="/Applications/$app"

        if [ -e "$app_path" ]; then
          echo "  Removing: $app" >&2

          # sudo 없이 제거 시도 (사용자 설치 앱)
          if rm -rf "$app_path" 2>/dev/null; then
            removed_count=$((removed_count + 1))
          else
            # sudo로 재시도 (시스템 앱)
            if sudo rm -rf "$app_path" 2>/dev/null; then
              removed_count=$((removed_count + 1))
            else
              echo "     Failed to remove (SIP protected): $app" >&2
              skipped_count=$((skipped_count + 1))
            fi
          fi
        else
          echo "  ✓  Already removed: $app" >&2
        fi
      done

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "Cleanup complete!" >&2
      echo "   - Removed: $removed_count apps" >&2
      echo "   - Skipped: $skipped_count apps (protected)" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    '';
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add users/shared/darwin-scripts.nix
git commit -m "refactor(darwin): extract activation scripts to darwin-scripts.nix"
```

## Task 3: Split darwin.nix — Update darwin.nix to import sub-files

**Files:**
- Modify: `users/shared/darwin.nix`

- [ ] **Step 1: Update darwin.nix**

Remove the extracted sections and add imports. The file should become:

```nix
# macOS Configuration
#
# Optimized macOS setup with:
# - Performance optimizations (UI, input, memory)
# - Developer-friendly interface (Dock, Finder, Trackpad)
# - Homebrew integration for GUI apps (darwin-homebrew.nix)
# - Automated app cleanup and keyboard config (darwin-scripts.nix)
# - Korean keyboard support with cmd+shift+space

{
  pkgs,
  lib,
  config,
  currentSystemUser,
  ...
}:

let
  # macOS-specific packages
  darwin-packages = with pkgs; [
    dockutil
  ];
in
{
  imports = [
    ./darwin-homebrew.nix
    ./darwin-scripts.nix
  ];

  # ===== Core System Configuration =====
  system.defaults = {
    # Global system preferences and performance optimizations
    NSGlobalDomain = {
      # UI Performance
      NSAutomaticWindowAnimationsEnabled = false; # Disable window animations
      NSWindowResizeTime = 0.1; # Faster window resizing
      NSScrollAnimationEnabled = false; # Disable smooth scrolling

      # Input Optimization
      NSAutomaticCapitalizationEnabled = false; # Disable auto-capitalization
      NSAutomaticSpellingCorrectionEnabled = false; # Disable spell correction
      NSAutomaticQuoteSubstitutionEnabled = false; # Disable smart quotes
      NSAutomaticDashSubstitutionEnabled = false; # Disable smart dashes
      NSAutomaticPeriodSubstitutionEnabled = false; # Disable auto-period
      ApplePressAndHoldEnabled = false; # Faster key repeat

      # Keyboard Speed (macOS GUI 제한을 초과하는 최고속 설정)
      KeyRepeat = 1; # 키 반복 속도 (1-120, 낮을수록 빠름, GUI 최소값: 2)
      InitialKeyRepeat = 10; # 초기 반복 지연 (10-120, 낮을수록 빠름, GUI 최소값: 15)

      # Trackpad Speed (최대 속도 설정)
      "com.apple.trackpad.scaling" = 3.0; # 커서 이동 속도 (0.0-3.0, 최대값)

      # Memory & Battery
      NSDisableAutomaticTermination = false; # Enable app auto-termination
      NSDocumentSaveNewDocumentsToCloud = false; # Disable iCloud auto-save

      # Advanced Optimizations
      "AppleEnableMouseSwipeNavigateWithScrolls" = false; # Disable swipe navigation
      "AppleEnableSwipeNavigateWithScrolls" = false; # Disable Chrome swipe navigation
      "AppleFontSmoothing" = 1; # Reduced font smoothing
      "NSNavPanelExpandedStateForSaveMode" = false; # Compact save dialogs
      "NSNavPanelExpandedStateForSaveMode2" = false; # Compact save dialogs
    };

    # User Interface - Dock
    dock = {
      autohide = true; # Auto-hide dock
      autohide-delay = 0.0; # Instant appearance
      autohide-time-modifier = 0.15; # Faster animation
      expose-animation-duration = 0.2; # Quick Mission Control
      tilesize = 48; # Smaller icons
      mru-spaces = false; # Predictable layout
    };

    # User Interface - Finder
    finder = {
      AppleShowAllFiles = true; # Show hidden files
      FXEnableExtensionChangeWarning = false; # No extension warnings
      _FXSortFoldersFirst = true; # Folders first
      ShowPathbar = true; # Show path navigation
      ShowStatusBar = true; # Show file information
    };

    # User Interface - Trackpad
    trackpad = {
      Clicking = true; # Enable tap-to-click
      TrackpadRightClick = true; # Enable two-finger right-click
      TrackpadThreeFingerDrag = true; # Enable three-finger drag
    };

    # System Management - Spaces
    spaces = {
      spans-displays = false; # Better performance
    };

    # Custom User Preferences (스크롤 속도는 여기서만 설정 가능)
    CustomUserPreferences = {
      "NSGlobalDomain" = {
        "com.apple.scrollwheel.scaling" = 1.0; # 스크롤 속도 (최대값, -1은 가속 비활성화)
      };
    };
  };

  # ===== Authentication Configuration =====
  system.defaults.loginwindow = {
    SHOWFULLNAME = false; # Compact login prompt
    DisableConsoleAccess = false; # Maintain console access
  };

  # ===== System Integration Configuration =====

  # Package Management Configuration
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix Integration
  nix = {
    enable = false; # Required for Determinate compatibility and to prevent conflicts
  };

  # Shell Environment Configuration
  programs.zsh.enable = true;

  # Keyboard Configuration
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system = {
    primaryUser = currentSystemUser; # Dynamic user resolution for multi-environment support
    checks.verifyNixPath = false; # Disable NIX_PATH verification for cleaner builds
    stateVersion = 5; # Updated to current nix-darwin version for compatibility
  };

  # Package Installation
  environment.systemPackages = darwin-packages;

  # Build Performance Optimization
  documentation.enable = false;
}
```

- [ ] **Step 2: Verify the darwin build evaluates correctly**

Run: `USER=$(whoami) nix build '.#darwinConfigurations.macbook-pro.system' --impure --dry-run 2>&1 | tail -5`

Expected: Build graph computed without errors. If there's an error, read the error message and fix accordingly.

- [ ] **Step 3: Commit**

```bash
git add users/shared/darwin.nix
git commit -m "refactor(darwin): import split homebrew and scripts sub-files"
```

## Task 4: Split test-helpers.nix — Create test-helpers-darwin.nix

**Files:**
- Create: `tests/lib/test-helpers-darwin.nix`

- [ ] **Step 1: Create test-helpers-darwin.nix**

Extract macOS assertion helpers from `tests/lib/test-helpers.nix` lines 440-599. These functions depend on `assertTest` and `testSuite` from the core, so they are passed as arguments:

```nix
# macOS-specific test assertion helpers
#
# Provides assertions for testing nix-darwin system.defaults:
# NSGlobalDomain, Dock, Finder, Trackpad, LoginWindow settings,
# plus bulk helpers for settings, patterns, and aliases.
{
  pkgs,
  lib,
  assertTest,
  testSuite,
}:

{
  # Test a single NSGlobalDomain default setting
  # Usage: assertNSGlobalDef "window-animations" "NSAutomaticWindowAnimationsEnabled" false darwinConfig
  assertNSGlobalDef =
    testName: key: expectedValue: darwinConfig:
    assertTest "ns-global-${testName}" (
      darwinConfig.system.defaults.NSGlobalDomain.${key} == expectedValue
    ) "NSGlobalDomain.${key} should be ${toString expectedValue}";

  # Test multiple NSGlobalDomain default settings at once
  # Usage: assertNSGlobalDefs [ ["key1" val1] ["key2" val2] ] darwinConfig
  assertNSGlobalDefs =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTest "ns-global-${builtins.head (
        builtins.split "=" (builtins.elemAt setting 0)
      )}" (
        darwinConfig.system.defaults.NSGlobalDomain.${builtins.elemAt setting 0} == (builtins.elemAt setting 1)
      ) "NSGlobalDomain.${builtins.elemAt setting 0} should be ${toString (builtins.elemAt setting 1)}"
    ) settings;

  # Test a single dock setting
  assertDockSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "dock-${testName}" (
      darwinConfig.system.defaults.dock.${key} == expectedValue
    ) "Dock.${key} should be ${toString expectedValue}";

  # Test multiple dock settings at once
  assertDockSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTest "dock-${builtins.elemAt setting 0}" (
        darwinConfig.system.defaults.dock.${builtins.elemAt setting 1} == (builtins.elemAt setting 2)
      ) "Dock.${builtins.elemAt setting 1} should be ${toString (builtins.elemAt setting 2)}"
    ) settings;

  # Test a single finder setting
  assertFinderSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "finder-${testName}" (
      darwinConfig.system.defaults.finder.${key} == expectedValue
    ) "Finder.${key} should be ${toString expectedValue}";

  # Test multiple finder settings at once
  assertFinderSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTest "finder-${builtins.elemAt setting 0}" (
        darwinConfig.system.defaults.finder.${builtins.elemAt setting 1} == (builtins.elemAt setting 2)
      ) "Finder.${builtins.elemAt setting 1} should be ${toString (builtins.elemAt setting 2)}"
    ) settings;

  # Test a single trackpad setting
  assertTrackpadSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "trackpad-${testName}" (
      darwinConfig.system.defaults.trackpad.${key} == expectedValue
    ) "Trackpad.${key} should be ${toString expectedValue}";

  # Test multiple trackpad settings at once
  assertTrackpadSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTest "trackpad-${builtins.elemAt setting 0}" (
        darwinConfig.system.defaults.trackpad.${builtins.elemAt setting 1} == (builtins.elemAt setting 2)
      ) "Trackpad.${builtins.elemAt setting 1} should be ${toString (builtins.elemAt setting 2)}"
    ) settings;

  # Test a login window setting
  assertLoginWindowSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "login-window-${testName}" (
      darwinConfig.system.defaults.loginwindow.${key} == expectedValue
    ) "Login window.${key} should be ${toString expectedValue}";

  # Test multiple key-value pairs in a nested attribute set
  assertSettings =
    name: settings: expectedValues:
    let
      individualTests = builtins.map (
        key:
        let
          expectedValue = builtins.getAttr key expectedValues;
          actualValue = builtins.getAttr key settings;
          testName = "${name}-${builtins.replaceStrings [ "." ] [ "-" ] key}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "${name}.${key} should be '${toString expectedValue}'"
      ) (builtins.attrNames expectedValues);

      summaryTest = pkgs.runCommand "${name}-settings-summary" { } ''
        echo "✅ Settings group '${name}': All ${toString (builtins.length individualTests)} values match"
        touch $out
      '';
    in
    testSuite "${name}-settings" (individualTests ++ [ summaryTest ]);

  # Test that a list contains all expected patterns
  assertPatterns =
    name: actualList: expectedPatterns:
    let
      individualTests = builtins.map (
        pattern:
        let
          sanitizedName = builtins.replaceStrings [ "*" "." "/" "-" " " ] [ "-" "-" "-" "-" "" ] (
            if pattern == "" then "empty" else pattern
          );
          testName = "${name}-${sanitizedName}";
          hasPattern = builtins.any (p: p == pattern) actualList;
        in
        assertTest testName hasPattern "${name} should include '${pattern}'"
      ) expectedPatterns;

      summaryTest = pkgs.runCommand "${name}-patterns-summary" { } ''
        echo "✅ Pattern group '${name}': All ${toString (builtins.length individualTests)} patterns found"
        touch $out
      '';
    in
    testSuite "${name}-patterns" (individualTests ++ [ summaryTest ]);

  # Test multiple git aliases
  assertAliases =
    aliasSettings: expectedAliases:
    let
      individualTests = builtins.map (
        aliasName:
        let
          expectedValue = builtins.getAttr aliasName expectedAliases;
          actualValue = builtins.getAttr aliasName aliasSettings;
          testName = "git-alias-${aliasName}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "Git should have '${aliasName}' alias for '${expectedValue}'"
      ) (builtins.attrNames expectedAliases);

      summaryTest = pkgs.runCommand "git-aliases-summary" { } ''
        echo "✅ Git aliases: All ${toString (builtins.length individualTests)} aliases configured correctly"
        touch $out
      '';
    in
    testSuite "git-aliases" (individualTests ++ [ summaryTest ]);
}
```

- [ ] **Step 2: Commit**

```bash
git add tests/lib/test-helpers-darwin.nix
git commit -m "refactor(tests): extract macOS assertions to test-helpers-darwin.nix"
```

## Task 5: Split test-helpers.nix — Create test-helpers-property.nix

**Files:**
- Create: `tests/lib/test-helpers-property.nix`

- [ ] **Step 1: Create test-helpers-property.nix**

Extract property testing helpers from `tests/lib/test-helpers.nix` lines 223-388:

```nix
# Property-based testing helpers
#
# Provides:
# - propertyTest: test a property against a list of values
# - multiParamPropertyTest: test binary/ternary properties against value combinations
# - forAllCases: test a property across named test cases
{
  pkgs,
  lib,
  assertTest,
  testSuite,
}:

{
  # Property-based testing helper
  # Tests a property against a list of test values
  propertyTest =
    name: property: testValues:
    let
      testResults = builtins.map (value: {
        value = value;
        result = builtins.tryEval (property value);
      }) testValues;

      allPassed = builtins.all (test: test.result.success) testResults;
      failedTests = builtins.filter (test: !test.result.success) testResults;
    in
    if allPassed then
      pkgs.runCommand "property-test-${name}-pass" { } ''
        echo "✅ Property test ${name}: PASS"
        echo "  Tested ${toString (builtins.length testValues)} values"
        echo "  Property holds for all test cases"
        touch $out
      ''
    else
      pkgs.runCommand "property-test-${name}-fail" { } ''
        echo "❌ Property test ${name}: FAIL"
        echo "  Property failed for ${toString (builtins.length failedTests)} out of ${toString (builtins.length testValues)} values"
        echo ""
        echo "🔍 Failed test cases:"
        ${lib.concatMapStringsSep "\n" (test: ''
          echo "  Value: ${toString test.value}"
          echo "  Error: ${test.result.value or "Unknown error"}"
        '') failedTests}
        exit 1
      '';

  # Enhanced property testing with multiple parameters
  multiParamPropertyTest =
    name: property: testValueSets:
    let
      generateCombinations =
        valueSets:
        if builtins.length valueSets == 0 then
          [ [ ] ]
        else
          let
            rest = generateCombinations (builtins.tail valueSets);
            current = builtins.head valueSets;
          in
          builtins.concatLists (builtins.map (combo: builtins.map (val: [ val ] ++ combo) current) rest);

      combinations = generateCombinations testValueSets;
      testResults = builtins.map (values: {
        values = values;
        result = builtins.tryEval (builtins.foldl' (acc: v: acc v) property values);
      }) combinations;

      allPassed = builtins.all (test: test.result.success) testResults;
      failedTests = builtins.filter (test: !test.result.success) testResults;
    in
    if allPassed then
      pkgs.runCommand "multi-property-test-${name}-pass" { } ''
        echo "✅ Multi-parameter property test ${name}: PASS"
        echo "  Tested ${toString (builtins.length combinations)} combinations"
        echo "  Property holds for all test cases"
        touch $out
      ''
    else
      pkgs.runCommand "multi-property-test-${name}-fail" { } ''
        echo "❌ Multi-parameter property test ${name}: FAIL"
        echo "  Property failed for ${toString (builtins.length failedTests)} out of ${toString (builtins.length combinations)} combinations"
        echo ""
        echo "🔍 Failed test cases:"
        ${lib.concatMapStringsSep "\n" (test: ''
          echo "  Values: [${lib.concatMapStringsSep ", " toString test.values}]"
          echo "  Error: ${test.result.value or "Unknown error"}"
        '') failedTests}
        exit 1
      '';

  # Property testing helper for all cases (forAllCases)
  forAllCases =
    testName: testCases: propertyFn:
    let
      individualTests = builtins.map (
        testCase:
        let
          caseName = "${testName}-${testCase.name or "case"}";
          propertyResult = builtins.tryEval (propertyFn testCase);
        in
        if propertyResult.success then
          assertTest caseName propertyResult.value "Property test failed for case: ${toString testCase}"
        else
          assertTest caseName false
            "Property test threw error for case: ${toString testCase}: ${propertyResult.value}"
      ) testCases;

      summaryTest = pkgs.runCommand "property-test-${testName}-summary" { } ''
        echo "🧪 Property Test Suite: ${testName}"
        echo "Testing ${toString (builtins.length testCases)} cases..."
        echo ""
        ${lib.concatMapStringsSep "\n" (testCase: ''
          echo "  🔍 Testing case: ${testCase.name or "unnamed"}"
        '') testCases}
        echo ""
        echo "✅ All property tests passed for ${testName}"
        echo "Property holds across all test cases"
        touch $out
      '';
    in
    testSuite "${testName}-property-tests" (individualTests ++ [ summaryTest ]);
}
```

- [ ] **Step 2: Commit**

```bash
git add tests/lib/test-helpers-property.nix
git commit -m "refactor(tests): extract property testing to test-helpers-property.nix"
```

## Task 6: Split test-helpers.nix — Create test-helpers-advanced.nix

**Files:**
- Create: `tests/lib/test-helpers-advanced.nix`

- [ ] **Step 1: Create test-helpers-advanced.nix**

Extract advanced assertion helpers from `tests/lib/test-helpers.nix` — this includes lines 306-351 (assertPerformance), 390-410 (assertFileContent), 412-438 (assertTestWithDetailsVerbose, mkSimpleTest), and 601-1272 (assertAttrsEqual, assertGitUserInfo, assertGitSettings, assertGitAliases, assertGitIgnorePatterns, assertContainsGeneric, assertPluginPresent, assertFileReadable, assertImportPresent):

```nix
# Advanced test assertion helpers
#
# Provides:
# - Performance testing (assertPerformance)
# - File content comparison (assertFileContent)
# - Verbose error reporting (assertTestWithDetailsVerbose)
# - Deep equality (assertAttrsEqual)
# - Git configuration validation (assertGitUserInfo, assertGitSettings, assertGitAliases, assertGitIgnorePatterns)
# - Generic membership testing (assertContainsGeneric)
# - Plugin/package validation (assertPluginPresent)
# - File system validation (assertFileReadable)
# - Module import validation (assertImportPresent)
{
  pkgs,
  lib,
  assertTest,
  testSuite,
  mkTest,
}:

{
  # Performance assertion helper
  assertPerformance =
    name: expectedBoundMs: command:
    let
      performanceScript = pkgs.writeShellScript "perf-script-${name}" ''
        # Measure execution time
        start_time=$(/usr/bin/time -p bash -c '${command}' 2>&1 | grep "real" | awk '{print $2}')
        echo "Execution time: $start_time seconds"

        # Convert to milliseconds and check bound
        echo "$start_time * 1000" | bc | sed 's/\.0*$//' | {
          read time_ms
          echo "Time in ms: $time_ms"

          if [ "$time_ms" -le ${toString expectedBoundMs} ]; then
            echo "✅ Performance test ${name}: PASS"
            echo "  Time: $time_ms ms (≤ ${toString expectedBoundMs} ms)"
            exit 0
          else
            echo "❌ Performance test ${name}: FAIL"
            echo "  Time: $time_ms ms (> ${toString expectedBoundMs} ms)"
            exit 1
          fi
        }
      '';
    in
    pkgs.runCommand "perf-test-${name}"
      {
        buildInputs = [ pkgs.bc ];
        passthru.script = performanceScript;
      }
      ''
        echo "🕒 Running performance test: ${name}"
        echo "Expected bound: ${toString expectedBoundMs}ms"
        echo "Command: ${command}"
        echo ""

        ${performanceScript}

        if [ $? -eq 0 ]; then
          touch $out
        else
          exit 1
        fi
      '';

  # File content validation with diff support
  assertFileContent =
    name: expectedPath: actualPath:
    pkgs.runCommand "test-${name}" {
      inherit expectedPath actualPath;
    } ''
      if diff -u "$expectedPath" "$actualPath" > /dev/null 2>&1; then
        echo "PASS: ${name}"
        touch $out
      else
        echo "FAIL: ${name}"
        echo "  File content mismatch"
        echo "  Expected: $expectedPath"
        echo "  Actual: $actualPath"
        echo ""
        echo "Diff:"
        diff -u "$expectedPath" "$actualPath" || true
        exit 1
      fi
    '';

  # Enhanced assertion with verbose error reporting including location info
  assertTestWithDetailsVerbose =
    name: condition: message: expected: actual: file: line:
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "PASS: ${name}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "FAIL: ${name}"
        echo "  ${message}"
        ${lib.optionalString (expected != null) ''
        echo "  Expected: ${expected}"
        ''}
        ${lib.optionalString (actual != null) ''
        echo "  Actual: ${actual}"
        ''}
        ${lib.optionalString (file != null) ''
        echo "  Location: ${file}${lib.optionalString (line != null) ":${toString line}"}"
        ''}
        exit 1
      '';

  # Backward compatibility alias
  mkSimpleTest = mkTest;

  # Compare two attribute sets for deep equality
  assertAttrsEqual =
    name: expected: actual: message:
    let
      expectedKeys = builtins.attrNames expected;
      actualKeys = builtins.attrNames actual;
      allKeys = lib.unique (expectedKeys ++ actualKeys);

      mismatches = builtins.filter (
        key:
        let
          expectedValue = builtins.toString expected.${key} or "<missing>";
          actualValue = builtins.toString actual.${key} or "<missing>";
        in
        expectedValue != actualValue
      ) allKeys;

      allMatch = builtins.length mismatches == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length allKeys)} attributes match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  ${message}"
        echo ""
        echo "🔍 Mismatched attributes:"
        ${lib.concatMapStringsSep "\n" (key: ''
          echo "  ${key}:"
          echo "    Expected: ${builtins.toString expected.${key} or "<missing>"}"
          echo "    Actual: ${builtins.toString actual.${key} or "<missing>"}"
        '') mismatches}
        exit 1
      '';

  # Validate git user configuration
  assertGitUserInfo =
    name: gitConfig: expectedName: expectedEmail:
    let
      userName = gitConfig.userName or "<not set>";
      userEmail = gitConfig.userEmail or "<not set>";
      nameMatch = userName == expectedName;
      emailMatch = userEmail == expectedEmail;
      bothMatch = nameMatch && emailMatch;
    in
    if bothMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git user: ${userName} <${userEmail}>"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git user info mismatch"
        echo ""
        echo "  User Name:"
        echo "    Expected: ${expectedName}"
        echo "    Actual: ${userName}"
        echo "  User Email:"
        echo "    Expected: ${expectedEmail}"
        echo "    Actual: ${userEmail}"
        exit 1
      '';

  # Validate git settings
  assertGitSettings =
    name: gitConfig: expectedSettings:
    let
      extraConfig = gitConfig.extraConfig or { };

      checkSetting =
        key: expectedValue:
        let
          keys = builtins.split "\\." key;
          actualValue = builtins.foldl' (
            acc: k: if acc == null then null else acc.${k} or null
          ) extraConfig keys;

          expectedStr =
            if expectedValue == true then
              "true"
            else if expectedValue == false then
              "false"
            else
              builtins.toString expectedValue;
          actualStr =
            if actualValue == true then
              "true"
            else if actualValue == false then
              "false"
            else if actualValue == null then
              "<not set>"
            else
              builtins.toString actualValue;

          matches = expectedStr == actualStr;
        in
        if matches then
          {
            inherit key;
            matches = true;
          }
        else
          {
            inherit key;
            matches = false;
            expected = expectedStr;
            actual = actualStr;
          };

      results = builtins.map (key: checkSetting key expectedSettings.${key}) (
        builtins.attrNames expectedSettings
      );
      failed = builtins.filter (r: !r.matches) results;
      allMatch = builtins.length failed == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} git settings match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git settings mismatch"
        echo ""
        echo "🔍 Mismatched settings:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.key}:"
          echo "    Expected: ${result.expected}"
          echo "    Actual: ${result.actual}"
        '') failed}
        exit 1
      '';

  # Validate git aliases
  assertGitAliases =
    name: gitConfig: expectedAliases:
    let
      actualAliases = gitConfig.aliases or { };

      checkAlias =
        alias: expectedCommand:
        let
          actualCommand = actualAliases.${alias} or "<not set>";
          matches = actualCommand == expectedCommand;
        in
        if matches then
          {
            inherit alias;
            matches = true;
          }
        else
          {
            inherit alias;
            matches = false;
            expected = expectedCommand;
            actual = actualCommand;
          };

      results = builtins.map (alias: checkAlias alias expectedAliases.${alias}) (
        builtins.attrNames expectedAliases
      );
      failed = builtins.filter (r: !r.matches) results;
      allMatch = builtins.length failed == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} git aliases match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git aliases mismatch"
        echo ""
        echo "🔍 Mismatched aliases:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.alias}:"
          echo "    Expected: ${result.expected}"
          echo "    Actual: ${result.actual}"
        '') failed}
        exit 1
      '';

  # Validate gitignore patterns
  assertGitIgnorePatterns =
    name: gitConfig: expectedPatterns:
    let
      actualPatterns = gitConfig.ignores or [ ];

      checkPattern =
        pattern:
        let
          isPresent = builtins.any (p: p == pattern) actualPatterns;
        in
        if isPresent then
          {
            inherit pattern;
            present = true;
          }
        else
          {
            inherit pattern;
            present = false;
          };

      results = builtins.map checkPattern expectedPatterns;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;
    in
    if allPresent then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} gitignore patterns present"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Gitignore patterns missing"
        echo ""
        echo "🔍 Missing patterns:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.pattern}"
        '') missing}
        exit 1
      '';

  # Generic membership test
  assertContainsGeneric =
    name: needle: haystack: message:
    let
      haystackType = builtins.typeOf haystack;
      isPresent =
        if haystackType == "list" then
          builtins.any (item: item == needle) haystack
        else if haystackType == "set" then
          builtins.hasAttr (builtins.toString needle) haystack
        else if haystackType == "string" then
          lib.hasInfix (builtins.toString needle) haystack
        else
          abort "assertContainsGeneric: haystack must be a list, set, or string";
    in
    assertTest name isPresent "${message}: ${builtins.toString needle} not found in ${haystackType}";

  # Test plugin/package presence
  assertPluginPresent =
    name: plugins: expectedPlugins:
    let
      options = {
        matchType = "exact";
        allowExtra = true;
      };

      pluginNames =
        if builtins.typeOf plugins == "list" then
          plugins
        else if builtins.typeOf plugins == "set" then
          builtins.attrNames plugins
        else
          abort "assertPluginPresent: plugins must be a list or attribute set";

      checkPlugin =
        expectedPlugin:
        let
          isPresent =
            if options.matchType == "exact" then
              builtins.any (p: p == expectedPlugin) pluginNames
            else if options.matchType == "regex" then
              builtins.any (p: builtins.match expectedPlugin p != null) pluginNames
            else
              abort "assertPluginPresent: matchType must be 'exact' or 'regex'";
        in
        if isPresent then
          {
            plugin = expectedPlugin;
            present = true;
          }
        else
          {
            plugin = expectedPlugin;
            present = false;
          };

      results = builtins.map checkPlugin expectedPlugins;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;

      unexpected =
        if options.allowExtra then
          [ ]
        else
          builtins.filter (
            p:
            let
              isExpected =
                if options.matchType == "exact" then
                  builtins.any (exp: exp == p) expectedPlugins
                else
                  builtins.any (exp: builtins.match exp p != null) expectedPlugins;
            in
            !isExpected
          ) pluginNames;
      hasUnexpected = builtins.length unexpected > 0;
    in
    if allPresent && !hasUnexpected then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length expectedPlugins)} expected plugins present"
        ${if options.allowExtra then "" else ''
          echo "  No unexpected plugins found"
        ''}
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        ${if !allPresent then ''
          echo "  Missing plugins:"
          ${lib.concatMapStringsSep "\n" (result: ''
            echo "    ${result.plugin}"
          '') missing}
        '' else ""}
        ${if hasUnexpected then ''
          echo ""
          echo "  Unexpected plugins found:"
          ${lib.concatMapStringsSep "\n" (p: ''
            echo "    ${p}"
          '') unexpected}
        '' else ""}
        exit 1
      '';

  # File system validation
  assertFileReadable =
    name: derivationOrPath: expectedPaths:
    let
      normalizePaths =
        paths:
        if builtins.typeOf paths == "list" then
          builtins.listToAttrs (builtins.map (p: {
            name = p;
            value = true;
          }) paths)
        else
          paths;

      pathSpecs = normalizePaths expectedPaths;

      checkPath =
        relPath: options:
        let
          fullPath =
            if builtins.typeOf derivationOrPath == "set" then
              "${derivationOrPath}/${relPath}"
            else
              "${derivationOrPath}/${relPath}";

          readResult = builtins.tryEval (
            if builtins.typeOf derivationOrPath == "set" then
              builtins.readFile fullPath
            else
              "mock-success"
          );

          isReadable = readResult.success;

          expectedType =
            if options == true then
              null
            else if builtins.typeOf options == "set" then
              options.type or null
            else
              null;

          typeMatches = true;

          executableExpected =
            if options == true then
              false
            else if builtins.typeOf options == "set" then
              options.executable or false
            else
              false;

          executableMatches = true;
        in
        if !isReadable then
          {
            path = relPath;
            readable = false;
          }
        else if !typeMatches then
          {
            path = relPath;
            readable = true;
            typeMatches = false;
            inherit expectedType;
          }
        else if !executableMatches then
          {
            path = relPath;
            readable = true;
            typeMatches = true;
            executableMatches = false;
          }
        else
          {
            path = relPath;
            readable = true;
            typeMatches = true;
            executableMatches = true;
          };

      results = builtins.map (relPath: checkPath relPath pathSpecs.${relPath}) (
        builtins.attrNames pathSpecs
      );

      unreadablePaths = builtins.filter (r: !r.readable) results;
      typeMismatches = builtins.filter (r: r.readable && !r.typeMatches) results;
      executableMismatches = builtins.filter (r: r.readable && r.typeMatches && !r.executableMatches) results;

      allValid =
        builtins.length unreadablePaths == 0 && builtins.length typeMismatches == 0
        && builtins.length executableMismatches == 0;
    in
    if allValid then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} paths are valid"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  File system validation failed"
        ${if builtins.length unreadablePaths > 0 then ''
          echo ""
          echo "  Unreadable paths:"
          ${lib.concatMapStringsSep "\n" (r: ''
            echo "    ${r.path}"
          '') unreadablePaths}
        '' else ""}
        ${if builtins.length typeMismatches > 0 then ''
          echo ""
          echo "  Type mismatches:"
          ${lib.concatMapStringsSep "\n" (r: ''
            echo "    ${r.path} (expected type: ${r.expectedType})"
          '') typeMismatches}
        '' else ""}
        exit 1
      '';

  # Module import validation
  assertImportPresent =
    name: moduleConfig: expectedImports:
    let
      directImports = moduleConfig.imports or [ ];
      configKeys = builtins.attrNames moduleConfig;

      normalizeImport =
        importSpec:
        if builtins.typeOf importSpec == "string" then
          {
            type = "any";
            pattern = importSpec;
            matchType = "exact";
          }
        else if builtins.typeOf importSpec == "set" then
          if importSpec ? regex then
            {
              type = importSpec.type or "any";
              pattern = importSpec.regex;
              matchType = "regex";
            }
          else if importSpec ? path then
            {
              type = importSpec.type or "any";
              pattern = importSpec.path;
              matchType = "exact";
            }
          else
            abort "assertImportPresent: invalid import specification"
        else
          abort "assertImportPresent: import spec must be string or attribute set";

      checkImport =
        importSpec:
        let
          spec = normalizeImport importSpec;

          inDirectImports =
            if spec.matchType == "exact" then
              builtins.any (imp: imp == spec.pattern) directImports
            else
              builtins.any (imp: builtins.match spec.pattern imp != null) directImports;

          inConfigKeys =
            if spec.matchType == "regex" then
              builtins.any (key: builtins.match spec.pattern key != null) configKeys
            else
              false;

          matchesInValues =
            if spec.matchType == "regex" then
              false
            else
              false;

          isPresent = inDirectImports || inConfigKeys || matchesInValues;
        in
        if isPresent then
          {
            spec = spec.pattern;
            present = true;
          }
        else
          {
            spec = spec.pattern;
            present = false;
          };

      results = builtins.map checkImport expectedImports;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;
    in
    if allPresent then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length expectedImports)} expected imports present"
        echo "  Direct imports found: ${toString (builtins.length directImports)}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Module import validation failed"
        echo ""
        echo "  Missing imports:"
        ${lib.concatMapStringsSep "\n" (r: ''
          echo "    ${r.spec}"
        '') missing}
        echo ""
        echo "  Found imports:"
        ${lib.concatMapStringsSep "\n" (imp: ''
          echo "    ${imp}"
        '') directImports}
        exit 1
      '';
}
```

- [ ] **Step 2: Commit**

```bash
git add tests/lib/test-helpers-advanced.nix
git commit -m "refactor(tests): extract advanced assertions to test-helpers-advanced.nix"
```

## Task 7: Split test-helpers.nix — Update test-helpers.nix to import and re-export

**Files:**
- Modify: `tests/lib/test-helpers.nix`

- [ ] **Step 1: Rewrite test-helpers.nix to keep core + re-export sub-files**

Replace the entire file with core assertions (lines 1-222 of the original) plus import/re-export logic. The file should contain:

```nix
# Extended test helpers for evantravers refactor
# Builds upon existing NixTest framework with additional assertions
#
# Core assertions live here. Specialized helpers are split into:
# - test-helpers-darwin.nix: macOS system.defaults assertions
# - test-helpers-property.nix: property-based testing
# - test-helpers-advanced.nix: performance, file, git, plugin, import assertions
{
  pkgs,
  lib,
  # Parameterized test configuration to eliminate external dependencies
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
    };
  },
}:

let
  # Simple NixTest framework replacement (since nixtest-template.nix doesn't exist)
  nixtest = {
    test =
      name: condition:
      if condition then
        pkgs.runCommand "test-${name}-pass" { } ''
          echo "✅ ${name}: PASS"
          touch $out
        ''
      else
        pkgs.runCommand "test-${name}-fail" { } ''
          echo "❌ ${name}: FAIL"
          exit 1
        '';

    suite =
      name: tests:
      pkgs.runCommand "test-suite-${name}" { } ''
        echo "Running test suite: ${name}"
        echo "✅ Test suite ${name}: All tests passed"
        touch $out
      '';

    assertions = {
      assertHasAttr = attrName: set: builtins.hasAttr attrName set;
    };
  };

  # Core assertions (defined in let so they can be passed to sub-files)
  assertTest =
    name: condition: message:
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL - ${message}"
        exit 1
      '';

  testSuite =
    name: tests:
    pkgs.runCommand "test-suite-${name}" { } ''
      echo "Running test suite: ${name}"
      ${lib.concatMapStringsSep "\n" (t: "cat ${t}") tests}
      echo "✅ Test suite ${name}: All tests passed"
      touch $out
    '';

  mkTest =
    name: testLogic:
    pkgs.runCommand "test-${name}-results" { } ''
      echo "Running ${name}..."
      ${testLogic}
      echo "✅ ${name}: PASS"
      touch $out
    '';

  # Import sub-files, passing shared dependencies
  darwinHelpers = import ./test-helpers-darwin.nix {
    inherit pkgs lib assertTest testSuite;
  };
  propertyHelpers = import ./test-helpers-property.nix {
    inherit pkgs lib assertTest testSuite;
  };
  advancedHelpers = import ./test-helpers-advanced.nix {
    inherit pkgs lib assertTest testSuite mkTest;
  };

in
rec {
  # Re-export NixTest framework
  inherit (nixtest) nixtest;

  # Core assertions
  inherit assertTest testSuite mkTest;

  # Behavioral file validation check
  assertFileExists =
    name: derivation: path:
    let
      fullPath = "${derivation}/${path}";
      readResult = builtins.tryEval (builtins.readFile fullPath);
    in
    assertTest name (
      readResult.success && builtins.stringLength readResult.value > 0
    ) "File ${path} not readable or empty in derivation";

  # Attribute existence check
  assertHasAttr =
    name: attrName: set:
    assertTest name (builtins.hasAttr attrName set) "Attribute ${attrName} not found";

  # String contains check
  assertContains =
    name: needle: haystack:
    assertTest name (lib.hasInfix needle haystack) "${needle} not found in ${haystack}";

  # Derivation builds successfully
  assertBuilds =
    name: drv:
    pkgs.runCommand "test-${name}-builds" { buildInputs = [ drv ]; } ''
      echo "Testing if ${drv.name} builds..."
      ${drv}/bin/* --version 2>/dev/null || echo "Version check not available"
      echo "✅ ${name}: Builds successfully"
      touch $out
    '';

  # Parameterized test helpers
  getUserHomeDir = user: "${testConfig.homeDirPrefix}/${user}";
  getTestUserHome = getUserHomeDir testConfig.username;

  createTestUserConfig =
    additionalConfig:
    {
      home = {
        username = testConfig.username;
        homeDirectory = getTestUserHome;
      }
      // (additionalConfig.home or { });
    }
    // (additionalConfig.config or { });

  # Platform-conditional test execution
  runIfPlatform =
    platform: test:
    if platform == "darwin" && testConfig.platformSystem.isDarwin then
      test
    else if platform == "linux" && testConfig.platformSystem.isLinux then
      test
    else if platform == "any" then
      test
    else
      pkgs.runCommand "test-skipped-${platform}" { } ''
        echo "⏭️  Skipped (${platform}-only test on current platform)"
        touch $out
      '';

  # Run a list of tests and aggregate results
  runTestList =
    testName: tests:
    pkgs.runCommand "test-${testName}" { } ''
      echo "🧪 Running test suite: ${testName}"
      echo ""

      overall_success=true

      ${lib.concatMapStringsSep "\n" (test: ''
        echo "🔍 Running test: ${test.name}"
        echo "  Expected: ${toString test.expected}"
        echo "  Actual: ${toString test.actual}"

        if [ "${toString test.expected}" = "${toString test.actual}" ]; then
          echo "  ✅ PASS: ${test.name}"
        else
          echo "  ❌ FAIL: ${test.name}"
          echo "    Expected: ${toString test.expected}"
          echo "    Actual: ${toString test.actual}"
          overall_success=false
        fi
        echo ""
      '') tests}

      if [ "$overall_success" = "true" ]; then
        echo "✅ All tests in '${testName}' passed!"
        touch $out
      else
        echo "❌ Some tests in '${testName}' failed!"
        exit 1
      fi
    '';

  # Enhanced assertion with detailed error reporting
  assertTestWithDetails =
    name: expected: actual: message:
    let
      expectedStr = toString expected;
      actualStr = toString actual;
      isEqual = expectedStr == actualStr;
    in
    if isEqual then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Expected: ${expectedStr}"
        echo "  Actual: ${actualStr}"
        echo "  ${message}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Expected: ${expectedStr}"
        echo "  Actual: ${actualStr}"
        echo "  ${message}"
        echo ""
        echo "🔍 Comparison details:"
        echo "  Expected length: ${toString (builtins.stringLength expectedStr)}"
        echo "  Actual length: ${toString (builtins.stringLength actualStr)}"
        echo "  Expected type: ${builtins.typeOf expected}"
        echo "  Actual type: ${builtins.typeOf actual}"
        exit 1
      '';
}
// darwinHelpers
// propertyHelpers
// advancedHelpers
```

Note: The `rec { ... } // darwinHelpers // ...` pattern works in Nix because the `in` clause of the enclosing `let` block evaluates to the merged attribute set. All functions from `test-helpers-darwin.nix`, `test-helpers-property.nix`, and `test-helpers-advanced.nix` become top-level attributes of the returned set.

- [ ] **Step 2: Run tests to verify backward compatibility**

Run: `make test 2>&1 | tail -20`

Expected: All tests pass. If any test fails with "attribute not found", check which function is missing from the re-exports.

- [ ] **Step 3: Commit**

```bash
git add tests/lib/test-helpers.nix
git commit -m "refactor(tests): slim test-helpers.nix to core + re-export sub-files"
```

## Task 8: Extract zsh env.nix

**Files:**
- Create: `users/shared/zsh/env.nix`

- [ ] **Step 1: Create env.nix**

Extract the "Environment and PATH setup" section from `users/shared/zsh/default.nix` (lines 152-188). This file returns a raw shell string, matching the pattern of `claude-wrappers.nix`:

```nix
# Environment variables and PATH configuration for Zsh
#
# Sets up:
# - PATH: pnpm, npm, local bin, cargo, go, gem, homebrew
# - Locale: en_US.UTF-8
# - Editor: vim
# - npm config
# - GitHub CLI token

# Note: isDarwin is not available here since this is a raw string import.
# Homebrew PATH is handled inline via the isDarwin conditional in default.nix.

''
# PATH configuration - Global package managers
export PATH="$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH"
export PATH="$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH"
export PATH="$HOME/.local/share/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
# Cargo (Rust)
export PATH="$HOME/.cargo/bin:$PATH"
# Go
export PATH="$HOME/go/bin:$PATH"
# Gem (Ruby) - only if GEM_HOME is set to user directory
if [[ -n "$GEM_HOME" ]]; then
  export PATH=$GEM_HOME/bin:$PATH
fi

# History configuration
export HISTIGNORE="pwd:ls:cd"

# Locale settings for UTF-8 support
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Editor preferences
export EDITOR="vim"
export VISUAL="vim"

# npm configuration
export NPM_CONFIG_PREFIX="$HOME/.npm-global"

# GitHub CLI token
export GITHUB_TOKEN=$(gh auth token)
''
```

- [ ] **Step 2: Commit**

```bash
git add users/shared/zsh/env.nix
git commit -m "refactor(zsh): extract environment/PATH config to env.nix"
```

## Task 9: Extract zsh ssh-agent.nix

**Files:**
- Create: `users/shared/zsh/ssh-agent.nix`

- [ ] **Step 1: Create ssh-agent.nix**

Extract the "SSH agent setup" section from `users/shared/zsh/default.nix` (lines 192-259). Note: this section uses `isDarwin` via Nix string interpolation, but the raw string pattern doesn't support that. Instead, `ssh-agent.nix` will be a **function** that takes `isDarwin` and `lib` and returns a string:

```nix
# 1Password SSH agent setup and SSH wrapper for Zsh
#
# Provides:
# - _setup_1password_agent(): detect and configure 1Password SSH agent
# - ssh-add key registration
# - ssh() wrapper with autossh fallback

{ isDarwin, lib }:

''
# Optimized 1Password SSH agent detection with platform awareness
_setup_1password_agent() {
  # Early exit if already configured
  [[ -n "$${SSH_AUTH_SOCK:-}" ]] && [[ -S "$SSH_AUTH_SOCK" ]] && return 0

  local socket_paths=()

  # Platform-specific socket detection
  ${lib.optionalString isDarwin ''
    # macOS: Check Group Containers efficiently
    for container in ~/Library/Group\ Containers/*.com.1password; do
      [[ -d "$container" ]] && socket_paths+=("$container/t/agent.sock")
    done 2>/dev/null
  ''}

  # Common cross-platform locations
  socket_paths+=(
    ~/.1password/agent.sock
    /tmp/1password-ssh-agent.sock
    ~/Library/Containers/com.1password.1password/Data/tmp/agent.sock
  )

  # Find first available socket
  for sock in "$${socket_paths[@]}"; do
    if [[ -S "$sock" ]]; then
      export SSH_AUTH_SOCK="$sock"
      return 0
    fi
  done

  return 1
}

_setup_1password_agent

# Add SSH key to agent if not already registered
if [[ -f ~/.ssh/id_ed25519 ]]; then
  ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf ~/.ssh/id_ed25519 2>/dev/null | awk '{print $2}')" \
    || ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
''
```

- [ ] **Step 2: Commit**

```bash
git add users/shared/zsh/ssh-agent.nix
git commit -m "refactor(zsh): extract SSH agent setup to ssh-agent.nix"
```

## Task 10: Extract zsh functions.nix

**Files:**
- Create: `users/shared/zsh/functions.nix`

- [ ] **Step 1: Create functions.nix**

Extract utility functions from `users/shared/zsh/default.nix` (lines 236-291). The `ssh()` wrapper was already in the SSH agent section, so this file gets `shell()`, `idea()`, `setup_ssh_agent_for_gui()`, and the `ssh()` wrapper:

```nix
# Utility shell functions for Zsh
#
# Provides:
# - shell(): quick nix-shell access
# - ssh(): enhanced SSH wrapper with autossh fallback
# - idea(): IntelliJ IDEA background launcher
# - setup_ssh_agent_for_gui(): SSH agent for GUI apps

''
# nix shortcuts
shell() {
    nix-shell '<nixpkgs>' -A "$1"
}

# Enhanced SSH wrapper with intelligent reconnection
ssh() {
  # Optimized connection wrapper with autossh fallback
  if command -v autossh >/dev/null 2>&1; then
    # Use autossh with optimized settings for reliability
    AUTOSSH_POLL=60 AUTOSSH_FIRST_POLL=30 autossh -M 0 \
      -o "ServerAliveInterval=30" \
      -o "ServerAliveCountMax=3" \
      "$@"
  else
    # Enhanced regular SSH with connection optimization
    command ssh \
      -o "ServerAliveInterval=60" \
      -o "ServerAliveCountMax=3" \
      -o "TCPKeepAlive=yes" \
      "$@"
  fi
}

# IntelliJ IDEA background launcher
# Runs IntelliJ IDEA in background to avoid blocking terminal
# Usage: idea [project-dir] [file-path]
idea() {
  if command -v idea >/dev/null 2>&1; then
    # Run IntelliJ IDEA in background, disown from shell
    # Preserve SSH agent and other important environment variables
    nohup env SSH_AUTH_SOCK="$SSH_AUTH_SOCK" SSH_AGENT_PID="$SSH_AGENT_PID" \
      GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" \
      command idea "$@" >/dev/null 2>&1 &
    disown %% 2>/dev/null || true
    echo "\033[0;32mIntelliJ IDEA started in background with SSH agent integration\033[0m"
  else
    echo "\033[0;31mIntelliJ IDEA not found. Please install it first.\033[0m"
    return 1
  fi
}

# SSH agent setup for GUI applications (including IntelliJ IDEA)
# Ensures GUI apps can access SSH agent for Git operations
setup_ssh_agent_for_gui() {
  if [[ -n "$SSH_AUTH_SOCK" && -S "$SSH_AUTH_SOCK" ]]; then
    # Set SSH agent variables for GUI applications
    launchctl setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null || true
    [[ -n "$SSH_AGENT_PID" ]] && launchctl setenv SSH_AGENT_PID "$SSH_AGENT_PID" 2>/dev/null || true
    echo "SSH agent configured for GUI applications"
  fi
}

# Setup SSH agent for GUI applications (IntelliJ IDEA, etc.)
setup_ssh_agent_for_gui
''
```

- [ ] **Step 2: Commit**

```bash
git add users/shared/zsh/functions.nix
git commit -m "refactor(zsh): extract utility functions to functions.nix"
```

## Task 11: Update zsh/default.nix to import extracted files

**Files:**
- Modify: `users/shared/zsh/default.nix`

- [ ] **Step 1: Update default.nix**

Replace the inline sections with imports. The `initContent` should become:

```nix
    initContent = lib.mkAfter ''
      # =============================================================================
      # Section: Nix daemon initialization
      # =============================================================================
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Local overrides (not tracked in git)
      if [[ -f ~/.zshrc.local ]]; then
        . ~/.zshrc.local
      fi

      # =============================================================================
      # Section: Claude Code wrapper functions
      # =============================================================================
      ${import ./claude-wrappers.nix}
      # =============================================================================
      # Section: Environment and PATH setup
      # =============================================================================
      ${import ./env.nix}
      # Homebrew PATH configuration (macOS only)
      ${lib.optionalString isDarwin ''
        if [[ -d /opt/homebrew ]]; then
          export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        fi
      ''}

      # =============================================================================
      # Section: SSH agent setup
      # =============================================================================
      ${import ./ssh-agent.nix { inherit isDarwin lib; }}

      # =============================================================================
      # Section: Utility functions
      # =============================================================================
      ${import ./functions.nix}

      # =============================================================================
      # Section: Git worktree wrapper
      # =============================================================================
      ${import ./gw.nix}
    '';
```

Note: The Homebrew PATH block stays in `default.nix` because it uses `isDarwin` which requires Nix interpolation context. Similarly, `ssh-agent.nix` is called as a function `(import ./ssh-agent.nix { inherit isDarwin lib; })` instead of a plain string.

- [ ] **Step 2: Verify zsh configuration builds**

Run: `USER=$(whoami) nix build '.#homeConfigurations."jito.hello".activationPackage' --impure --dry-run 2>&1 | tail -5`

Expected: Build graph computed without errors.

- [ ] **Step 3: Commit**

```bash
git add users/shared/zsh/default.nix
git commit -m "refactor(zsh): replace inline sections with file imports"
```

## Task 12: Create cache sync verification script

**Files:**
- Create: `scripts/check-cache-sync.sh`

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
# Check that flake.nix nixConfig and lib/cache-config.nix are in sync.
# Used as a pre-commit hook.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
FLAKE="$REPO_ROOT/flake.nix"
CACHE_CONFIG="$REPO_ROOT/lib/cache-config.nix"

# Extract substituters from flake.nix (between nixConfig's substituters brackets)
flake_substituters=$(sed -n '/nixConfig/,/accept-flake-config/{/substituters/,/\]/p}' "$FLAKE" \
  | grep -o '"[^"]*"' | sort)

# Extract substituters from cache-config.nix
cache_substituters=$(sed -n '/substituters/,/\]/p' "$CACHE_CONFIG" \
  | grep -o '"[^"]*"' | sort)

# Extract trusted-public-keys from flake.nix
flake_keys=$(sed -n '/nixConfig/,/accept-flake-config/{/trusted-public-keys/,/\]/p}' "$FLAKE" \
  | grep -o '"[^"]*"' | sort)

# Extract trusted-public-keys from cache-config.nix
cache_keys=$(sed -n '/trusted-public-keys/,/\]/p' "$CACHE_CONFIG" \
  | grep -o '"[^"]*"' | sort)

errors=0

if [ "$flake_substituters" != "$cache_substituters" ]; then
  echo "ERROR: substituters mismatch between flake.nix and lib/cache-config.nix" >&2
  echo "" >&2
  echo "flake.nix:" >&2
  echo "$flake_substituters" >&2
  echo "" >&2
  echo "lib/cache-config.nix:" >&2
  echo "$cache_substituters" >&2
  errors=1
fi

if [ "$flake_keys" != "$cache_keys" ]; then
  echo "ERROR: trusted-public-keys mismatch between flake.nix and lib/cache-config.nix" >&2
  echo "" >&2
  echo "flake.nix:" >&2
  echo "$flake_keys" >&2
  echo "" >&2
  echo "lib/cache-config.nix:" >&2
  echo "$cache_keys" >&2
  errors=1
fi

if [ "$errors" -eq 0 ]; then
  echo "Cache config is in sync."
fi

exit $errors
```

- [ ] **Step 2: Make executable and test**

Run: `chmod +x scripts/check-cache-sync.sh && bash scripts/check-cache-sync.sh`

Expected: "Cache config is in sync." with exit code 0.

- [ ] **Step 3: Commit**

```bash
git add scripts/check-cache-sync.sh
git commit -m "feat: add cache config sync verification script"
```

## Task 13: Add cache sync pre-commit hook

**Files:**
- Modify: `.pre-commit-config.yaml`

- [ ] **Step 1: Add hook to the local repo section**

Add the `check-cache-sync` hook to the existing `- repo: local` section in `.pre-commit-config.yaml`, right after the `test-all` hook (before the closing of that repo block):

```yaml
      - id: check-cache-sync
        name: Check cache config sync
        entry: scripts/check-cache-sync.sh
        language: script
        pass_filenames: false
        files: '(flake\.nix|lib/cache-config\.nix)'
```

- [ ] **Step 2: Verify pre-commit config is valid**

Run: `pre-commit run check-cache-sync --all-files 2>&1 | tail -5`

Expected: "Passed" or "Check cache config sync...Passed"

- [ ] **Step 3: Commit**

```bash
git add .pre-commit-config.yaml
git commit -m "feat: add pre-commit hook for cache config sync check"
```

## Task 14: Add E2E test factory functions to helpers.nix

**Files:**
- Modify: `tests/e2e/helpers.nix`

- [ ] **Step 1: Add mkNixosTest and mkBaseNode to helpers.nix**

Add the two factory functions to the existing attribute set. The file currently takes `{ pkgs, platformSystem }` — add `lib` to the arguments:

Add to the function arguments: `lib` (after `pkgs`).

Add to the returned attribute set (before the closing `}`):

```nix
  # Factory: resolve nixosTest function (replaces boilerplate in each E2E test)
  mkNixosTest =
    { nixpkgs, system }:
    pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });

  # Factory: base VM node configuration (common defaults for E2E tests)
  mkBaseNode =
    {
      hostname,
      extraConfig ? { },
    }:
    {
      config,
      pkgs,
      ...
    }:
    lib.mkMerge [
      {
        system.stateVersion = "24.11";
        networking.hostName = hostname;
        networking.useDHCP = false;
        networking.firewall.enable = false;
        virtualisation.cores = 2;
        virtualisation.memorySize = 2048;
        virtualisation.diskSize = 4096;
        nix = {
          extraOptions = ''
            experimental-features = nix-command flakes
            accept-flake-config = true
          '';
          settings = {
            substituters = [ "https://cache.nixos.org/" ];
            trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
          };
        };
        users.users.testuser = {
          isNormalUser = true;
          password = "test";
          extraGroups = [ "wheel" ];
          shell = pkgs.bash;
        };
        environment.systemPackages = with pkgs; [
          git
          vim
          curl
          jq
        ];
        security.sudo.wheelNeedsPassword = false;
      }
      extraConfig
    ];
```

Also add `lib` to the function signature:

```nix
{
  pkgs,
  lib,
  platformSystem,
}:
```

- [ ] **Step 2: Commit**

```bash
git add tests/e2e/helpers.nix
git commit -m "feat(tests): add mkNixosTest and mkBaseNode factories to E2E helpers"
```

## Task 15: Migrate test-template.nix to use factories

**Files:**
- Modify: `tests/e2e/test-template.nix`

- [ ] **Step 1: Update test-template.nix to use the factory functions**

Replace the file content with:

```nix
# End-to-End Test Template
#
# This is a template for writing E2E tests.
# Copy this file to tests/e2e/<feature>-test.nix and modify.
#
# E2E tests should:
# - Test complete system scenarios in a VM
# - Have long execution time (5-15 minutes)
# - Validate real-world workflows
# - Only be run manually or in CI (excluded from auto-discovery)
#
# Quick Start:
# 1. Copy this file: cp tests/e2e/test-template.nix tests/e2e/my-scenario-test.nix
# 2. Edit the test configuration below
# 3. Run: nix build '.#checks.x86_64-linux.e2e-my-scenario' --impure
#
# NOTE: E2E tests are NOT auto-discovered. They must be run manually
# or explicitly included in CI workflows.

{
  pkgs ? import <nixpkgs> { },
  nixpkgs ? <nixpkgs>,
  lib ? pkgs.lib,
  system ? builtins.currentSystem,
  self ? null,
  inputs ? { },
}:

let
  e2eHelpers = import ./helpers.nix {
    inherit pkgs lib;
    platformSystem = { isDarwin = false; isLinux = true; };
  };
  nixosTest = e2eHelpers.mkNixosTest { inherit nixpkgs system; };

in
nixosTest {
  # Test name
  name = "my-e2e-test";

  # Define the VM node(s) using factory
  nodes.machine = e2eHelpers.mkBaseNode {
    hostname = "test-machine";
    # Add test-specific configuration:
    # extraConfig = {
    #   services.my-service.enable = true;
    # };
  };

  # Test script - Python-based test logic
  testScript = ''
    start_all()

    # Wait for system to be ready
    machine.wait_for_unit("multi-user.target")

    print("🚀 Starting E2E Test: my-e2e-test")

    # ===== BASIC SYSTEM TESTS =====

    # Verify basic tools are available
    machine.succeed("which git")
    machine.succeed("which vim")
    machine.succeed("which curl")

    # Verify user exists
    machine.succeed("id -u testuser")

    # ===== USER SCENARIO TESTS =====

    # Test user can perform actions
    machine.succeed("su - testuser -c 'git --version'")
    machine.succeed("su - testuser -c 'vim --version'")

    # Test user home directory
    machine.succeed("su - testuser -c 'test -d /home/testuser'")

    print("✅ All E2E tests passed!")
  '';
}
```

- [ ] **Step 2: Commit**

```bash
git add tests/e2e/test-template.nix
git commit -m "refactor(tests): migrate test-template.nix to use E2E factory helpers"
```

## Task 16: Run full test suite and verify

**Files:** None (verification only)

- [ ] **Step 1: Run make test**

Run: `make test 2>&1 | tail -20`

Expected: All tests pass.

- [ ] **Step 2: Verify darwin build**

Run: `USER=$(whoami) nix build '.#darwinConfigurations.macbook-pro.system' --impure --dry-run 2>&1 | tail -5`

Expected: No errors.

- [ ] **Step 3: Verify home-manager build**

Run: `USER=$(whoami) nix build '.#homeConfigurations."jito.hello".activationPackage' --impure --dry-run 2>&1 | tail -5`

Expected: No errors.

- [ ] **Step 4: Verify cache sync**

Run: `bash scripts/check-cache-sync.sh`

Expected: "Cache config is in sync." with exit code 0.

- [ ] **Step 5: Run format check**

Run: `make format 2>&1 | tail -5`

Expected: No formatting changes needed, or auto-formatted successfully.
