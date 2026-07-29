# tests/integration/machine-builds-test.nix
#
# Every host declared in flake-modules/hosts.nix must evaluate. That is most of
# the value here: reaching into `.config` forces the module tree, so a broken
# machine file, a bad option name, or a merge conflict between modules fails
# this check instead of failing someone's `make switch`.
#
# Beyond evaluating, only settings that are easy to lose silently are asserted:
# stateVersion (activation fails without it) and hostName on NixOS.
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  darwinHosts = inputs.self.darwinConfigurations;
  nixosHosts = inputs.self.nixosConfigurations;

  darwinNames = builtins.attrNames darwinHosts;
  nixosNames = builtins.attrNames nixosHosts;

  expectedDarwin = [
    "baleen-macbook"
    "kakaostyle-jito"
    "macbook-pro"
  ];
  expectedNixos = [
    "vm-aarch64-utm"
    "vm-x86_64-utm"
  ];
  hostsAreDeclared = darwinNames == expectedDarwin && nixosNames == expectedNixos;

  allHosts = hosts: predicate: lib.all (host: predicate host.config) (lib.attrValues hosts);

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "machine-builds" [
    # Guards against a host silently vanishing from the flake, e.g. a typo in a
    # hosts.nix `class` value dropping it from both mapAttrs calls.
    (helpers.assertTest "every-host-is-declared" hostsAreDeclared
      "flake-modules/hosts.nix should expose exactly the known Darwin and NixOS hosts"
    )

    (helpers.assertTest "darwin-hosts-set-state-version" (allHosts darwinHosts (
      c: (c.system.stateVersion or null) != null
    )) "every Darwin host needs system.stateVersion; activation fails without it")

    (helpers.assertTest "darwin-hosts-install-system-packages" (allHosts darwinHosts (
      c: builtins.length c.environment.systemPackages > 0
    )) "every Darwin host should end up with system packages")

    (helpers.assertTest "darwin-hosts-load-home-manager" (allHosts darwinHosts (
      c: builtins.attrNames c.home-manager.users != [ ]
    )) "every Darwin host should configure at least one Home Manager user")

    (helpers.assertTest "nixos-hosts-set-state-version" (allHosts nixosHosts (
      c: (c.system.stateVersion or null) != null
    )) "every NixOS host needs system.stateVersion; activation fails without it")

    (helpers.assertTest "nixos-hosts-set-hostname" (allHosts nixosHosts (
      c: (c.networking.hostName or "") != ""
    )) "every NixOS host should set networking.hostName")
  ];
}
