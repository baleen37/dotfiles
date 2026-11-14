# tests/unit/mksystem-test.nix
#
# Guards the parts of lib/mksystem.nix that a reader cannot verify from the
# source alone: what the module list actually resolves to after the NixOS /
# nix-darwin module system has merged everything.
#
# A test-only NixOS fixture exercises the shared system factory even when no
# NixOS machines are registered for deployment.
{
  inputs,
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  cacheConfig = import ../../lib/cache-config.nix;
  nixos = (import ../lib/nixos-fixture.nix { inherit inputs self; }).config;
  trustedUsers = nixos.nix.settings.trusted-users;
  trustedSubs = nixos.nix.settings.trusted-substituters;

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
      lib.elem "root" trustedUsers && lib.elem "testuser" trustedUsers
    ) "NixOS nix.settings.trusted-users must include root and the host user so the cache is usable")

    # A trusted user is root-equivalent; a group entry hands that to every member.
    (helpers.assertTest "nixos-trusts-no-groups" (
      !lib.any (lib.hasPrefix "@") trustedUsers
    ) "NixOS nix.settings.trusted-users must not trust whole groups; got ${toString trustedUsers}")

    # Without this a non-root `nix build` silently ignores the caches and
    # rebuilds the world.
    (helpers.assertTest "cache-substituters-are-trusted" (lib.all (url: lib.elem url trustedSubs)
      cacheConfig.substituters
    ) "every substituter from lib/cache-config.nix must also be a trusted-substituter")
  ];
}
