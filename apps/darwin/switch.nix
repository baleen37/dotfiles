{ pkgs, ... }:
pkgs.mkApp {
  name = "switch";
  drv = pkgs.writeShellScriptBin "switch" ''
    darwin-rebuild switch --flake .
  '';
}

