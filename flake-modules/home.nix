{
  inputs,
  self,
  overlays,
  ...
}:

let
  inherit (inputs) nixpkgs;
  inherit (inputs) home-manager;

  mkHomeConfig =
    userName:
    {
      system ? "aarch64-darwin",
      isDarwin ? true,
    }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        inherit inputs self isDarwin;
        currentSystemUser = userName;
      };
      modules = [
        ../users/shared/home-manager.nix
      ];
    };
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
