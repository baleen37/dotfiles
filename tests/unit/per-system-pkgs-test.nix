{
  inputs,
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  homeConfiguration = self.homeConfigurations.baleen;
  homeModule = builtins.readFile ../../flake-modules/home.nix;
in
helpers.testSuite "per-system-pkgs" [
  (helpers.assertTest "baleen-home-configuration-evaluates" (
    homeConfiguration.activationPackage.drvPath != ""
  ) "homeConfigurations.baleen should evaluate an activation package derivation")

  (helpers.assertTest "home-configuration-uses-per-system-pkgs" (
    lib.hasInfix "withSystem system (" homeModule
    && lib.hasInfix "{ pkgs, ... }:" homeModule
    && !(lib.hasInfix "import nixpkgs" homeModule)
  ) "home.nix should receive pkgs from withSystem without importing nixpkgs")
]
