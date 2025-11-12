# Vim Configuration Tests
#
# Vim 편집기 설정 테스트
# - 기본 설정 검증
# - 플러그인 설치 확인
# - 설정 파일 내용 검증
# - 핵심 기능 설정 확인
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

  # Import vim module for testing
  vimModule = import ../../users/shared/vim.nix;

  # Create test configuration
  testConfig = {
    home = {
      username = helpers.testConfig.username;
      homeDirectory = helpers.getTestUserHome;
    };
  };

  # Create test derivation with vim configuration
  vimTestConfig = vimModule {
    inherit pkgs lib;
    config = testConfig;
  };

in
{
  # Test 1: vim module imports successfully
  importTest = helpers.assertTest "vim-import"
    (helpers.canImport ../../users/shared/vim.nix)
    "vim module should import without errors";

  # Test 2: vim is enabled
  enabledTest = helpers.assertTest "vim-enabled"
    (vimTestConfig.programs.vim.enable == true)
    "vim should be enabled";

  # Test 3: vim has essential plugins
  pluginsTest = helpers.assertTest "vim-plugins"
    (builtins.length vimTestConfig.programs.vim.plugins >= 3)
    "vim should have at least 3 plugins configured";

  # Test 4: vim has specific essential plugins
  essentialPluginsTest =
    let
      pluginNames = builtins.map (p: (p.pname or p.name or "")) vimTestConfig.programs.vim.plugins;
      requiredPlugins = [
        "vim-airline"
        "vim-airline-themes"
        "vim-tmux-navigator"
      ];
    in
    helpers.assertTest "vim-essential-plugins"
      (builtins.all (name: builtins.any (p: lib.hasInfix name p) pluginNames) requiredPlugins)
      "vim should have essential plugins (vim-airline, vim-airline-themes, vim-tmux-navigator)";

  # Test 5: vim has ignorecase setting
  ignorecaseTest = helpers.assertTest "vim-ignorecase"
    (vimTestConfig.programs.vim.settings.ignorecase == true)
    "vim should have ignorecase setting enabled";

  # Test 6: vim extra config exists and has content
  extraConfigTest = helpers.assertTest "vim-extra-config"
    (
      builtins.stringLength vimTestConfig.programs.vim.extraConfig > 1000
    )
    "vim should have substantial extra configuration";

  # Test 7: vim extra config contains basic settings
  basicSettingsTest =
    let
      config = vimTestConfig.programs.vim.extraConfig;
    in
    helpers.assertTest "vim-basic-settings"
      (lib.hasInfix "set number" config && lib.hasInfix "set history=1000" config)
      "vim extra config should contain basic settings like line numbers and history";

  # Test 8: vim extra config contains whitespace settings
  whitespaceTest =
    let
      config = vimTestConfig.programs.vim.extraConfig;
    in
    helpers.assertTest "vim-whitespace-settings"
      (
        lib.hasInfix "set tabstop=8" config &&
        lib.hasInfix "set shiftwidth=2" config &&
        lib.hasInfix "set expandtab" config
      )
    "vim should have proper whitespace settings configured";

  # Test 9: vim extra config contains search settings
  searchSettingsTest = helpers.assertTest "vim-search-settings"
    (lib.hasInfix "set incsearch" vimTestConfig.programs.vim.extraConfig)
    "vim should have incremental search enabled";

  # Test 10: vim extra config contains backup settings
  backupSettingsTest =
    let
      config = vimTestConfig.programs.vim.extraConfig;
    in
    helpers.assertTest "vim-backup-settings"
      (lib.hasInfix "set nobackup" config && lib.hasInfix "set noswapfile" config)
    "vim should have backup and swap files disabled";

  # Test 11: vim extra config contains status line settings
  statusLineTest = helpers.assertTest "vim-status-line"
    (lib.hasInfix "airline_theme" vimTestConfig.programs.vim.extraConfig)
    "vim should have airline theme configured";

  # Test 12: vim extra config contains key mappings
  keyMappingsTest =
    let
      config = vimTestConfig.programs.vim.extraConfig;
    in
    helpers.assertTest "vim-key-mappings"
      (lib.hasInfix "mapleader" config && lib.hasInfix "bnext" config)
    "vim should have custom key mappings configured";

  # Test 13: vim extra config contains relative line numbers
  relativeLineNumbersTest = helpers.assertTest "vim-relative-numbers"
    (lib.hasInfix "set relativenumber" vimTestConfig.programs.vim.extraConfig)
    "vim should have relative line numbers enabled";

  # Test 14: vim extra config contains clipboard settings
  clipboardTest = helpers.assertTest "vim-clipboard"
    (lib.hasInfix "set clipboard=autoselect" vimTestConfig.programs.vim.extraConfig)
    "vim should have clipboard integration configured";

  # Test 15: vim extra config contains file type settings
  fileTypeTest =
    let
      config = vimTestConfig.programs.vim.extraConfig;
    in
    helpers.assertTest "vim-file-type"
      (lib.hasInfix "syntax on" config && lib.hasInfix "filetype on" config)
    "vim should have syntax highlighting and filetype detection enabled";

  # Test 16: vim extra config contains tmux navigation
  tmuxNavigationTest = helpers.assertTest "vim-tmux-navigation"
    (
      let
        pluginNames = builtins.map (p: (p.pname or p.name or "")) vimTestConfig.programs.vim.plugins;
      in
      builtins.any (name: lib.hasInfix "vim-tmux-navigator" name) pluginNames
    )
    "vim should have tmux navigator plugin for seamless navigation";
}
