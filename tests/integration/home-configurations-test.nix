# tests/integration/home-configurations-test.nix
#
# `make switch-home` activates flake.homeConfigurations.<user> directly, without
# going through a darwinConfiguration. That path has no other coverage, so this
# check evaluates each standalone Home Manager configuration.
#
# Module imports and option values are covered by home-manager-test.nix against
# the raw module; here the point is that the evaluated configuration exists and
# produces an activation package for every user we ship.
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  homeConfigs = inputs.self.homeConfigurations;
in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "home-configurations" [
    (helpers.assertTest "expected-users-are-exposed" (
      builtins.attrNames homeConfigs == [
        "baleen"
        "baleen-linux"
        "jito.hello"
        "testuser"
      ]
    ) "flake-modules/home.nix should expose a homeConfiguration for every supported user")

    # Forcing activationPackage is what actually evaluates the module tree.
    (helpers.assertTest "every-user-has-an-activation-package" (
      lib.all (cfg: cfg ? activationPackage) (lib.attrValues homeConfigs)
    ) "each homeConfiguration must evaluate to an activation package for `make switch-home`")
  ];
}
