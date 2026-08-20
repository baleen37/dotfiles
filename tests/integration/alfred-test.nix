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

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "alfred" [
    (helpers.assertTest "alfred-module-exists" moduleExists
      "users/shared/programs/alfred.nix must exist"
    )

    (helpers.assertTest "workflow-directory-exists" (
      workflowsExist && firefoxWorkflowExists && workflowEntries == [ "firefox-profiles" ]
    ) "the Alfred workflows directory must discover the firefox-profiles workflow")

    (helpers.assertTest "workflow-scripts-exist" (
      builtins.pathExists listScriptPath && builtins.pathExists openScriptPath
    ) "the Firefox Alfred workflow must contain both executable scripts")

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
