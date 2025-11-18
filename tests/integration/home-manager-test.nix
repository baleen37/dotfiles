# tests/integration/home-manager-test.nix
{
  inputs,
  system,
  nixtest ? { },
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  hmConfig = import ../../users/shared/home-manager.nix {
    inherit pkgs lib inputs;
    currentSystemUser = "baleen"; # Test with default user
    config = {
      home = {
        homeDirectory = "/Users/baleen";
      };
    };
  };

in
helpers.testSuite "home-manager" [
  (helpers.assertTest "hm-has-imports" (hmConfig ? imports) "home-manager.nix should have imports")

  (helpers.assertTest "hm-has-home" (hmConfig ? home) "home-manager.nix should have home attribute")

  (helpers.assertTest "hm-username" (
    hmConfig.home.username == "baleen"
  ) "Username should match currentSystemUser (baleen in test)")
]
