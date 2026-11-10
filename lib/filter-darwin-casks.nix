{ lib, modules }:
let
  enabled = {
    hammerspoon = modules.programs.hammerspoon.enable;
    karabiner-elements = modules.programs.karabiner.enable;
    tailscale-app = modules.programs.tailscale.enable;
    rustdesk = modules.programs.rustdesk.enable;
    herdr-app = modules.programs.herdr.enable;
    visual-studio-code = modules.darwin.vscode.enable;
  };
in
lib.filter (name: enabled.${name} or true)
