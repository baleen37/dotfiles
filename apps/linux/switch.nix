{ pkgs, ... }:
pkgs.mkApp {
  name = "switch";
  drv = pkgs.writeShellScriptBin "switch" ''
    nixos-rebuild switch --flake .
  '';
}
