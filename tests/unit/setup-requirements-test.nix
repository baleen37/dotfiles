{
  inputs,
  self,
  pkgs,
  lib,
  ...
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  mkSystem = import ../../lib/mksystem.nix { inherit inputs self; };
  minimal = mkSystem "requirements-probe" {
    system = "aarch64-darwin";
    user = "probe";
    darwin = true;
    machineModules = [ ../../machines/darwin/common.nix ];
  };
  requirements = modules: (minimal.extendModules { inherit modules; }).config.dotfiles.setup;
  empty = requirements [ ];
  brew = requirements [ { homebrew.enable = true; } ];
  cask = requirements [
    {
      homebrew.enable = true;
      homebrew.casks = [ "rustdesk" ];
    }
  ];
  mas = requirements [
    {
      homebrew.enable = true;
      homebrew.masApps.Probe = 123456;
    }
  ];
  password = requirements [ { programs._1password-gui.enable = true; } ];
  nixos = (import ../lib/nixos-fixture.nix { inherit inputs self; }).config.dotfiles.setup;
  overridden =
    builtins.tryEval
      (requirements [ { dotfiles.setup.appManagementRequired = false; } ]).appManagementRequired;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "setup-requirements" [
    (helpers.assertTest "minimal-host" (
      !empty.homebrewRequired && !empty.appManagementRequired
    ) "minimal hosts must require neither Homebrew nor App Management")
    (helpers.assertTest "brew-without-apps" (
      brew.homebrewRequired && !brew.appManagementRequired
    ) "Homebrew alone must not require App Management consent")
    (helpers.assertTest "gui-apps" (
      cask.homebrewRequired
      && cask.appManagementRequired
      && mas.homebrewRequired
      && mas.appManagementRequired
    ) "both casks and Mac App Store declarations must require consent")
    (helpers.assertTest "password-without-brew" (
      !password.homebrewRequired && password.appManagementRequired
    ) "Nix-managed 1Password must require consent without Homebrew")
    (helpers.assertTest "nixos" (
      !nixos.homebrewRequired && !nixos.appManagementRequired
    ) "NixOS must not evaluate Darwin-only requirements")
    (helpers.assertTest "computed-policy-is-read-only" (
      !overridden.success
    ) "host modules must not override computed consent requirements")
  ];
}
