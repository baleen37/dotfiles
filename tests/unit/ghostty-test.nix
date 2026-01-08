# tests/unit/ghostty-test.nix
# Ghostty Terminal Emulator Configuration Tests
# Tests that Ghostty package and configuration are properly set up
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import Ghostty configuration
  ghosttyConfig = import ../../users/shared/ghostty.nix { inherit pkgs lib; };

  # Path to Ghostty config directory
  ghosttyConfigDir = ../../users/shared/.config/ghostty;

  # Helper to check if config file has expected key-value pairs
  configHasKey = key: content:
    lib.hasInfix key content && lib.hasInfix "=" content;

  # Helper to check if config file has expected key-value pair with specific value
  configKeyValue = key: value: content:
    lib.hasInfix "${key}=" content && lib.hasInfix value content;

  # Read Ghostty config file
  ghosttyConfigContent = builtins.tryEval (
    builtins.readFile (ghosttyConfigDir + "/config")
  );

in
{
  platforms = ["any"];
  value = helpers.testSuite "ghostty" [
    # Test 1: Ghostty package is in home.packages
    (helpers.assertTest "ghostty-package-in-home-packages" (
      builtins.any (p: builtins.match "ghostty.*" (builtins.toString p) != null) ghosttyConfig.home.packages
    ) "Ghostty package should be in home.packages")

    # Test 2: home.file .config/ghostty is configured
    (helpers.assertTest "ghostty-config-dir-symlinked" (
      ghosttyConfig.home.file ? ".config/ghostty"
    ) "home.file .config/ghostty should be configured")

    # Test 3: Ghostty config source directory exists
    (helpers.assertTest "ghostty-config-source-exists" (
      builtins.pathExists ghosttyConfigDir
    ) "Ghostty config source directory should exist")

    # Test 4: Ghostty config file exists and is readable
    (helpers.assertTest "ghostty-config-file-readable" (
      ghosttyConfigContent.success && builtins.stringLength ghosttyConfigContent.value > 0
    ) "Ghostty config file should exist and be readable")

    # Test 5: Config file uses recursive symlinking
    (helpers.assertTest "ghostty-config-recursive" (
      ghosttyConfig.home.file.".config/ghostty".recursive or false
    ) "Ghostty config should use recursive symlinking")

    # Test 6: Config file uses force = true
    (helpers.assertTest "ghostty-config-force" (
      ghosttyConfig.home.file.".config/ghostty".force or false
    ) "Ghostty config should use force = true")

    # Test 7: Config file has font-family setting
    (helpers.assertTest "ghostty-has-font-family" (
      let content = ghosttyConfigContent.value;
      in configHasKey "font-family" content
    ) "Ghostty config should have font-family setting")

    # Test 8: Config file has font-size setting
    (helpers.assertTest "ghostty-has-font-size" (
      let content = ghosttyConfigContent.value;
      in configHasKey "font-size" content
    ) "Ghostty config should have font-size setting")

    # Test 9: Config file has theme setting
    (helpers.assertTest "ghostty-has-theme" (
      let content = ghosttyConfigContent.value;
      in configHasKey "theme" content
    ) "Ghostty config should have theme setting")

    # Test 10: Config file has shell-integration enabled
    (helpers.assertTest "ghostty-has-shell-integration" (
      let content = ghosttyConfigContent.value;
      in configKeyValue "shell-integration" "true" content
    ) "Ghostty config should have shell-integration enabled")

    # Test 11: Config file has macos-option-as-alt setting for Claude Code
    (helpers.assertTest "ghostty-has-macos-option-as-alt" (
      let content = ghosttyConfigContent.value;
      in configHasKey "macos-option-as-alt" content
    ) "Ghostty config should have macos-option-as-alt for Claude Code compatibility")

    # Test 12: Config file has keybindings for Claude Code
    (helpers.assertTest "ghostty-has-claude-keybindings" (
      let content = ghosttyConfigContent.value;
      in configHasKey "keybind" content
    ) "Ghostty config should have keybindings for Claude Code compatibility")
  ];
}
