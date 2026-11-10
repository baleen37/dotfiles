{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  flakeSource = builtins.readFile ../../flake.nix;
  devShellSource = builtins.readFile ../../flake-modules/dev-shells.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "development-tooling" [
    (helpers.assertTest "nixos-generators-input-removed" (
      !(lib.hasInfix "nixos-generators" flakeSource)
    ) "flake.nix should not declare the deprecated nixos-generators input")

    (helpers.assertTest "duplicate-formatters-removed" (
      !(lib.hasInfix "nixfmt-rfc-style" devShellSource) && !(lib.hasInfix "alejandra" devShellSource)
    ) "the dev shell should rely on nix fmt instead of bundling duplicate formatters")
  ];
}
