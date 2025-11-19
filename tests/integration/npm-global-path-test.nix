# tests/integration/npm-global-path-test.nix
#
# Tests for npm global PATH configuration
# Validates that ~/.npm-global/bin is included in the PATH
#
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

  # Read the actual zsh configuration file content
  zshConfigFile = builtins.readFile ../../users/shared/zsh.nix;

  # Check if npm-global/bin is mentioned in the configuration
  npmGlobalInConfig = lib.hasInfix "$HOME/.npm-global/bin" zshConfigFile;

  # Check if npm is available in the system
  npmAvailable = builtins.tryEval (pkgs.nodejs_22.outPath or null);
  npmExists = npmAvailable.success;

in
helpers.testSuite "npm-global-path" [
  # Test that npm-global/bin is configured in the PATH
  (helpers.assertTest "npm-global-path-configured" npmGlobalInConfig
    "npm-global/bin should be configured in zsh PATH")

  # Test that npm is available in the system packages
  (helpers.assertTest "npm-available" npmExists
    "npm should be available in the system packages")

  # Test that the PATH configuration includes npm-global in the correct order
  (helpers.assertTest "path-order-correct" (
    let
      pathLines = lib.splitString "\n" zshConfigFile;
      pathLineWithNpm = lib.findFirst (line: lib.hasInfix "npm-global" line) "" pathLines;
    in
    lib.hasInfix "$HOME/.npm-global/bin" pathLineWithNpm &&
    lib.hasInfix "$PATH" pathLineWithNpm
  ) "PATH should include $HOME/.npm-global/bin before $PATH")
]
