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
        fake_firefox="$TMPDIR/firefox-bin"
        cat > "$fake_firefox" <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" >> "$CAPTURE"
        EOF
        chmod +x "$fake_firefox"

        export CAPTURE="$capture"
        export FF_FIREFOX_DATA_DIR="$firefox_data_dir"
        export FF_FIREFOX_BINARY="$fake_firefox"
        export FF_SQLITE3_BINARY="${pkgs.sqlite}/bin/sqlite3"
        export FF_NOHUP_BINARY="${pkgs.coreutils}/bin/nohup"

        ${pkgs.zsh}/bin/zsh ${scriptPath} work
        sleep 1
        grep -Fx -- '--no-remote' "$capture"
        grep -Fx -- '--profile' "$capture"
        grep -Fx -- "$firefox_data_dir/Profiles/work" "$capture"

        : > "$capture"
        ${pkgs.zsh}/bin/zsh ${scriptPath}
        sleep 1
        grep -Fx -- '--ProfileManager' "$capture"

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

    (helpers.assertTest "extension-exists" extensionExists "Firefox profile chooser Extension should exist")

    (helpers.assertTest "extension-manifest" (
      extensionPackageResult.success
      && (extensionPackage.name or null) == "firefox-profile"
      && lib.hasInfix ''"choose-profile"'' (builtins.readFile extensionPackagePath)
    ) "Firefox profile chooser Extension should declare its command")

    (helpers.assertTest "extension-reads-live-profiles" (
      lib.hasInfix "Profile Groups" extensionSource
      && lib.hasInfix "sqlite3" extensionSource
      && lib.hasInfix "List" extensionSource
    ) "Firefox profile chooser should build a dynamic List from Firefox profile data")

    (helpers.assertTest "script-exists" scriptExists "Firefox Raycast Script Command should exist")

    (helpers.assertTest "script-has-raycast-metadata" (
      has "@raycast.schemaVersion 1"
      && has "@raycast.title Firefox Profile"
      && has "@raycast.mode silent"
      && has "@raycast.argument1"
    ) "Firefox Script Command should declare Raycast metadata")

    (helpers.assertTest "script-reads-profile-groups" (
      has "Profile Groups" && has "sqlite3" && has "-readonly" && has "SELECT name, path FROM Profiles"
    ) "Firefox Script Command should read selectable profiles from SQLite")

    (helpers.assertTest "script-launches-profile" (
      has "--no-remote" && has "--profile" && has "ProfileManager"
    ) "Firefox Script Command should launch profiles and the fallback manager")

    (helpers.assertTest "script-does-not-manage-alfred" (
      !(lib.hasInfix "alfred" (lib.toLower script))
    ) "Raycast Script Command should not retain Alfred references")

    runtimeCheck
  ];
}
