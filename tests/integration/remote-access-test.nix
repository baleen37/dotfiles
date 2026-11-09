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
    && home.sops.secrets.tailscale-auth-key.format == "json"
    && home.modules.programs.tailscale.authKeyFile == home.sops.secrets.tailscale-auth-key.path
    && builtins.elem "--server" home.launchd.agents.rustdesk.config.ProgramArguments
    && !(c.launchd.daemons ? dotfiles-rustdesk)
    && !(home.launchd.agents ? tailscale-config)
    && lib.any (p: p.name == "dotfiles-remote-apply") c.environment.systemPackages
    && lib.hasInfix ''/run/current-system/sw/bin/dotfiles-remote-configure ""'' c.security.sudo.extraConfig
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
    ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin (
      lib.concatMapStringsSep "\n"
        (name: ''
          status=0
          ${
            lib.getExe (
              lib.findFirst (
                p: p.name == name
              ) (throw "missing ${name}") self.darwinConfigurations.macbook-pro.config.environment.systemPackages
            )
          } unexpected-argument > output 2>&1 || status=$?
          [ "$status" -eq 2 ]
          grep -q 'takes no arguments' output
        '')
        [
          "dotfiles-remote-configure"
          "dotfiles-remote-apply"
        ]
    )}
      touch "$out"
  ''
