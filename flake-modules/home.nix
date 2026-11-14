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
    }:
    withSystem system (
      { pkgs, ... }:
      let
        isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs self;
          inherit isDarwin;
          currentSystemUser = userName;
        };
        modules = [
          ../users/shared/home-manager.nix
          ../users/shared/development.nix
          {
            modules.programs.hammerspoon.enable = isDarwin;
            modules.programs.karabiner.enable = isDarwin;
            modules.programs.rustdesk.enable = isDarwin;
            modules.darwin.keyboard-input.enable = isDarwin;
            modules.darwin.keyboard-input.reserveCommandSpace = isDarwin;
            modules.darwin.vscode.enable = isDarwin;
          }
        ];
      }
    );
in
{
  flake.homeConfigurations = {
    baleen = mkHomeConfig "baleen" { };
    "jito.hello" = mkHomeConfig "jito.hello" { };
    testuser = mkHomeConfig "testuser" { };
    "baleen-linux" = mkHomeConfig "baleen" { system = "x86_64-linux"; };
  };
}
