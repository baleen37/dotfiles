{
  inputs,
  self,
  pkgs,
  lib,
  ...
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  mkSystem = import ../../lib/mksystem.nix {
    inherit inputs self;
    overlays = with self.overlays; [
      additions
      modifications
      worktree
    ];
  };
  minimal =
    (mkSystem "minimal-probe" {
      system = "aarch64-darwin";
      user = "probe";
      darwin = true;
      machineModules = [ ../../machines/darwin/common.nix ];
    }).config;
  home = minimal.home-manager.users.probe;
  disabled =
    (self.darwinConfigurations.macbook-pro.extendModules {
      modules = [
        ({ lib, ... }: {
          home-manager.users.baleen.modules = {
            programs.hammerspoon.enable = lib.mkForce false;
            programs.karabiner.enable = lib.mkForce false;
            programs.rustdesk.enable = lib.mkForce false;
            programs.tailscale.enable = lib.mkForce false;
            darwin.vscode.enable = lib.mkForce false;
            darwin.keyboard-input.enable = lib.mkForce false;
          };
        })
      ];
    }).config;
  disabledHome = disabled.home-manager.users.baleen;
  withoutApps =
    (self.darwinConfigurations.macbook-pro.extendModules {
      modules = [ { homebrew.casks = lib.mkForce [ ]; } ];
    }).config;
  withoutRaycast =
    (self.darwinConfigurations.macbook-pro.extendModules {
      modules = [
        {
          homebrew.casks = lib.mkForce (
            builtins.filter (c: c.name != "raycast") self.darwinConfigurations.macbook-pro.config.homebrew.casks
          );
        }
      ];
    }).config;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "machine-selection" [
    (helpers.assertTest "minimal-host" (
      minimal.homebrew.casks == [ ]
      && minimal.homebrew.masApps == { }
      && home.programs.zsh.enable
      && home.programs.git.enable
      && home.programs.ssh.enable
      && builtins.elem pkgs.age.pname (map (p: p.pname or "") home.home.packages)
      && !home.modules.packages.dev.enable
      && !home.modules.programs.claude-code.enable
      && !(home.home.activation ? keyboardInputSource)
      && !(home.home.activation ? vscodeLaunchServices)
      && !(minimal.launchd.daemons ? lid-awake-on-ac)
    ) "new hosts must evaluate with baseline tools and no GUI apps or personal automation")
    (helpers.assertTest "disabled-features-remove-effects" (
      !(disabledHome.home.file ? ".hammerspoon")
      && !(lib.any (
        c:
        builtins.elem c.name [
          "hammerspoon"
          "karabiner-elements"
          "rustdesk"
          "tailscale-app"
          "visual-studio-code"
        ]
      ) disabled.homebrew.casks)
      && !(disabledHome.home.file ? ".config/karabiner/karabiner.json")
      && !(disabledHome.home.activation ? keyboardInputSource)
      && !(disabled.launchd.daemons ? dotfiles-rustdesk)
      && !(disabledHome.sops.secrets ? rustdesk-password)
      && !(disabledHome.launchd.agents ? tailscale-config)
      && !(lib.any (p: p.name == "dotfiles-remote-apply") disabled.environment.systemPackages)
      && !(disabledHome.home.activation ? vscodeLaunchServices)
      && !(withoutApps.system.defaults.CustomUserPreferences ? "com.raycast.macos")
      && !(lib.hasInfix "AppleSymbolicHotKeys -dict-add 64" withoutApps.home-manager.users.baleen.home.activation.keyboardInputSource.data)
    ) "disabling features must remove their files, activation and app preferences")
    (helpers.assertTest "raycast-shortcut-follows-selection" (
      let
        rules =
          c:
          (builtins.head
            (builtins.fromJSON c.home-manager.users.baleen.home.file.".config/karabiner/karabiner.json".text)
            .profiles
          ).complex_modifications.rules;
        launchesRaycast = c: lib.hasInfix "com.raycast.macos" (builtins.toJSON (rules c));
      in
      withoutRaycast.home-manager.users.baleen.modules.programs.karabiner.enable
      && lib.any (c: c.name == "karabiner-elements") withoutRaycast.homebrew.casks
      && !launchesRaycast withoutRaycast
      && launchesRaycast self.darwinConfigurations.macbook-pro.config
    ) "removing Raycast must remove its Cmd+Space mapping while preserving Karabiner")
    (helpers.assertTest "host-isolation" (
      self.darwinConfigurations.baleen-macbook.config.home-manager.users.baleen.modules.programs.hammerspoon.enable
      && self.darwinConfigurations.baleen-macbook.config.homebrew.casks != [ ]
    ) "changing one host must not alter another host")
  ];
}
