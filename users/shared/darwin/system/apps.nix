{
  config,
  lib,
  currentSystemUser,
  ...
}:
let
  modules = config.home-manager.users.${currentSystemUser}.modules;
  apps = {
    hammerspoon = modules.programs.hammerspoon.enable;
    karabiner-elements = modules.programs.karabiner.enable;
    tailscale-app = modules.programs.tailscale.enable;
    rustdesk = modules.programs.rustdesk.enable;
    herdr-app = modules.programs.herdr.enable;
    visual-studio-code = modules.darwin.vscode.enable;
  };
in
{
  homebrew.casks = builtins.attrNames (lib.filterAttrs (_: enabled: enabled) apps);
}
