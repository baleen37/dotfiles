{
  inputs,
  self,
  withSystem,
  ...
}:

let
  inherit (inputs) home-manager;

  mkHomeConfig =
    userName:
    {
      system ? "aarch64-darwin",
      isDarwin ? true,
    }:
    withSystem system (
      { pkgs, ... }:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs self isDarwin;
          currentSystemUser = userName;
        };
        modules = [
          ../users/shared/home-manager.nix
        ];
      }
    );
in
{
  flake.homeConfigurations = {
    baleen = mkHomeConfig "baleen" { };
    "jito.hello" = mkHomeConfig "jito.hello" { };
    testuser = mkHomeConfig "testuser" { };
    "baleen-linux" = mkHomeConfig "baleen" {
      system = "x86_64-linux";
      isDarwin = false;
    };
  };
}
