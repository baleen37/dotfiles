# WSL Configuration Test
# This test should initially fail because machines/wsl.nix doesn't exist
{ pkgs, lib, ... }:

{
  # Test basic WSL configuration structure
  test.wsl-structure = {
    expr = (import ../machines/wsl.nix {});
    expected = { config, pkgs, ... }: { /* expected structure */ };
  };
}