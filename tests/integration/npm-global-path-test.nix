# tests/integration/npm-global-path-test.nix
#
# Tests for npm global PATH configuration
# Validates that ~/.npm-global/bin is included in the PATH
#

{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Read the actual zsh configuration file content
  zshConfigFile = builtins.readFile ../../users/shared/zsh.nix;

  # Check if npm-global/bin is mentioned in the configuration
  npmGlobalInConfig = lib.hasInfix "$HOME/.npm-global/bin" zshConfigFile;

in
{
  # Test that npm-global/bin is configured in the PATH
  npm-global-path-configured = pkgs.runCommand "test-npm-global-path-configured" { } ''
    if [ "${toString npmGlobalInConfig}" = "true" ]; then
      echo "✅ npm-global/bin found in zsh configuration"
      echo "Configuration includes: $HOME/.npm-global/bin"
    else
      echo "❌ npm-global/bin NOT found in zsh configuration"
      exit 1
    fi
    touch $out
  '';

  # Test that npm is available
  npm-available = pkgs.runCommand "test-npm-available" { buildInputs = [ pkgs.nodejs_22 ]; } ''
    npm --version
    echo "✅ npm is available"
    touch $out
  '';

  # Test that the PATH order is correct (npm-global should come before others)
  path-order-correct = pkgs.runCommand "test-path-order-correct" { } ''
    # Extract the PATH line from zsh.nix
    path_line=$(grep 'export PATH=.*npm-global' ${../../users/shared/zsh.nix} | head -1)

    if echo "$path_line" | grep -q "\$HOME/.npm-global/bin.*\$PATH"; then
      echo "✅ npm-global/bin appears in PATH configuration"
      echo "Found: $path_line"
    else
      echo "❌ npm-global/bin PATH configuration not found or incorrect"
      echo "Looking for: export PATH containing \$HOME/.npm-global/bin before \$PATH"
      exit 1
    fi
    touch $out
  '';
}
