# Runs the real opencodePlugins activation snippet against fixture files.
# The snippet merges into a user-writable opencode.json, so a regression
# silently drops hand-added plugins or rewrites a JSONC file.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  homeConfig = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/opencode.nix
      {
        modules.programs.opencode.enable = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };

  inherit (homeConfig) config;

  snippet = builtins.replaceStrings [ config.xdg.configHome ] [ "$TEST_CONFIG" ]
    config.home.activation.opencodePlugins.data;
  plugin = "skills@git+https://github.com/baleen37/skills.git";
in
pkgs.runCommand "test-opencode-plugins-activation"
  {
    nativeBuildInputs = [ pkgs.jq ];
  }
  ''
    set -euo pipefail
    run() { "$@"; }
    warnEcho() { echo "$*" >&2; }
    activate() { ( ${snippet} ) 2> "$TMPDIR/stderr"; }

    export TEST_CONFIG="$TMPDIR/config"
    file="$TEST_CONFIG/opencode/opencode.json"

    # Missing file: created with the plugin.
    activate
    jq -e --arg p ${lib.escapeShellArg plugin} '.plugins == [$p]' "$file"

    # Existing keys and hand-added plugins survive; the plugin is not duplicated.
    echo '{"theme":"x","plugins":["other@1", ${builtins.toJSON plugin}]}' > "$file"
    activate
    jq -e --arg p ${lib.escapeShellArg plugin} \
      '.theme == "x" and (.plugins | sort) == (["other@1", $p] | sort)' "$file"

    # Second run leaves the file untouched.
    before=$(cat "$file")
    activate
    [ "$(cat "$file")" = "$before" ]

    # JSONC is left alone with a warning.
    printf '// comment\n{"plugins":[]}\n' > "$file"
    cp "$file" "$TMPDIR/jsonc"
    activate
    cmp "$file" "$TMPDIR/jsonc"
    grep -q "not plain JSON" "$TMPDIR/stderr"

    touch "$out"
  ''
