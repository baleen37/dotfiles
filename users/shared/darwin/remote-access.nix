{
  config,
  lib,
  pkgs,
  currentSystemUser,
  currentSystemName,
  ...
}:
let
  home = config.home-manager.users.${currentSystemUser};
  rustdeskEnabled = home.modules.programs.rustdesk.enable;
  tailscale = home.modules.programs.tailscale;
  driver = ../../../scripts/lib/remote_access.py;
  policy = ../../../machines/remote-access.json;
  configure = pkgs.writeShellApplication {
    name = "dotfiles-remote-configure";
    text = ''
      [ "$#" -eq 0 ] || { echo 'This command takes no arguments.' >&2; exit 2; }
      exec ${pkgs.python3}/bin/python3 ${driver} darwin \
        ${lib.escapeShellArg currentSystemUser} \
        ${lib.escapeShellArg home.sops.secrets.rustdesk-password.path} ${policy}
    '';
  };
  apply = pkgs.writeShellApplication {
    name = "dotfiles-remote-apply";
    text = ''
      [ "$#" -eq 0 ] || { echo 'This command takes no arguments.' >&2; exit 2; }
      ${lib.optionalString rustdeskEnabled ''
        /usr/bin/sudo -n -H -- /run/current-system/sw/bin/dotfiles-remote-configure
      ''}
      ${lib.optionalString tailscale.enable ''
        ${pkgs.python3}/bin/python3 ${driver} tailscale \
          /Applications/Tailscale.app/Contents/MacOS/Tailscale \
          ${lib.escapeShellArg (lib.toLower currentSystemName)} \
          ${
            lib.escapeShellArg (if tailscale.authKeyFile == null then "" else tailscale.authKeyFile)
          } ${policy}
      ''}
    '';
  };
in
{
  config = lib.mkIf (rustdeskEnabled || tailscale.enable) {
    environment.systemPackages = [ apply ] ++ lib.optional rustdeskEnabled configure;
    # The fixed, root-owned helper accepts no arguments and uses only this host's
    # declared secret path and policy. Remote triggers need no broad sudo grant.
    security.sudo.extraConfig = lib.mkIf rustdeskEnabled ''
      ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/dotfiles-remote-configure ""
    '';
  };
}
