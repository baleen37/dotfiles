# Alfred workflow integration tests.
#
# The workflow source is intentionally tested as files plus a real Home Manager
# evaluation. Alfred's runtime prefs.plist is user state and must not be part of
# this source tree.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  modulePath = ../../users/shared/programs/alfred.nix;
  workflowsPath = ../../users/shared/programs/.config/alfred/workflows;
  firefoxWorkflowPath = workflowsPath + "/firefox-profiles";
  infoPath = firefoxWorkflowPath + "/info.plist";
  listScriptPath = firefoxWorkflowPath + "/list-profiles.zsh";
  openScriptPath = firefoxWorkflowPath + "/open-profile.zsh";

  moduleExists = builtins.pathExists modulePath;
  workflowsExist = builtins.pathExists workflowsPath;
  firefoxWorkflowExists = builtins.pathExists firefoxWorkflowPath;
  infoExists = builtins.pathExists infoPath;
  infoText = if infoExists then builtins.readFile infoPath else "";
  openScriptText =
    if builtins.pathExists openScriptPath then builtins.readFile openScriptPath else "";
  workflowEntries =
    if workflowsExist then builtins.attrNames (builtins.readDir workflowsPath) else [ ];

  evalHome =
    extraModule:
    if moduleExists then
      builtins.tryEval (
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            modulePath
            {
              home = {
                username = "testuser";
                homeDirectory = "/Users/testuser";
                stateVersion = "24.11";
              };
            }
            extraModule
          ];
        }
      )
    else
      {
        success = false;
        value = { };
      };

  defaultEvaluation = evalHome { };
  defaultHome = if defaultEvaluation.success then defaultEvaluation.value else { };
  defaultFiles = if defaultEvaluation.success then defaultHome.config.home.file else { };
  defaultWorkflowTarget = "Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/firefox-profiles";
  defaultWorkflowFile = defaultFiles.${defaultWorkflowTarget} or { };

  syncedEvaluation = evalHome {
    modules.programs.alfred.preferencesPath = "Synced/Alfred.alfredpreferences";
  };
  syncedHome = if syncedEvaluation.success then syncedEvaluation.value else { };
  syncedFiles = if syncedEvaluation.success then syncedHome.config.home.file else { };
  syncedWorkflowTarget = "Synced/Alfred.alfredpreferences/workflows/firefox-profiles";

  profileListBehaviorTest = pkgs.runCommand "test-alfred-profile-list" { } ''
    set -euo pipefail

    test_home="$TMPDIR/home"
    firefox_data="$test_home/Library/Application Support/Firefox"
    mkdir -p "$firefox_data/Profile Groups" \
      "$firefox_data/Profiles/Work Profile" \
      "$firefox_data/Profiles/personal"

    cat > "$firefox_data/profiles.ini" <<'EOF'
    [General]
    Version=2

    [Profile0]
    Name=default-release
    IsRelative=1
    Path=Profiles/Work Profile
    StoreID=4ec43ac3
    EOF

    "${pkgs.sqlite}/bin/sqlite3" "$firefox_data/Profile Groups/4ec43ac3.sqlite" <<'SQL'
    CREATE TABLE Profiles (
      id INTEGER PRIMARY KEY,
      path TEXT NOT NULL,
      name TEXT NOT NULL
    );
    INSERT INTO Profiles VALUES
      (1, 'Profiles/Work Profile', 'work'),
      (2, 'Profiles/personal', 'personal');
    SQL

    output="$(HOME="$test_home" FF_SQLITE3_BINARY="${pkgs.sqlite}/bin/sqlite3" ${pkgs.zsh}/bin/zsh ${listScriptPath})"
    printf '%s\n' "$output"
    grep -Fq '"title":"work"' <<<"$output"
    grep -Fq '"title":"personal"' <<<"$output"
    grep -Fq "\"arg\":\"$firefox_data/Profiles/Work Profile\"" <<<"$output"
    ! grep -Fq 'default-release' <<<"$output"

    legacy_home="$TMPDIR/legacy-home"
    legacy_data="$legacy_home/Library/Application Support/Firefox"
    mkdir -p "$legacy_data/Profiles/legacy"
    cat > "$legacy_data/profiles.ini" <<'EOF'
    [General]
    Version=2

    [Profile0]
    Name=legacy profile
    IsRelative=1
    Path=Profiles/legacy
    StoreID=missing
    EOF

    legacy_output="$(HOME="$legacy_home" FF_SQLITE3_BINARY="${pkgs.sqlite}/bin/sqlite3" ${pkgs.zsh}/bin/zsh ${listScriptPath})"
    printf '%s\n' "$legacy_output"
    grep -Fq '"title":"legacy profile"' <<<"$legacy_output"

    touch "$out"
  '';

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "alfred" [
    profileListBehaviorTest

    (helpers.assertTest "alfred-module-exists" moduleExists
      "users/shared/programs/alfred.nix must exist"
    )

    (helpers.assertTest "workflow-directory-exists" (
      workflowsExist && firefoxWorkflowExists && workflowEntries == [ "firefox-profiles" ]
    ) "the Alfred workflows directory must discover the firefox-profiles workflow")

    (helpers.assertTest "workflow-scripts-exist" (
      builtins.pathExists listScriptPath && builtins.pathExists openScriptPath
    ) "the Firefox Alfred workflow must contain both executable scripts")

    (helpers.assertTest "open-script-uses-profile-path" (
      lib.hasInfix "--no-remote" openScriptText && lib.hasInfix "--profile" openScriptText
    ) "the launcher must pass the selected profile path to Firefox")

    (helpers.assertTest "info-plist-has-script-filter" (
      lib.hasInfix "alfred.workflow.input.scriptfilter" infoText
      && lib.hasInfix "<string>ff</string>" infoText
      && lib.hasInfix "list-profiles.zsh" infoText
    ) "info.plist must expose the ff Script Filter and its external script")

    (helpers.assertTest "info-plist-connects-run-script" (
      lib.hasInfix "alfred.workflow.action.script" infoText
      && lib.hasInfix "open-profile.zsh" infoText
      && lib.hasInfix "destinationuid" infoText
    ) "info.plist must connect the selected profile to the Run Script action")

    (helpers.assertTest "runtime-prefs-are-not-source" (
      !(builtins.pathExists (firefoxWorkflowPath + "/prefs.plist"))
    ) "prefs.plist is Alfred runtime state and must stay outside the repository")

    (helpers.assertTest "alfred-default-enabled-on-darwin" (
      defaultEvaluation.success && defaultHome.config.modules.programs.alfred.enable == true
    ) "Alfred should default to enabled on Darwin")

    (helpers.assertTest "workflow-is-recursively-linked" (
      defaultEvaluation.success
      && defaultFiles ? ${defaultWorkflowTarget}
      && defaultWorkflowFile.recursive == true
      && lib.hasInfix "/users/shared/programs/.config/alfred/workflows/firefox-profiles" (
        builtins.toString defaultWorkflowFile.source
      )
    ) "each discovered workflow should use a recursive source link")

    (helpers.assertTest "preferences-path-is-overridable" (
      syncedEvaluation.success && syncedFiles ? ${syncedWorkflowTarget}
    ) "Alfred sync paths should be configurable without changing the workflow source")
  ];
}
