# tests/integration/vim-test.nix
# Vim configuration extraction tests
# Tests that vim config is properly extracted from modules/ to users/shared/vim.nix
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

in
helpers.testSuite "vim" [
  # Test that vim.nix can be imported and is usable (behavioral)
  (helpers.assertTest "vim-config-usable" vimConfigUsable "vim.nix should be importable and usable")

  # Test that vim is enabled
  (helpers.assertTest "vim-enabled" vimEnabled "vim should be enabled")

  # Test that vim plugins exist
  (helpers.assertTest "vim-plugins-exist" hasPlugins "vim plugins should exist")

  # Test that vim settings exist
  (helpers.assertTest "vim-settings-exist" hasSettings "vim settings should exist")

  # Test that vim has extraConfig
  (helpers.assertTest "vim-extra-config" hasExtraConfig
    "vim should have extraConfig for custom key bindings"
  )

  # Test that airline plugin is present
  (helpers.assertTest "vim-airline-plugin" hasAirlinePlugin "vim airline plugin should be present")

  # Test that tmux-navigator plugin is present
  (helpers.assertTest "vim-tmux-navigator" hasTmuxNavigator
    "vim tmux-navigator plugin should be present"
  )
]
