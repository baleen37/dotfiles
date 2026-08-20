# On Linux, VS Code stays a nix package.
#
# The Darwin half of this invariant lives in vscode-source-test.nix, which can
# only run on Darwin because it reads `self.darwinConfigurations`. Platform
# gating keys off the system the check runs on, so the Linux half has to be its
# own file: `users/shared/packages/dev.nix` branches on
# `stdenv.hostPlatform.isDarwin`, and dropping `vscode` from the non-Darwin
# branch would otherwise be caught by nothing.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  homeOptionsModule = {
    options.home.packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };

  devPackages =
    (lib.evalModules {
      modules = [
        homeOptionsModule
        (import ../../users/shared/packages/dev.nix)
        { _module.args = { inherit pkgs; }; }
        { config.modules.packages.dev.enable = true; }
      ];
    }).config.home.packages;

  devPackageNames = map (pkg: pkg.pname or pkg.name or "") devPackages;
in
{
  platforms = [ "linux" ];
  value = helpers.assertTest "vscode from nix on linux" (builtins.any (name: name == "vscode")
    devPackageNames
  ) "VS Code should stay in home.packages on Linux: only Darwin moves it to Homebrew";
}
