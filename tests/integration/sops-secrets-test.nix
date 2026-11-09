{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  # Test identities are generated during the build; no real keys are read.
  fixture =
    pkgs.runCommand "synthetic-sops-fixture"
      {
        nativeBuildInputs = [
          pkgs.age
          pkgs.sops
          pkgs.gnupg
          pkgs.jq
        ];
      }
      ''
        mkdir -p "$out"
        age-keygen -o "$out/identity" 2>/dev/null
        age-keygen -o "$out/wrong-identity" 2>/dev/null
        recipient=$(age-keygen -y "$out/identity")
        export GNUPGHOME="$TMPDIR/gpg-source"
        mkdir -m 700 "$GNUPGHOME"
        gpg --batch --pinentry-mode loopback --passphrase "" --quick-generate-key \
          'Synthetic Fixture <fixture@example.invalid>' ed25519 sign 0
        gpg --batch --armor --export-secret-keys > "$out/export.asc"
        gpg --batch --with-colons --list-secret-keys | awk -F: '$1 == "fpr" { print $10; exit }' > "$out/fingerprint"
        jq -n --rawfile gpg "$out/export.asc" '{token: "synthetic-token", gpg: $gpg}' > plain.json
        sops --encrypt --age "$recipient" --input-type json --output-type json plain.json > "$out/secrets.json"
        gpgconf --kill all
      '';
  probe = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      inputs.sops-nix.homeManagerModules.sops
      ../../users/shared/secrets.nix
      {
        home.username = "fixture";
        home.homeDirectory = "/tmp/dotfiles-sops-fixture";
        home.stateVersion = "24.11";
        sops.defaultSopsFile = "${fixture}/secrets.json";
        sops.defaultSopsFormat = "json";
        sops.secrets.token = { };
        sops.secrets.gpg = {
          path = "/tmp/dotfiles-sops-fixture/gpg.asc";
        };
        modules.secrets.gpgImports = [ "gpg" ];
      }
    ];
  };
  inherit (probe) config;
  emptyProbe = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      inputs.sops-nix.homeManagerModules.sops
      ../../users/shared/secrets.nix
      {
        home.username = "fixture";
        home.homeDirectory = "/tmp/dotfiles-sops-fixture";
        home.stateVersion = "24.11";
      }
    ];
  };
  gpgImport =
    lib.replaceStrings [ "/tmp/dotfiles-sops-fixture/gpg.asc" ] [ "$PWD/restored.asc" ]
      config.home.activation.importSecretGpgKeys.data;
in
pkgs.runCommand "sops-secrets-integration"
  {
    nativeBuildInputs = [
      pkgs.age
      pkgs.sops
      pkgs.gnupg
    ];
    preflight = config.modules.secrets.preflight;
    emptyPreflight = emptyProbe.config.modules.secrets.preflight;
  }
  ''
    # Even a configuration with no declared secrets requires a valid identity.
    if "$emptyPreflight/bin/dotfiles-secrets-check" "$PWD/missing-identity"; then
      echo "missing identity unexpectedly passed empty configuration" >&2; exit 1
    fi
    printf 'not-an-age-key\n' > invalid-identity
    if "$emptyPreflight/bin/dotfiles-secrets-check" "$PWD/invalid-identity"; then
      echo "invalid identity unexpectedly passed empty configuration" >&2; exit 1
    fi
    ln -s ${fixture}/identity linked-identity
    if "$emptyPreflight/bin/dotfiles-secrets-check" "$PWD/linked-identity"; then
      echo "symlinked identity unexpectedly passed empty configuration" >&2; exit 1
    fi
    "$emptyPreflight/bin/dotfiles-secrets-check" ${fixture}/identity
    "$preflight/bin/dotfiles-secrets-check" ${fixture}/identity
    if "$preflight/bin/dotfiles-secrets-check" ${fixture}/wrong-identity; then
      echo "wrong age identity unexpectedly decrypted the fixture" >&2; exit 1
    fi
    SOPS_AGE_KEY_FILE=${fixture}/identity sops --decrypt --extract '["gpg"]' ${fixture}/secrets.json > restored.asc
    export GNUPGHOME="$TMPDIR/gpg-target"
    mkdir -m 700 "$GNUPGHOME"
    run() { "$@"; }
    ${gpgImport}
    gpg --batch --with-colons --list-secret-keys | grep -F "$(cat ${fixture}/fingerprint)"
    # Re-import must preserve the same identity.
    ${gpgImport}
    gpgconf --kill all
    ${lib.optionalString (!(builtins.elem "sops-nix" config.home.activation.importSecretGpgKeys.after))
      ''
        echo "GPG import must be ordered after synchronous sops installation" >&2; exit 1
      ''
    }
    ${lib.optionalString (!(builtins.elem "linkGeneration" config.home.activation.sops-nix.before)) ''
      echo "secrets must decrypt before dependent home files are linked" >&2; exit 1
    ''}
    touch "$out"
  ''
