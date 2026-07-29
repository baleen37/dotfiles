# tests/unit/mksystem-test.nix
#
# Guards the parts of lib/mksystem.nix that a reader cannot verify from the
# source alone: what the module list actually resolves to after the NixOS /
# nix-darwin module system has merged everything.
#
# Assertions go through self.nixosConfigurations / self.darwinConfigurations
# rather than calling mkSystem with synthetic host names, so what is checked is
# the configuration a machine really gets.
{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  cacheConfig = import ../../lib/cache-config.nix;
  nixos = self.nixosConfigurations.vm-x86_64-utm.config;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "mksystem" [
    # Home Manager takes over files that may already exist on a fresh machine;
    # without a backup extension the first switch aborts instead of moving them.
    (helpers.assertTest "home-manager-backs-up-collisions" (
      nixos.home-manager.backupFileExtension == "backup"
    ) "home-manager.backupFileExtension must be set so a first switch cannot abort on existing dotfiles")

    # Determinate manages Nix on Darwin, so mksystem must hand GC to it there
    # and configure nix.gc itself only on NixOS.
    (helpers.assertTest "nixos-gc-is-scheduled" (
      nixos.nix.gc.automatic
      && nixos.nix.gc.dates == "daily"
      && nixos.nix.gc.options == "--delete-older-than 7d"
    ) "NixOS hosts should garbage collect daily with a 7 day retention window")

    (helpers.assertTest "nixos-trusts-the-host-user" (
      lib.elem "root" nixos.nix.settings.trusted-users
      && lib.elem "@wheel" nixos.nix.settings.trusted-users
    ) "NixOS nix.settings.trusted-users must include root and @wheel so the cache is usable")

    # Without this a non-root `nix build` silently ignores the caches and
    # rebuilds the world.
    (helpers.assertTest "cache-substituters-are-trusted" (
      lib.all (url: lib.elem url nixos.nix.settings.trusted-substituters) cacheConfig.substituters
    ) "every substituter from lib/cache-config.nix must also be a trusted-substituter")
  ];
}
