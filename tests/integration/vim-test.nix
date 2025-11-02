# tests/unit/vim-test.nix
# Vim configuration extraction tests
# Tests that vim config is properly extracted from modules/ to users/shared/vim.nix
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import nixtest framework assertions
  inherit (nixtest.assertions) assertTrue assertFalse;

  # Behavioral test: try to import and use vim config
  vimConfigFile = ../../users/shared/vim.nix;
  vimConfigResult = builtins.tryEval (
    import vimConfigFile {
      inherit pkgs lib;
      config = { };
    }
  );

  # Test if vim config can be imported and is usable
  vimConfig = if vimConfigResult.success then vimConfigResult.value else { };
  vimConfigUsable = vimConfigResult.success;

  # Test if vim is enabled (behavioral)
  vimEnabled = vimConfigUsable && vimConfig.programs.vim.enable;

  # Test if vim plugins exist (behavioral)
  hasPlugins = vimConfigUsable && builtins.hasAttr "plugins" vimConfig.programs.vim;

  # Test if vim settings exist (behavioral)
  hasSettings = vimConfigUsable && builtins.hasAttr "settings" vimConfig.programs.vim;

  # Test if vim has extraConfig (for custom key bindings) (behavioral)
  hasExtraConfig = vimConfigUsable && builtins.hasAttr "extraConfig" vimConfig.programs.vim;

  # Test if airline plugin is present (behavioral)
  hasAirlinePlugin =
    vimConfigUsable
    && builtins.any (plugin: plugin.pname or null == "vim-airline") vimConfig.programs.vim.plugins;

  # Test if tmux-navigator plugin is present (behavioral)
  hasTmuxNavigator =
    vimConfigUsable
    && builtins.any (
      plugin: plugin.pname or null == "vim-tmux-navigator"
    ) vimConfig.programs.vim.plugins;

  # Test suite using NixTest framework
  testSuite = {
    name = "vim-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that vim.nix can be imported and is usable (behavioral)
      vim-config-usable = nixtest.test "vim-config-usable" (assertTrue vimConfigUsable);

      # Test that vim is enabled
      vim-enabled = nixtest.test "vim-enabled" (assertTrue vimEnabled);

      # Test that vim plugins exist
      vim-plugins-exist = nixtest.test "vim-plugins-exist" (assertTrue hasPlugins);

      # Test that vim settings exist
      vim-settings-exist = nixtest.test "vim-settings-exist" (assertTrue hasSettings);

      # Test that vim has extraConfig
      vim-extra-config = nixtest.test "vim-extra-config" (assertTrue hasExtraConfig);

      # Test that airline plugin is present
      vim-airline-plugin = nixtest.test "vim-airline-plugin" (assertTrue hasAirlinePlugin);

      # Test that tmux-navigator plugin is present
      vim-tmux-navigator = nixtest.test "vim-tmux-navigator" (assertTrue hasTmuxNavigator);
    };
  };

in
# Convert test suite to executable derivation
pkgs.runCommand "vim-test-results" { } ''
  echo "Running Vim configuration tests..."

  # Test that vim.nix can be imported and is usable
  echo "Test 1: vim.nix file is importable..."
  ${
    if vimConfigUsable then
      ''echo "✅ PASS: vim.nix is importable and usable"''
    else
      ''echo "❌ FAIL: vim.nix is not importable or not usable"; exit 1''
  }

  # Test that vim is enabled
  echo "Test 2: vim is enabled..."
  ${
    if vimEnabled then
      ''echo "✅ PASS: vim is enabled"''
    else
      ''echo "❌ FAIL: vim is not enabled"; exit 1''
  }

  # Test that vim plugins exist
  echo "Test 3: vim plugins exist..."
  ${
    if hasPlugins then
      ''echo "✅ PASS: vim plugins exist"''
    else
      ''echo "❌ FAIL: vim plugins missing"; exit 1''
  }

  # Test that vim settings exist
  echo "Test 4: vim settings exist..."
  ${
    if hasSettings then
      ''echo "✅ PASS: vim settings exist"''
    else
      ''echo "❌ FAIL: vim settings missing"; exit 1''
  }

  # Test that vim has extraConfig
  echo "Test 5: vim has extraConfig..."
  ${
    if hasExtraConfig then
      ''echo "✅ PASS: vim has extraConfig"''
    else
      ''echo "❌ FAIL: vim extraConfig missing"; exit 1''
  }

  # Test that airline plugin is present
  echo "Test 6: vim airline plugin present..."
  ${
    if hasAirlinePlugin then
      ''echo "✅ PASS: vim airline plugin present"''
    else
      ''echo "❌ FAIL: vim airline plugin missing"; exit 1''
  }

  # Test that tmux-navigator plugin is present
  echo "Test 7: vim tmux-navigator plugin present..."
  ${
    if hasTmuxNavigator then
      ''echo "✅ PASS: vim tmux-navigator plugin present"''
    else
      ''echo "❌ FAIL: vim tmux-navigator plugin missing"; exit 1''
  }

  echo "✅ All Vim configuration tests passed!"
  echo "Vim configuration verified - all expected settings are present"
  touch $out
''
