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
          {
            modules.programs.baleen-toolkit.enable = true;
            modules.programs.claude-code.enable = true;
            modules.programs.codex.enable = true;
            modules.programs.docker.enable = true;
            modules.programs.git.enable = true;
            modules.programs.herdr.enable = true;
            modules.programs.neovim.enable = true;
            modules.programs.powerlevel10k.enable = true;
            modules.programs.ssh.enable = true;
            modules.programs.terraform.enable = true;
            modules.programs.tmux.enable = true;
            modules.programs.vim.enable = true;
            modules.programs.yarn.enable = true;
            modules.programs.zsh.enable = true;
            modules.packages.ai.enable = true;
            modules.packages.cloud.enable = true;
            modules.packages.core.enable = true;
            modules.packages.databases.enable = true;
            modules.packages.dev.enable = true;
            modules.packages.fonts.enable = true;
            modules.packages.media.enable = true;
            modules.packages.nix-tools.enable = true;
            modules.packages.security.enable = true;
            modules.packages.ssh.enable = true;
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
