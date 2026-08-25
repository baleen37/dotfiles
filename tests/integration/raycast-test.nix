# Raycast Script Command integration tests
# Verifies the declarative Home Manager link and Firefox profile command.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  testLib = lib // {
    hm = {
      dag.entryAfter = dependencies: body: {
        after = dependencies;
        data = body;
      };
    };
  };

  modulePath = ../../users/shared/programs/raycast.nix;
  moduleResult = builtins.tryEval (
    import modulePath {
      inherit pkgs;
      lib = testLib;
      config = {
        modules.programs.raycast.enable = true;
      };
    }
  );
  module = if moduleResult.success then moduleResult.value else { };
  raycastConfig = if moduleResult.success then module.config.content else { };
  homeFiles = raycastConfig.home.file or { };
  activation = raycastConfig.home.activation or { };
  launcherPath = "${../../users/shared/programs/.config/raycast}/firefox-profile-launcher.zsh";
  generatorPath = "${../../users/shared/programs/.config/raycast}/generate-firefox-profile-command.zsh";
  helperPath = "${../../users/shared/programs/.config/raycast}/firefox-profile-activate.swift";
  launcherExists = builtins.pathExists launcherPath;
  generatorExists = builtins.pathExists generatorPath;
  helperExists = builtins.pathExists helperPath;
  launcher = if launcherExists then builtins.readFile launcherPath else "";
  generator = if generatorExists then builtins.readFile generatorPath else "";
  helper = if helperExists then builtins.readFile helperPath else "";
  helperHomeFile = homeFiles.".config/raycast/firefox-profile-activate" or { };
  helperSource = helperHomeFile.source or null;

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
        test -x "${helperSource}"

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
        fake_firefox="$TMPDIR/firefox-bin"
        cat > "$fake_firefox" <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" >> "$CAPTURE"
        if [ -n "''${FAKE_FIREFOX_DELAY:-}" ]; then
          sleep "$FAKE_FIREFOX_DELAY"
          printf '%s\n' done >> "$CAPTURE"
        fi
        EOF
        chmod +x "$fake_firefox"

        export CAPTURE="$capture"
        export FF_FIREFOX_DATA_DIR="$firefox_data_dir"
        export FF_FIREFOX_BINARY="$fake_firefox"
        export FF_SQLITE3_BINARY="${pkgs.sqlite}/bin/sqlite3"

        focus_args="$TMPDIR/focus-args"
        lsof_called="$TMPDIR/lsof-called"
        ps_profile_path="$firefox_data_dir/Profiles/work"
        fake_lsof="$TMPDIR/lsof-bin"
        fake_ps="$TMPDIR/ps-bin"
        fake_activate="$TMPDIR/activate-bin"
        cat > "$fake_lsof" <<'EOF'
        #!/bin/sh
        printf '%s\n' 4242
        EOF
        chmod +x "$fake_lsof"
        cat > "$fake_ps" <<'EOF'
        #!/bin/sh
        printf '%s\n' "6161 /Applications/Firefox.app/Contents/MacOS/plugin-container --profile $PS_PROFILE_PATH"
        printf '%s\n' "5151 /Applications/Firefox.app/Contents/MacOS/firefox --profile $PS_PROFILE_PATH"
        EOF
        chmod +x "$fake_ps"
        cat > "$fake_activate" <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" > "$FOCUS_ARGS"
        EOF
        chmod +x "$fake_activate"

        export PS_PROFILE_PATH="$ps_profile_path"
        export FF_PS_BINARY="$fake_ps"
        export FF_LSOF_BINARY="$fake_lsof"
        export FF_FIREFOX_ACTIVATE_BINARY="$fake_activate"
        export FOCUS_ARGS="$focus_args"
        : > "$lsof_called"
        cat > "$fake_lsof" <<EOF
        #!/bin/sh
        printf '%s\n' called > "$lsof_called"
        exit 1
        EOF
        chmod +x "$fake_lsof"
        : > "$capture"
        ${pkgs.zsh}/bin/zsh ${launcherPath} Work > "$TMPDIR/fast-output" 2>&1
        test ! -s "$capture"
        grep -Fx -- '5151' "$focus_args"
        test ! -s "$lsof_called"
        unset FF_PS_BINARY FF_LSOF_BINARY FF_FIREFOX_ACTIVATE_BINARY PS_PROFILE_PATH FOCUS_ARGS

        export FF_LSOF_BINARY="$fake_lsof"
        export FF_FIREFOX_ACTIVATE_BINARY="$fake_activate"
        export FOCUS_ARGS="$focus_args"
        cat > "$fake_lsof" <<'EOF'
        #!/bin/sh
        printf '%s\n' 4242
        EOF
        chmod +x "$fake_lsof"
        touch "$firefox_data_dir/Profiles/work/.parentlock"
        : > "$capture"
        ${pkgs.zsh}/bin/zsh ${launcherPath} Work > "$TMPDIR/focus-output" 2>&1
        test ! -s "$capture"
        grep -Fx -- '4242' "$focus_args"
        unset FF_LSOF_BINARY FF_FIREFOX_ACTIVATE_BINARY FOCUS_ARGS
        rm -f "$firefox_data_dir/Profiles/work/.parentlock"

        ${pkgs.zsh}/bin/zsh ${launcherPath} Work
        sleep 1
        ! grep -Fx -- '--no-remote' "$capture"
        grep -Fx -- '--profile' "$capture"
        grep -Fx -- "$firefox_data_dir/Profiles/work" "$capture"

        export FAKE_FIREFOX_DELAY=1
        : > "$capture"
        ${pkgs.zsh}/bin/zsh ${launcherPath} Work > "$TMPDIR/launcher-output" 2>&1 &
        launcher_pid=$!
        sleep 0.2
        ! grep -Fx -- done "$capture"
        wait "$launcher_pid"
        grep -Fx -- done "$capture"
        unset FAKE_FIREFOX_DELAY

        generated="$TMPDIR/firefox-profile-generated.sh"
        export FF_FIREFOX_LAUNCHER="${launcherPath}"
        ${pkgs.zsh}/bin/zsh ${generatorPath} "$generated"
        test -x "$generated"
        grep -F -- '@raycast.argument1' "$generated"
        test "$(grep -c '^# @raycast.argument1 ' "$generated")" -eq 1
        grep -F -- '"title": "Work", "value": "'$firefox_data_dir'/Profiles/work"' "$generated"
        ! grep -F -- 'Profile Manager' "$generated"
        ! grep -F -- '__profile_manager__' "$generated"

        sqlite_fail="$TMPDIR/sqlite-fail"
        ps_fail="$TMPDIR/ps-fail"
        cat > "$sqlite_fail" <<'EOF'
        #!/bin/sh
        exit 1
        EOF
        cat > "$ps_fail" <<'EOF'
        #!/bin/sh
        exit 1
        EOF
        chmod +x "$sqlite_fail" "$ps_fail"
        : > "$capture"
        export FF_SQLITE3_BINARY="$sqlite_fail"
        export FF_PS_BINARY="$ps_fail"
        export FF_FIREFOX_DATA_DIR="$TMPDIR/missing-firefox-data"
        ${pkgs.zsh}/bin/zsh ${launcherPath} "$firefox_data_dir/Profiles/work"
        grep -Fx -- '--profile' "$capture"
        grep -Fx -- "$firefox_data_dir/Profiles/work" "$capture"

        touch "$out"
      '';

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "raycast" [
    (helpers.assertTest "module-importable" moduleResult.success "raycast.nix should be importable")

    (helpers.assertTest "launcher-file-configured" (
      moduleResult.success && builtins.hasAttr ".config/raycast/firefox-profile-launcher.zsh" homeFiles
    ) "Firefox profile launcher should be linked from Home Manager")

    (helpers.assertTest "generator-file-configured" (
      moduleResult.success
      && builtins.hasAttr ".config/raycast/generate-firefox-profile-command.zsh" homeFiles
    ) "Firefox profile dropdown generator should be linked from Home Manager")

    (helpers.assertTest "focus-helper-file-configured" (
      moduleResult.success && builtins.hasAttr ".config/raycast/firefox-profile-activate" homeFiles
    ) "Firefox native activation helper should be linked from Home Manager")

    (helpers.assertTest "activation-configured" (
      moduleResult.success
      && builtins.hasAttr "raycastFirefoxProfileCommand" activation
      && lib.hasInfix "generate-firefox-profile-command" activation.raycastFirefoxProfileCommand.data
    ) "Home Manager should regenerate the Raycast dropdown")

    (helpers.assertTest "launcher-exists" launcherExists "Firefox profile launcher should exist")

    (helpers.assertTest "generator-exists" generatorExists "Firefox dropdown generator should exist")

    (helpers.assertTest "focus-helper-exists" helperExists
      "Firefox native activation helper should exist"
    )

    (helpers.assertTest "launcher-lists-profiles" (
      lib.hasInfix "--list" launcher
      && lib.hasInfix "Profile Groups" launcher
      && lib.hasInfix "sqlite3" launcher
    ) "Firefox profile launcher should expose profile names for generation")

    (helpers.assertTest "launcher-reuses-firefox" (
      lib.hasInfix "--profile" launcher
      && !(lib.hasInfix "--no-remote" launcher)
      && !(lib.hasInfix "--new-instance" launcher)
      && !(lib.hasInfix "ProfileManager" launcher)
      && !(lib.hasInfix "__profile_manager__" launcher)
      && lib.hasInfix "ps" launcher
      && lib.hasInfix "lsof" launcher
      && lib.hasInfix "firefox-profile-activate" launcher
    ) "Firefox launcher should reuse an existing profile process")

    (helpers.assertTest "generator-has-dropdown" (
      lib.hasInfix "@raycast.argument1" generator
      && lib.hasInfix "dropdown" generator
      && lib.hasInfix "--list-paths" generator
      && !(lib.hasInfix "Profile Manager" generator)
      && !(lib.hasInfix "__profile_manager__" generator)
    ) "Generated Firefox command should use a dropdown argument")

    (helpers.assertTest "focus-helper-uses-native-activation" (
      lib.hasInfix "NSRunningApplication" helper && lib.hasInfix "activate(options:" helper
    ) "Native helper should activate the Firefox process directly")

    (helpers.assertTest "focus-helper-built" (
      moduleResult.success && helperSource != null
    ) "Home Manager should build the native Firefox activation helper")

    runtimeCheck
  ];
}
