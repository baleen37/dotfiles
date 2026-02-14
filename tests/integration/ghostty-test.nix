# tests/integration/ghostty-test.nix
# Ghostty terminal emulator configuration tests
# Validates terminal settings, font configuration, theme, and keybindings
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  nixtest ? { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Behavioral test: try to import ghostty config
  ghosttyConfigFile = ../../users/shared/ghostty.nix;
  ghosttyConfigResult = builtins.tryEval (
    import ghosttyConfigFile {
      inherit pkgs lib;
      config = { };
    }
  );

  # Test if ghostty config can be imported and is usable
  ghosttyConfig = if ghosttyConfigResult.success then ghosttyConfigResult.value else { };
  ghosttyConfigUsable = ghosttyConfigResult.success;

  # Read the actual Ghostty config file content
  ghosttyConfigPath = ../../users/shared/.config/ghostty/config;
  ghosttyConfigContent = builtins.readFile ghosttyConfigPath;

  # Helper function to check if a config line exists
  hasConfigLine =
    pattern: builtins.match ".*${pattern}.*" ghosttyConfigContent != null;

  # Helper function to check if multiple config lines exist (all must match)
  hasAllConfigLines =
    patterns: builtins.all (p: hasConfigLine p) patterns;

  # Helper function to extract config value
  getConfigValue =
    key:
    let
      pattern = "${key}[ \t]*=[ \t]*([^ \t\n]+)";
      result = builtins.match pattern ghosttyConfigContent;
    in
    if result == null then null else builtins.head result;

  allTests = [
  # Test that ghostty.nix can be imported and is usable (behavioral)
  (helpers.assertTest "ghostty-config-usable" ghosttyConfigUsable "ghostty.nix should be importable and usable")

  # Test that home.packages exists
  (helpers.assertTest "ghostty-has-packages" (
    ghosttyConfigUsable && builtins.hasAttr "home" ghosttyConfig
    && builtins.hasAttr "packages" ghosttyConfig.home
  ) "ghostty config should have home.packages")

  # Test that home.file exists for config symlink
  (helpers.assertTest "ghostty-has-file-config" (
    ghosttyConfigUsable && builtins.hasAttr "home" ghosttyConfig
    && builtins.hasAttr "file" ghosttyConfig.home
  ) "ghostty config should have home.file for symlinking")

  # Test that the config file path is correct
  (helpers.assertTest "ghostty-config-path" (
    ghosttyConfigUsable
    && builtins.hasAttr ".config/ghostty" ghosttyConfig.home.file
  ) "ghostty should symlink .config/ghostty directory")

  # Font configuration tests
  (helpers.assertTest "ghostty-font-family-jetbrains-set"
    (hasConfigLine "font-family.*=.*JetBrains Mono")
    "Ghostty should have JetBrains Mono as primary font")

  (helpers.assertTest "ghostty-font-family-d2coding-set"
    (hasConfigLine "font-family.*=.*D2Coding")
    "Ghostty should have D2Coding as fallback font")

  (helpers.assertTest "ghostty-font-size-set" (hasConfigLine "font-size.*=.*14")
    "Ghostty should have font-size set to 14"
  )

  # Theme configuration test
  (helpers.assertTest "ghostty-theme-set" (hasConfigLine "theme.*=.*dark")
    "Ghostty should have theme set to dark"
  )

  # Window settings tests
  (helpers.assertTest "ghostty-window-padding-x" (hasConfigLine "window-padding-x.*=.*10")
    "Ghostty should have window-padding-x set to 10"
  )

  (helpers.assertTest "ghostty-window-padding-y" (hasConfigLine "window-padding-y.*=.*10")
    "Ghostty should have window-padding-y set to 10"
  )

  # Shell integration tests
  (helpers.assertTest "ghostty-shell-integration-enabled" (hasConfigLine "shell-integration.*=.*true")
    "Ghostty should have shell-integration enabled"
  )

  (helpers.assertTest "ghostty-shell-integration-features" (
    hasConfigLine "shell-integration-features.*=.*cursor,sudo,title"
  ) "Ghostty should have shell-integration-features set to cursor,sudo,title")

  # macOS-specific keybinding test (Option key as Alt)
  (helpers.assertTest "ghostty-macos-option-as-alt" (hasConfigLine "macos-option-as-alt.*=.*left")
    "Ghostty should have macos-option-as-alt set to left for Claude Code compatibility"
  )

  # Keybinding tests for Claude Code compatibility
  (helpers.assertTest "ghostty-keybind-shift-enter" (
    hasConfigLine "keybind.*shift\\+enter.*=.*text:\\\\n"
  ) "Ghostty should have shift+enter keybind for newline")

  (helpers.assertTest "ghostty-keybind-ctrl-left-bracket" (
    hasConfigLine "keybind.*ctrl\\+left_bracket.*=.*text:\\\\x1b"
  ) "Ghostty should have ctrl+left_bracket keybind for escape")

  # Test all keybindings are present
  (helpers.assertTest "ghostty-all-keybindings" (hasAllConfigLines [
    "keybind.*shift\\+enter"
    "keybind.*ctrl\\+left_bracket"
  ]) "Ghostty should have all Claude Code compatibility keybindings")

  # Test config file structure integrity
  (helpers.assertTest "ghostty-config-has-comments" (
    builtins.match ".*#.*Font Configuration.*" ghosttyConfigContent != null
  ) "Ghostty config should have section comments")

  (helpers.assertTest "ghostty-config-not-empty" (builtins.stringLength ghosttyConfigContent > 0)
    "Ghostty config should not be empty"
  )

  # Test that source directory reference is correct
  (helpers.assertTest "ghostty-source-is-directory" (
    ghosttyConfigUsable
    && ghosttyConfig.home.file.".config/ghostty".recursive or false
  ) "Ghostty file source should be a directory (recursive = true)")

  (helpers.assertTest "ghostty-force-symlink" (
    ghosttyConfigUsable
    && ghosttyConfig.home.file.".config/ghostty".force or false
  ) "Ghostty file should use force = true for symlink")
];

  testSuite = helpers.testSuite "ghostty" allTests;
in
{
  platforms = ["darwin"];
  value = testSuite;
}
