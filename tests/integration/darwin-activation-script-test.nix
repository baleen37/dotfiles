# Darwin activation is tested with fake tools so the check never touches the
# host's Spotlight index, Remote Login setting, or installed applications. The
# script is plain bash, so it runs on Linux builders too.
{
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  scriptPath = ../../users/shared/darwin/activation.sh;
  scriptExists = builtins.pathExists scriptPath;

  behaviorTest =
    if !scriptExists then
      helpers.assertTest "darwin-activation-script-exists" false
        "users/shared/darwin/activation.sh must exist"
    else
      pkgs.runCommand "test-darwin-activation-script-behavior"
        {
          nativeBuildInputs = [ pkgs.bash ];
        }
        ''
          set -euo pipefail

          test_root="$TMPDIR/darwin-activation"
          apps="$test_root/Applications"
          log="$test_root/activation.log"
          fake_bin="$test_root/bin"
          mkdir -p "$apps" "$fake_bin"
          touch "$log"

          cat > "$fake_bin/mdutil" <<'EOF'
          #!/bin/sh
          set -eu
          printf 'mdutil %s\n' "$*" >> "$DARWIN_TEST_LOG"
          if [ "$1" = -s ]; then
            printf '/:\n\tIndexing %s.\n' "$DARWIN_TEST_SPOTLIGHT"
          fi
          EOF

          cat > "$fake_bin/mdls" <<'EOF'
          #!/bin/sh
          set -eu
          printf '%s' "$DARWIN_TEST_ADAM_ID"
          EOF

          cat > "$fake_bin/mdimport" <<'EOF'
          #!/bin/sh
          set -eu
          printf 'mdimport %s\n' "$*" >> "$DARWIN_TEST_LOG"
          EOF

          cat > "$fake_bin/systemsetup" <<'EOF'
          #!/bin/sh
          set -eu
          printf 'systemsetup %s\n' "$*" >> "$DARWIN_TEST_LOG"
          if [ "$1" = -getremotelogin ]; then
            printf 'Remote Login: %s\n' "$DARWIN_TEST_REMOTE_LOGIN"
          fi
          EOF
          chmod +x "$fake_bin"/*

          export DARWIN_TEST_LOG="$log"
          export DARWIN_ACTIVATION_APPLICATIONS_DIR="$apps"
          export DARWIN_ACTIVATION_MDUTIL="$fake_bin/mdutil"
          export DARWIN_ACTIVATION_MDLS="$fake_bin/mdls"
          export DARWIN_ACTIVATION_MDIMPORT="$fake_bin/mdimport"
          export DARWIN_ACTIVATION_SYSTEMSETUP="$fake_bin/systemsetup"
          export PATH="${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin"

          # `! cmd` never trips `set -e`, so negative assertions need an explicit exit.
          refute() {
            if "$@"; then
              echo "unexpectedly succeeded: $*" >&2
              exit 1
            fi
          }

          run() {
            : > "$log"
            ${pkgs.bash}/bin/bash ${scriptPath} "$@" 2> "$test_root/stderr"
          }

          # Spotlight disabled, KakaoTalk installed without an Adam ID: re-enable
          # indexing and import the app so mas can find it.
          mkdir -p "$apps/KakaoTalk.app"
          export DARWIN_TEST_SPOTLIGHT=disabled DARWIN_TEST_ADAM_ID='(null)'
          run spotlight
          grep -Fqx 'mdutil -E -i on /' "$log"
          grep -Fqx "mdimport $apps/KakaoTalk.app" "$log"
          test "$(grep -c '^mdimport ' "$log")" -eq 1

          # Spotlight enabled and the Adam ID already indexed: nothing to do.
          export DARWIN_TEST_SPOTLIGHT=enabled DARWIN_TEST_ADAM_ID=869223134
          run spotlight
          refute grep -Fq -- '-E -i on' "$log"
          refute grep -q '^mdimport ' "$log"

          # KakaoTalk not installed: never import a missing path.
          rmdir "$apps/KakaoTalk.app"
          export DARWIN_TEST_ADAM_ID=""
          run spotlight
          refute grep -q '^mdimport ' "$log"

          # Remote Login off: turn it on.
          export DARWIN_TEST_REMOTE_LOGIN=Off
          run remote-login
          grep -Fqx 'systemsetup -setremotelogin -f on' "$log"

          # Remote Login already on: leave it alone.
          export DARWIN_TEST_REMOTE_LOGIN=On
          run remote-login
          grep -Fqx 'systemsetup -getremotelogin' "$log"
          refute grep -Fq -- '-setremotelogin' "$log"
          grep -Fq 'Remote Login already enabled' "$test_root/stderr"

          # A failing systemsetup must abort, as the inline segment did under set -e.
          cat > "$fake_bin/systemsetup-broken" <<'EOF'
          #!/bin/sh
          exit 3
          EOF
          chmod +x "$fake_bin/systemsetup-broken"
          if DARWIN_ACTIVATION_SYSTEMSETUP="$fake_bin/systemsetup-broken" run remote-login; then
            echo "remote-login unexpectedly succeeded when systemsetup failed" >&2
            exit 1
          fi

          # App cleanup removes listed apps, keeps unlisted ones, and counts a
          # removal it cannot complete (SIP) as skipped instead of failing.
          mkdir -p "$apps/GarageBand.app" "$apps/iMovie.app" "$apps/Safari.app" \
            "$apps/TV.app/Contents"
          touch "$apps/TV.app/Contents/Info.plist"
          chmod 555 "$apps/TV.app/Contents"
          run app-cleanup
          chmod 755 "$apps/TV.app/Contents"
          test ! -e "$apps/GarageBand.app"
          test ! -e "$apps/iMovie.app"
          test -d "$apps/Safari.app"
          test -d "$apps/TV.app"
          grep -Fq 'Failed to remove (SIP protected): TV.app' "$test_root/stderr"
          grep -Fq 'Removed: 2 apps' "$test_root/stderr"
          grep -Fq 'Skipped: 1 apps (protected)' "$test_root/stderr"
          grep -Fq 'Already removed: Freeform.app' "$test_root/stderr"

          if run bogus; then
            echo "unknown subcommand unexpectedly succeeded" >&2
            exit 1
          fi

          touch "$out"
        '';
in
{
  platforms = [ "any" ];
  value = behaviorTest;
}
