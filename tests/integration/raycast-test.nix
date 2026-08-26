# Raycast Script Command integration tests
# Verifies the declarative Home Manager link and Firefox profile command.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  modulePath = ../../users/shared/programs/raycast.nix;
  moduleResult = builtins.tryEval (
    import modulePath {
      inherit pkgs lib;
      config = {
        modules.programs.raycast.enable = true;
      };
    }
  );
  module = if moduleResult.success then moduleResult.value else { };
  raycastConfig = if moduleResult.success then module.config.content else { };
  homeFiles = raycastConfig.home.file or { };
  scriptPath = ../../users/shared/programs/.config/raycast/script-commands/firefox-profile.sh;
  scriptExists = builtins.pathExists scriptPath;
  script = if scriptExists then builtins.readFile scriptPath else "";
  launcherPath = ../../users/shared/programs/.config/raycast/firefox-profile-launcher.zsh;
  launcherExists = builtins.pathExists launcherPath;
  launcher = if launcherExists then builtins.readFile launcherPath else "";
  helperPath = ../../users/shared/programs/.config/raycast/firefox-profile-activate.swift;
  helperExists = builtins.pathExists helperPath;
  helper = if helperExists then builtins.readFile helperPath else "";
  extensionPath = ../../users/shared/programs/.config/raycast/extensions/firefox-profile;
  extensionPackagePath = extensionPath + "/package.json";
  extensionSourcePath = extensionPath + "/src/choose-profile.tsx";
  extensionExists = builtins.pathExists extensionPath;
  extensionPackageResult =
    if builtins.pathExists extensionPackagePath then
      builtins.tryEval (builtins.fromJSON (builtins.readFile extensionPackagePath))
    else
      {
        success = false;
        value = { };
      };
  extensionPackage = if extensionPackageResult.success then extensionPackageResult.value else { };
  extensionSource =
    if builtins.pathExists extensionSourcePath then builtins.readFile extensionSourcePath else "";

  has = needle: lib.hasInfix needle script;

  runtimeCheck =
    pkgs.runCommand "raycast-firefox-profile-runtime"
      {
        nativeBuildInputs = [
          pkgs.sqlite
          pkgs.zsh
        ];
      }
      ''
        set -euo pipefail

        firefox_data_dir="$TMPDIR/firefox"
        mkdir -p "$firefox_data_dir/Profile Groups" "$firefox_data_dir/Profiles/work"

        cat > "$firefox_data_dir/profiles.ini" <<'EOF'
        [Profile0]
        Name=personal
        IsRelative=1
        Path=Profiles/personal
        StoreID=test-store
        EOF

        ${pkgs.sqlite}/bin/sqlite3 "$firefox_data_dir/Profile Groups/test-store.sqlite" <<'SQL'
        CREATE TABLE Profiles (id INTEGER PRIMARY KEY, name TEXT NOT NULL, path TEXT NOT NULL);
        INSERT INTO Profiles VALUES (1, 'Work', 'Profiles/work');
        SQL

        capture="$TMPDIR/firefox-args"
        open_capture="$TMPDIR/open-args"
        fake_firefox="$TMPDIR/firefox-bin"
        fake_open="$TMPDIR/open-bin"
        cat > "$fake_firefox" <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" >> "$CAPTURE"
        EOF
        cat > "$fake_open" <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" > "$OPEN_CAPTURE"
        EOF
        chmod +x "$fake_firefox"
        chmod +x "$fake_open"

        export CAPTURE="$capture"
        export OPEN_CAPTURE="$open_capture"
        export FF_FIREFOX_DATA_DIR="$firefox_data_dir"
        export FF_FIREFOX_BINARY="$fake_firefox"
        export FF_OPEN_BINARY="$fake_open"
        export FF_SQLITE3_BINARY="${pkgs.sqlite}/bin/sqlite3"
        export FF_NOHUP_BINARY="${pkgs.coreutils}/bin/nohup"
        export FF_FIREFOX_LAUNCHER="${launcherPath}"

        focus_args="$TMPDIR/focus-args"
        fake_ps="$TMPDIR/ps-bin"
        fake_lsof="$TMPDIR/lsof-bin"
        fake_activate="$TMPDIR/activate-bin"
        cat > "$fake_ps" <<'EOF'
        #!/bin/sh
        printf '%s\n' "5151 /Applications/Firefox.app/Contents/MacOS/firefox --profile $PS_PROFILE_PATH"
        EOF
        cat > "$fake_lsof" <<'EOF'
        #!/bin/sh
        exit 1
        EOF
        cat > "$fake_activate" <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" > "$FOCUS_ARGS"
        EOF
        chmod +x "$fake_ps" "$fake_lsof" "$fake_activate"
        export PS_PROFILE_PATH="$firefox_data_dir/Profiles/work"
        export FF_PS_BINARY="$fake_ps"
        export FF_LSOF_BINARY="$fake_lsof"
        export FF_FIREFOX_ACTIVATE_BINARY="$fake_activate"
        export FOCUS_ARGS="$focus_args"

        ${pkgs.zsh}/bin/zsh ${scriptPath} work
        test ! -s "$capture"
        grep -Fx -- '5151' "$focus_args"

        cat > "$fake_ps" <<'EOF'
        #!/bin/sh
        exit 1
        EOF
        chmod +x "$fake_ps"
        : > "$capture"
        ${pkgs.zsh}/bin/zsh ${scriptPath} work
        for attempt in $(seq 1 50); do
          [[ -s "$capture" ]] && break
          sleep 0.02
        done
        grep -Fx -- '--profile' "$capture"
        grep -Fx -- "$firefox_data_dir/Profiles/work" "$capture"

        : > "$capture"
        ${pkgs.zsh}/bin/zsh ${scriptPath}
        grep -Fx -- '-a' "$open_capture"
        grep -Fx -- 'Firefox' "$open_capture"

        touch "$out"
      '';

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "raycast" [
    (helpers.assertTest "module-importable" moduleResult.success "raycast.nix should be importable")

    (helpers.assertTest "home-file-configured" (
      moduleResult.success && builtins.hasAttr ".config/raycast/script-commands" homeFiles
    ) "Raycast Script Commands should be linked from Home Manager")

    (helpers.assertTest "home-file-recursive" (
      moduleResult.success && homeFiles.".config/raycast/script-commands".recursive or false
    ) "Raycast Script Commands should be managed recursively")

    (helpers.assertTest "home-file-force" (
      moduleResult.success && homeFiles.".config/raycast/script-commands".force or false
    ) "Raycast Script Commands should use a force symlink")

    (helpers.assertTest "launcher-file-configured" (
      moduleResult.success && builtins.hasAttr ".config/raycast/firefox-profile-launcher.zsh" homeFiles
    ) "Firefox profile launcher should be linked from Home Manager")

    (helpers.assertTest "focus-helper-configured" (
      moduleResult.success && builtins.hasAttr ".config/raycast/firefox-profile-activate" homeFiles
    ) "Firefox native focus helper should be linked from Home Manager")

    (helpers.assertTest "extension-exists" extensionExists
      "Firefox profile chooser Extension should exist"
    )

    (helpers.assertTest "extension-manifest" (
      extensionPackageResult.success
      && (extensionPackage.name or null) == "firefox-profile"
      && lib.hasInfix ''"choose-profile"'' (builtins.readFile extensionPackagePath)
    ) "Firefox profile chooser Extension should declare its command")

    (helpers.assertTest "extension-uses-launcher-profile-contract" (
      lib.hasInfix "--list-paths" extensionSource
      && lib.hasInfix "firefox-profile-launcher.zsh" extensionSource
      && lib.hasInfix "List" extensionSource
      && !(lib.hasInfix "Profile Groups" extensionSource)
      && !(lib.hasInfix "sqlite3" extensionSource)
    ) "Firefox profile chooser should use the launcher's live profile contract")

    (helpers.assertTest "extension-opens-default-profile" (
      lib.hasInfix "Open Default Firefox" extensionSource
      && lib.hasInfix "openDefaultProfile" extensionSource
    ) "Firefox profile chooser should expose the Firefox default profile")

    (helpers.assertTest "extension-does-not-open-profile-manager" (
      !(lib.hasInfix "Profile Manager" extensionSource)
      && !(lib.hasInfix "openProfileManager" extensionSource)
      && !(lib.hasInfix "ProfileManager" extensionSource)
    ) "Firefox profile chooser should not expose Profile Manager in the quick switcher")

    (helpers.assertTest "extension-launches-by-path" (
      lib.hasInfix "runProfileScript([profile.path])" extensionSource
    ) "Firefox profile chooser should launch the selected resolved path")

    (helpers.assertTest "extension-uses-use-promise" (
      lib.hasInfix "usePromise" extensionSource
      && lib.hasInfix "@raycast/utils" extensionSource
    ) "Firefox profile chooser should use Raycast async state management")

    (helpers.assertTest "extension-can-refresh-profiles" (
      lib.hasInfix "Refresh Profiles" extensionSource
      && lib.hasInfix "revalidate" extensionSource
    ) "Firefox profile chooser should refresh its live profile list")

    (helpers.assertTest "extension-reports-launch-errors" (
      lib.hasInfix "Could not open Firefox profile" extensionSource
    ) "Firefox profile chooser should report launch failures")

    (helpers.assertTest "script-exists" scriptExists "Firefox Raycast Script Command should exist")

    (helpers.assertTest "script-has-raycast-metadata" (
      has "@raycast.schemaVersion 1"
      && has "@raycast.title Firefox Profile"
      && has "@raycast.mode silent"
      && has "@raycast.argument1"
    ) "Firefox Script Command should declare Raycast metadata")

    (helpers.assertTest "launcher-reads-profile-groups" (
      lib.hasInfix "Profile Groups" launcher
      && lib.hasInfix "sqlite3" launcher
      && lib.hasInfix "-readonly" launcher
      && lib.hasInfix "SELECT name, path FROM Profiles" launcher
    ) "Firefox profile launcher should read selectable profiles from SQLite")

    (helpers.assertTest "script-delegates-profile-launch" (
      has "FF_FIREFOX_LAUNCHER"
      && has "firefox-profile-launcher.zsh"
      && has "optional"
      && has "FF_OPEN_BINARY"
      && !(has "--ProfileManager")
    ) "Firefox Script Command should delegate profile launch and open normal Firefox")

    (helpers.assertTest "launcher-detaches-new-profile" (
      lib.hasInfix "FF_NOHUP_BINARY" launcher
      && lib.hasInfix "nohup_binary" launcher
      && lib.hasInfix "2>&1 &" launcher
    ) "Firefox profile launcher should not block on a new Firefox process")

    (helpers.assertTest "launcher-focuses-existing-profile" (
      lib.hasInfix "firefox-profile-activate" launcher
      && lib.hasInfix "profile_pid_from_ps" launcher
      && lib.hasInfix "profile_pid_from_lsof" launcher
      && !(lib.hasInfix "--no-remote" launcher)
    ) "Firefox profile launcher should focus an existing profile process")

    (helpers.assertTest "focus-helper-uses-cooperative-activation" (
      !(lib.hasInfix "activateIgnoringOtherApps" helper)
      && lib.hasInfix "activateAllWindows" helper
    ) "Firefox native focus helper should avoid deprecated focus stealing")

    (helpers.assertTest "script-does-not-manage-alfred" (
      !(lib.hasInfix "alfred" (lib.toLower script))
    ) "Raycast Script Command should not retain Alfred references")

    runtimeCheck
  ];
}
