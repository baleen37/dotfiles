# Remote access by kind (docs/adr/0005): bootstrap enrolls Tailscale once,
# switch's root activation converges RustDesk on every run.
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
  python = "${pkgs.python3}/bin/python3";
  driver = ../../../../scripts/lib/remote_access.py;
  policy = ../../../../machines/remote-access.json;
  enroll = pkgs.writeShellApplication {
    name = "dotfiles-tailscale-enroll";
    runtimeInputs = [ pkgs.sops ];
    text = ''
      ${python} ${driver} enroll /Applications/Tailscale.app/Contents/MacOS/Tailscale \
        ${lib.escapeShellArg (lib.toLower currentSystemName)} ${../../../../secrets/remote-access.json} \
        ${lib.escapeShellArg home.sops.age.keyFile} ${policy} \
        || echo 'Tailscale enrollment skipped; follow the message above, then rerun ./bootstrap.sh.' >&2
    '';
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf home.modules.programs.tailscale.enable {
      dotfiles.setup.tailscaleEnroll = enroll;
    })
    (lib.mkIf rustdeskEnabled {
      # After Home Manager (also postActivation), which decrypts the password
      # and starts the user's RustDesk server. A desktop not logged in skips it.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "Applying RustDesk remote-access settings..." >&2
        ${python} ${driver} darwin ${lib.escapeShellArg currentSystemUser} \
          ${lib.escapeShellArg home.sops.secrets.rustdesk-password.path} ${policy} \
          || echo "warning: RustDesk settings not applied; log in to the desktop and rerun ./switch.sh" >&2
      '';
    })
  ];
}
