{
  pkgs,
  lib,
  self,
  ...
}:
assert lib.all
  (
    host:
    let
      c = self.darwinConfigurations.${host}.config;
      home = c.home-manager.users.${c.system.primaryUser};
    in
    home.modules.programs.tailscale.enable
    && home.sops.secrets.rustdesk-password.format == "json"
    # Enrollment reads the shared sops file in bootstrap; no decrypted copy in HM.
    && !(home.sops.secrets ? tailscale-auth-key)
    && c.dotfiles.setup.tailscaleEnroll.name == "dotfiles-tailscale-enroll"
    && builtins.elem "--server" home.launchd.agents.rustdesk.config.ProgramArguments
    && !(c.launchd.daemons ? dotfiles-rustdesk)
    && !(home.launchd.agents ? tailscale-config)
    # RustDesk converges in root activation, after Home Manager decrypts the password.
    && (
      let
        text = c.system.activationScripts.postActivation.text;
        after = lib.splitString "Activating home-manager configuration" text;
      in
      builtins.length after == 2 && lib.hasInfix "remote_access.py darwin" (builtins.elemAt after 1)
    )
    && !(lib.any (p: p.name == "dotfiles-remote-apply") c.environment.systemPackages)
    && !(lib.hasInfix "dotfiles-remote-configure" c.security.sudo.extraConfig)
  )
  [
    "macbook-pro"
    "baleen-macbook"
    "kakaostyle-jito"
  ];
pkgs.runCommand "remote-access-integration"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.bash
    ];
  }
  ''
      export PYTHONDONTWRITEBYTECODE=1
      python3 ${./remote-access.py} ${../../scripts/lib/remote_access.py} ${../../machines/remote-access.json} ${../../users/shared/programs/tailscale-remote.py}
      bash ${./switch-entrypoint.sh} ${../..}
      touch "$out"
  ''
