# LaunchServices repair is tested with fake tools so the check never mutates the
# host's LaunchServices database or installed applications.
{
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  scriptPath = ../../users/shared/darwin/vscode-launchservices.sh;
  scriptExists = builtins.pathExists scriptPath;

  behaviorTest =
    if !scriptExists then
      helpers.assertTest "vscode-launchservices-script-exists" false
        "users/shared/darwin/vscode-launchservices.sh must exist"
    else
      pkgs.runCommand "test-vscode-launchservices-behavior"
        {
          nativeBuildInputs = [ pkgs.bash ];
        }
        ''
          set -euo pipefail

          test_root="$TMPDIR/vscode-launchservices"
          app="$test_root/Applications/Visual Studio Code.app"
          profile="$test_root/profile"
          state="$test_root/launchservices-state"
          log="$test_root/launchservices.log"
          fake_bin="$test_root/bin"
          mkdir -p "$app/Contents" "$fake_bin" "$profile"

          cat > "$app/Contents/Info.plist" <<'EOF'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>CFBundleIdentifier</key>
            <string>com.microsoft.VSCode</string>
          </dict>
          </plist>
          EOF

          {
            printf '%s\n' '/nix/store/fake-vscode/Applications/Visual Studio Code.app'
            printf '%s\n' "$app"
          } > "$state"

          cat > "$fake_bin/lsregister" <<'EOF'
          #!/bin/sh
          set -eu
          state="$VSCODE_TEST_STATE"
          log="$VSCODE_TEST_LOG"
          case "$1" in
            -dump)
              while IFS= read -r path; do
                printf 'path: %s\nidentifier: com.microsoft.VSCode\n' "$path"
              done < "$state"
              ;;
            -u)
              printf 'unregister %s\n' "$2" >> "$log"
              grep -Fvx "$2" "$state" > "$state.tmp" || true
              mv "$state.tmp" "$state"
              ;;
            -f)
              printf 'register %s\n' "$2" >> "$log"
              if ! grep -Fqx "$2" "$state"; then
                printf '%s\n' "$2" >> "$state"
              fi
              ;;
            *)
              echo "unexpected lsregister args: $*" >&2
              exit 2
              ;;
          esac
          EOF
          chmod +x "$fake_bin/lsregister"

          cat > "$fake_bin/mdimport" <<'EOF'
          #!/bin/sh
          set -eu
          printf 'mdimport %s\n' "$2" >> "$VSCODE_TEST_LOG"
          EOF
          chmod +x "$fake_bin/mdimport"

          cat > "$fake_bin/osascript" <<'EOF'
          #!/bin/sh
          set -eu
          first_path="$(sed -n '1p' "$VSCODE_TEST_STATE")"
          printf '%s\n' "$first_path"
          EOF
          chmod +x "$fake_bin/osascript"

          export VSCODE_TEST_STATE="$state"
          export VSCODE_TEST_LOG="$log"
          export VSCODE_LSREGISTER="$fake_bin/lsregister"
          export VSCODE_MDIMPORT="$fake_bin/mdimport"
          export VSCODE_OSASCRIPT="$fake_bin/osascript"
          export VSCODE_CANONICAL_APP="$app"

          ${pkgs.bash}/bin/bash ${scriptPath} audit > "$test_root/audit-before" || test "$?" -eq 1
          grep -Fq 'representative=/nix/store/fake-vscode/Applications/Visual Studio Code.app' \
            "$test_root/audit-before"
          grep -Fq 'nix_registered=/nix/store/fake-vscode/Applications/Visual Studio Code.app' \
            "$test_root/audit-before"

          ${pkgs.bash}/bin/bash ${scriptPath} repair
          test -d "$app"
          test -d "$profile"
          ! grep -Fq '/nix/store/fake-vscode/Applications/Visual Studio Code.app' "$state"
          grep -Fqx "$app" "$state"
          grep -Fqx "unregister /nix/store/fake-vscode/Applications/Visual Studio Code.app" "$log"
          grep -Fqx "register $app" "$log"
          grep -Fqx "mdimport $app" "$log"

          cp "$state" "$test_root/state-after-first-repair"
          ${pkgs.bash}/bin/bash ${scriptPath} repair
          cmp -s "$test_root/state-after-first-repair" "$state"
          test "$(grep -Fc 'unregister /nix/store/fake-vscode/Applications/Visual Studio Code.app' "$log")" -eq 1

          ${pkgs.bash}/bin/bash ${scriptPath} audit > "$test_root/audit-after"
          grep -Fq "representative=$app" "$test_root/audit-after"
          grep -Fq 'nix_registered=none' "$test_root/audit-after"
          test -e "$app/Contents/Info.plist"
          test -e "$profile"

          sed 's/com.microsoft.VSCode/com.example.Wrong/' "$app/Contents/Info.plist" \
            > "$app/Contents/Info.plist.wrong"
          mv "$app/Contents/Info.plist.wrong" "$app/Contents/Info.plist"
          if ${pkgs.bash}/bin/bash ${scriptPath} repair > "$test_root/wrong-bundle.log" 2>&1; then
            echo "repair unexpectedly accepted a non-VS Code bundle ID" >&2
            exit 1
          fi
          grep -Fq 'expected com.microsoft.VSCode' "$test_root/wrong-bundle.log"
          test -e "$app/Contents/Info.plist"
          test -e "$profile"
          touch "$out"
        '';
in
{
  platforms = [ "darwin" ];
  value = behaviorTest;
}
