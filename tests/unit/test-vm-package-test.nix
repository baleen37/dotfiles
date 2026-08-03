{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  flakeSource = builtins.readFile ../../flake.nix;
  devShellSource = builtins.readFile ../../flake-modules/dev-shells.nix;
  packagesSource = builtins.readFile ../../flake-modules/packages.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "test-vm-package" [
    (helpers.assertTest "nixos-generators-input-removed" (
      !(lib.hasInfix "nixos-generators" flakeSource)
    ) "flake.nix should not declare the deprecated nixos-generators input")

    (helpers.assertTest "native-nixos-vm-build" (lib.hasInfix "config.system.build.vm" packagesSource)
      "test-vm should use the native NixOS config.system.build.vm output"
    )

    (helpers.assertTest "duplicate-formatters-removed" (
      !(lib.hasInfix "nixfmt-rfc-style" devShellSource) && !(lib.hasInfix "alejandra" devShellSource)
    ) "the dev shell should rely on nix fmt instead of bundling duplicate formatters")
  ];
}
