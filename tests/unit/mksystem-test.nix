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

  # Read defensively: if a field were renamed upstream, a throw here would turn a
  # readable assertion failure into an evaluation error for the whole check.
  gc = nixos.nix.gc or { };
  gcReport = lib.generators.toPretty { multiline = false; } {
    automatic = gc.automatic or "<unset>";
    dates = gc.dates or "<unset>";
    options = gc.options or "<unset>";
  };
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "mksystem" [
    # Home Manager takes over files that may already exist on a fresh machine;
    # without a backup extension the first switch aborts instead of moving them.
    (helpers.assertTest "home-manager-backs-up-collisions" (
      nixos.home-manager.backupFileExtension == "backup"
    ) "home-manager needs a backup extension or the first switch aborts on existing files")

    # Determinate manages Nix on Darwin, so mksystem must hand GC to it there
    # and configure nix.gc itself only on NixOS. Split per field, and report the
    # value that was actually merged — the schedule is a string the NixOS module
    # is free to reshape, so "it disagrees" is not a useful failure message.
    (helpers.assertTest "nixos-gc-is-automatic" (gc.automatic or false
    ) "NixOS hosts should garbage collect automatically; got ${gcReport}")

    (helpers.assertTest "nixos-gc-retains-7-days" (lib.hasInfix "--delete-older-than 7d" (
      gc.options or ""
    )) "NixOS GC should keep a 7 day retention window; got ${gcReport}")

    (helpers.assertTest "nixos-trusts-the-host-user" (
      lib.elem "root" nixos.nix.settings.trusted-users
      && lib.elem "@wheel" nixos.nix.settings.trusted-users
    ) "NixOS nix.settings.trusted-users must include root and @wheel so the cache is usable")

    # Without this a non-root `nix build` silently ignores the caches and
    # rebuilds the world.
    (helpers.assertTest "cache-substituters-are-trusted" (lib.all
      (url: lib.elem url nixos.nix.settings.trusted-substituters)
      cacheConfig.substituters
    ) "every substituter from lib/cache-config.nix must also be a trusted-substituter")
  ];
}
