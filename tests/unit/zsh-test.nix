# tests/unit/zsh-test.nix
# Zsh configuration extraction tests
# Tests that zsh config is properly extracted from modules/ to users/baleen/zsh.nix
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

  # Try to import zsh config (this will fail initially)
  zshConfigFile = ../../users/baleen/zsh.nix;
  zshConfigExists = builtins.pathExists zshConfigFile;

  # Test if zsh config can be imported (will fail initially)
  zshConfig =
    if zshConfigExists then
      (import zshConfigFile {
        inherit pkgs lib;
        config = { };
      })
    else
      { };

  # Test if zsh is enabled
  zshEnabled = zshConfigExists && zshConfig.programs.zsh.enable;

  # Test if zsh has shell aliases
  hasAliases = zshConfigExists && builtins.hasAttr "shellAliases" zshConfig.programs.zsh;

  # Test if zsh has plugins
  hasPlugins = zshConfigExists && builtins.hasAttr "plugins" zshConfig.programs.zsh;

  # Test if zsh has init content
  hasInitContent = zshConfigExists && builtins.hasAttr "initContent" zshConfig.programs.zsh;

  # Test if powerlevel10k plugin is present
  hasPowerlevel10k =
    zshConfigExists
    && builtins.any (plugin: plugin.name or null == "powerlevel10k") zshConfig.programs.zsh.plugins;

  # Test if cc alias exists
  hasCCAlias = zshConfigExists && zshConfig.programs.zsh.shellAliases ? cc;

  # Test if ccw alias exists
  hasCCWAlias = zshConfigExists && zshConfig.programs.zsh.shellAliases ? ccw;

  # Test suite using NixTest framework
  testSuite = {
    name = "zsh-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that zsh.nix file exists (will fail initially)
      zsh-config-exists = nixtest.test "zsh-config-exists" (assertTrue zshConfigExists);

      # Test that zsh is enabled
      zsh-enabled = nixtest.test "zsh-enabled" (assertTrue zshEnabled);

      # Test that zsh has shell aliases
      zsh-aliases-exist = nixtest.test "zsh-aliases-exist" (assertTrue hasAliases);

      # Test that zsh has plugins
      zsh-plugins-exist = nixtest.test "zsh-plugins-exist" (assertTrue hasPlugins);

      # Test that zsh has init content
      zsh-init-content = nixtest.test "zsh-init-content" (assertTrue hasInitContent);

      # Test that powerlevel10k plugin is present
      zsh-powerlevel10k = nixtest.test "zsh-powerlevel10k" (assertTrue hasPowerlevel10k);

      # Test that cc alias exists
      zsh-cc-alias = nixtest.test "zsh-cc-alias" (assertTrue hasCCAlias);

      # Test that ccw alias exists
      zsh-ccw-alias = nixtest.test "zsh-ccw-alias" (assertTrue hasCCWAlias);
    };
  };

in
testSuite
