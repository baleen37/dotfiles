# tests/integration/home-manager-test.nix
{ inputs, system }:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  hmConfig = import ../../users/baleen/home-manager.nix {
    inherit pkgs lib inputs;
    config = { home = { homeDirectory = "/Users/baleen"; }; };
  };

in helpers.testSuite "home-manager" [
  (helpers.assertTest "hm-has-imports"
    (hmConfig ? imports)
    "home-manager.nix should have imports")

  (helpers.assertTest "hm-has-home"
    (hmConfig ? home)
    "home-manager.nix should have home attribute")

  (helpers.assertTest "hm-username"
    (hmConfig.home.username == "baleen")
    "Username should be baleen")
]