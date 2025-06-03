{ pkgs, ... }:
{
  type = "app";
  program = "${pkgs.writeShellScript "switch" ''
    nixos-rebuild switch --flake .
  ''}";
}
