# User secrets share one implementation across system and standalone HM outputs.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.secrets;
  enabled = config.sops.secrets != { };
  encryptedFiles = lib.unique (
    map (s: {
      file = s.sopsFile;
      inherit (s) format;
    }) (builtins.attrValues config.sops.secrets)
  );
  preflight = pkgs.writeShellApplication {
    name = "dotfiles-secrets-check";
    runtimeInputs = [
      pkgs.age
      pkgs.sops
    ];
    text = ''
      key_file="''${1:-${config.sops.age.keyFile}}"
      [ -f "$key_file" ] && [ ! -L "$key_file" ] && [ -s "$key_file" ] || {
        echo "Missing or invalid age key: run ./bootstrap.sh" >&2
        exit 1
      }
      age-keygen -y "$key_file" >/dev/null
    ''
    + (
      if !enabled then
        ''
          echo "No secrets declared for this configuration."
        ''
      else
        ''
          unset SOPS_AGE_KEY SOPS_AGE_KEY_CMD SOPS_AGE_SSH_PRIVATE_KEY_CMD
          export SOPS_AGE_KEY_FILE="$key_file"
          export SOPS_AGE_SSH_PRIVATE_KEY_FILE=/dev/null
          export SOPS_GPG_EXEC=false
          ${lib.concatMapStringsSep "\n" (s: ''
            sops --decrypt --input-type ${lib.escapeShellArg s.format} ${lib.escapeShellArg (toString s.file)} >/dev/null
          '') encryptedFiles}
          echo "Declared secrets decrypt successfully."
        ''
    );
  };
  # Run the same upstream installer synchronously; the default HM Darwin hook
  # only starts launchd and can return before any secret has been written.
  installer =
    if pkgs.stdenv.hostPlatform.isDarwin then
      config.launchd.agents.sops-nix.config.Program
    else
      config.systemd.user.services.sops-nix.Service.ExecStart;
in
{
  options.modules.secrets = {
    gpgImports = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Names in sops.secrets containing exported GPG keys to import after decryption.";
    };
    preflight = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = preflight;
      description = "Public readiness check used by bootstrap.sh and switch.sh; never prints secrets.";
    };
  };

  config = lib.mkMerge [
    {
      sops.age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      sops.age.generateKey = false;
    }
    (lib.mkIf enabled {
      assertions = [
        {
          assertion = lib.all (name: builtins.hasAttr name config.sops.secrets) cfg.gpgImports;
          message = "modules.secrets.gpgImports must refer to declared sops.secrets.";
        }
      ];
      home.activation.sops-nix = lib.mkForce (
        lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
          run ${pkgs.coreutils}/bin/env ${
            lib.concatStringsSep " " (
              lib.mapAttrsToList (name: value: lib.escapeShellArg "${name}=${value}") config.sops.environment
            )
          } ${installer}
        ''
      );
      home.activation.importSecretGpgKeys = lib.hm.dag.entryAfter [ "sops-nix" ] (
        lib.concatMapStringsSep "\n" (name: ''
          run ${pkgs.gnupg}/bin/gpg --batch --import ${lib.escapeShellArg config.sops.secrets.${name}.path}
        '') cfg.gpgImports
      );
      home.packages = lib.optionals (cfg.gpgImports != [ ]) [ pkgs.gnupg ];
    })
  ];
}
