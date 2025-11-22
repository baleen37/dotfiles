# tests/wsl/default.nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  # Import WSL configuration tests
  wslConfigTest = import ./wsl-configuration.nix {
    inherit inputs system pkgs lib;
  };
in
{
  # WSL tests should only run on Linux platforms
  wsl-configuration =
    if lib.strings.hasSuffix "linux" system then
      wslConfigTest
    else
      pkgs.runCommand "wsl-test-skipped-${system}" { } ''
        echo "✅ WSL configuration test skipped on ${system} (Linux-only test)"
        touch $out
      '';
}