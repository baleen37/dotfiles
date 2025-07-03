# Platform application definitions module
# Provides common app builders for Darwin and Linux systems

{ nixpkgs, self }:

let
  # Import sudo-helper utilities
  sudoHelperLib = import (self + "/lib/sudo-helper.nix");
  # Generic app builder that wraps platform-specific scripts
  mkApp = scriptName: system: {
    type = "app";
    program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
      #!/usr/bin/env bash
      PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
      echo "Running ${scriptName} for ${system}"
      exec ${self}/apps/${system}/${scriptName} "$@"
    '')}/bin/${scriptName}";
  };

  # Setup-dev app builder with fallback handling
  mkSetupDevApp = system:
    if builtins.pathExists (self + "/scripts/setup-dev")
    then {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "setup-dev"
        (builtins.readFile (self + "/scripts/setup-dev"))
      )}/bin/setup-dev";
    }
    else {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "setup-dev" ''
        #!/usr/bin/env bash
        echo "setup-dev script not found. Please run: ./scripts/install-setup-dev"
        exit 1
      '')}/bin/setup-dev";
    };

  # Sudo helper app builder
  mkSudoHelperApp = system: {
    type = "app";
    program = "${(sudoHelperLib { inherit nixpkgs system; }).sudoHelper}/bin/sudo-helper";
  };

  # BL auto-update command builders
  mkBlAutoUpdateApp = { system, commandName }:
    let
      scriptPath = self + "/scripts/bl-auto-update-${commandName}";
    in
    if builtins.pathExists scriptPath
    then {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "bl-auto-update-${commandName}"
        (builtins.readFile scriptPath)
      )}/bin/bl-auto-update-${commandName}";
    }
    else {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "bl-auto-update-${commandName}" ''
        #!/usr/bin/env bash
        echo "bl-auto-update-${commandName} script not found at: ${scriptPath}"
        exit 1
      '')}/bin/bl-auto-update-${commandName}";
    };

  # Core apps available on all platforms
  coreApps = [
    "apply"
    "build"
    "build-switch"
  ];

  # SSH key management apps
  sshApps = [
    "copy-keys"
    "create-keys"
    "check-keys"
  ];

  # Linux-specific apps
  linuxOnlyApps = [
    "install"
  ];

  # Darwin-specific apps
  darwinOnlyApps = [
    "rollback"
  ];

  # Build app set for a system
  mkAppSet = { system, includeApps }:
    nixpkgs.lib.genAttrs includeApps (appName: mkApp appName system);

in
{
  # Build Linux apps (core + SSH + linux-specific)
  mkLinuxCoreApps = system:
    mkAppSet
      {
        inherit system;
        includeApps = coreApps ++ sshApps ++ linuxOnlyApps;
      } // {
      "setup-dev" = mkSetupDevApp system;
      "sudo-helper" = mkSudoHelperApp system;
      "bl-auto-update-status" = mkBlAutoUpdateApp { inherit system; commandName = "status"; };
      "bl-auto-update-check" = mkBlAutoUpdateApp { inherit system; commandName = "check"; };
      "bl-auto-update-apply" = mkBlAutoUpdateApp { inherit system; commandName = "apply"; };
    };

  # Build Darwin apps (core + SSH + darwin-specific)
  mkDarwinCoreApps = system:
    mkAppSet
      {
        inherit system;
        includeApps = coreApps ++ sshApps ++ darwinOnlyApps;
      } // {
      "setup-dev" = mkSetupDevApp system;
      "sudo-helper" = mkSudoHelperApp system;
      "bl-auto-update-status" = mkBlAutoUpdateApp { inherit system; commandName = "status"; };
      "bl-auto-update-check" = mkBlAutoUpdateApp { inherit system; commandName = "check"; };
      "bl-auto-update-apply" = mkBlAutoUpdateApp { inherit system; commandName = "apply"; };
    };

  # Export for potential reuse
  inherit mkApp mkSetupDevApp mkSudoHelperApp mkBlAutoUpdateApp;
}
