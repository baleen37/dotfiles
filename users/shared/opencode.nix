# users/shared/opencode.nix
# OpenCode configuration managed via Home Manager

{
  pkgs,
  lib,
  ...
}:

{
  home.file.".config/opencode/opencode.json" = {
    source = ./.config/opencode/opencode.json;
    force = true;
  };
}
