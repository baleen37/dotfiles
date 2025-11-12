# Tmux Configuration Tests
#
# tmux 터미널 멀티플렉서 설정 테스트
# - 기본 설정 검증
# - 패키지 설치 확인
# - 설정 파일 생성 검증
# - 플러그인 설정 확인
#
# 이 테스트는 통합된 헬퍼 함수를 사용하여 중복을 제거합니다

{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Import unified test helpers
  testHelpers = import ../lib/unified-test-helpers.nix { inherit pkgs lib; };
  helpers = testHelpers;

  # Import tmux module for testing
  tmuxModule = import ../../users/shared/tmux.nix;

  # Create test configuration
  testConfig = {
    home = {
      username = helpers.testConfig.username;
      homeDirectory = helpers.getTestUserHome;
    };
  };

  # Create test derivation with tmux configuration
  tmuxTestConfig = tmuxModule {
    inherit pkgs lib;
    config = testConfig;
  };

in
let
  # Test 1: tmux module imports successfully
  importTest = helpers.assertTest "tmux-import"
    (helpers.canImport ../../users/shared/tmux.nix)
    "tmux module should import without errors";

  # Test 2: tmux is enabled
  enabledTest = helpers.assertTest "tmux-enabled"
    (tmuxTestConfig.programs.tmux.enable == true)
    "tmux should be enabled";

  # Test 3: terminal setting is correct
  terminalTest = helpers.assertTest "tmux-terminal"
    (tmuxTestConfig.programs.tmux.terminal == "screen-256color")
    "tmux terminal should be set to screen-256color";

  # Test 4: prefix is Ctrl+b
  prefixTest = helpers.assertTest "tmux-prefix"
    (tmuxTestConfig.programs.tmux.prefix == "C-b")
    "tmux prefix should be Ctrl+b";

  # Test 5: escape time is optimized
  escapeTimeTest = helpers.assertTest "tmux-escape-time"
    (tmuxTestConfig.programs.tmux.escapeTime == 0)
    "tmux escape time should be 0 for performance";

  # Test 6: history limit is adequate
  historyLimitTest = helpers.assertTest "tmux-history-limit"
    (tmuxTestConfig.programs.tmux.historyLimit == 50000)
    "tmux history limit should be 50000";

  # Test 7: essential plugins are included
  pluginsTest = helpers.assertTest "tmux-plugins"
    (builtins.length tmuxTestConfig.programs.tmux.plugins >= 5)
    "tmux should have at least 5 plugins configured";

  # Test 8: specific essential plugins are present
  essentialPluginsTest = helpers.assertTest "tmux-essential-plugins"
    (
      let
        pluginNames = builtins.map (p: (p.pname or p.name or "")) tmuxTestConfig.programs.tmux.plugins;
        requiredPlugins = [
          "sensible"
          "vim-tmux-navigator"
          "resurrect"
          "continuum"
        ];
      in
      builtins.all (name: builtins.any (p: lib.hasInfix name p) pluginNames) requiredPlugins
    )
    "tmux should have essential plugins (sensible, vim-tmux-navigator, resurrect, continuum)";

  # Test 9: extra config contains performance optimizations
  extraConfigTest = helpers.assertTest "tmux-extra-config"
    (builtins.stringLength tmuxTestConfig.programs.tmux.extraConfig > 1000)
    "tmux extra config should contain performance optimizations";

  # Test 10: extra config contains session persistence settings
  sessionPersistenceTest =
    let
      config = tmuxTestConfig.programs.tmux.extraConfig;
      hasSessionSettings =
        lib.hasInfix "@continuum-restore 'on'" config &&
        lib.hasInfix "@resurrect-capture-pane-contents 'on'" config;
    in
    helpers.assertTest "tmux-session-persistence"
      hasSessionSettings
      "tmux extra config should contain session persistence settings";

  # Test 11: extra config contains mouse support
  mouseSupportTest = helpers.assertTest "tmux-mouse-support"
    (lib.hasInfix "set -g mouse on" tmuxTestConfig.programs.tmux.extraConfig)
    "tmux should have mouse support enabled";

  # Test 12: extra config contains vi key bindings
  viKeyBindingsTest = helpers.assertTest "tmux-vi-keys"
    (lib.hasInfix "setw -g mode-keys vi" tmuxTestConfig.programs.tmux.extraConfig)
    "tmux should use vi key bindings in copy mode";

  # Test 13: extra config contains window navigation bindings
  windowNavigationTest =
    let
      config = tmuxTestConfig.programs.tmux.extraConfig;
      hasNavigationBindings =
        lib.hasInfix "bind -n M-h previous-window" config &&
        lib.hasInfix "bind -n M-l next-window" config;
    in
    helpers.assertTest "tmux-window-navigation"
      hasNavigationBindings
      "tmux should have Alt+h/l window navigation bindings";

  # Test 14: extra config contains true color support
  trueColorTest = helpers.assertTest "tmux-true-color"
    (lib.hasInfix "Tc" tmuxTestConfig.programs.tmux.extraConfig)
    "tmux extra config should contain true color support";

  # Test 15: extra config contains status bar settings
  statusBarTest =
    let
      config = tmuxTestConfig.programs.tmux.extraConfig;
      hasStatusBarSettings =
        lib.hasInfix "status-position bottom" config &&
        lib.hasInfix "status-bg colour234" config;
    in
    helpers.assertTest "tmux-status-bar"
      hasStatusBarSettings
      "tmux should have status bar configured";

  # Test suite aggregator
  testSuite = helpers.testSuite "tmux" [
    importTest
    enabledTest
    terminalTest
    prefixTest
    escapeTimeTest
    historyLimitTest
    pluginsTest
    essentialPluginsTest
    extraConfigTest
    sessionPersistenceTest
    mouseSupportTest
    viKeyBindingsTest
    windowNavigationTest
    trueColorTest
    statusBarTest
  ];
in
testSuite
