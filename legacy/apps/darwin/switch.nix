{ pkgs, ... }:
{
  type = "app";
  program = "${pkgs.writeShellScript "switch" ''
    darwin-rebuild switch --flake .
  ''}";
}

