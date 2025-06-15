# Platform application definitions module
# Provides common app builders for Darwin and Linux systems

{ nixpkgs, self }:

let
  # Generic app builder that wraps platform-specific scripts
  mkApp = scriptName: system: {
    type = "app";
    program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
      #!/usr/bin/env bash
      PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
      echo "Running ${scriptName} for ${system}"
      exec ${self}/apps/${system}/${scriptName}
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
    mkAppSet { 
      inherit system; 
      includeApps = coreApps ++ sshApps ++ linuxOnlyApps; 
    } // {
      "setup-dev" = mkSetupDevApp system;
    };

  # Build Darwin apps (core + SSH + darwin-specific)
  mkDarwinCoreApps = system: 
    mkAppSet { 
      inherit system; 
      includeApps = coreApps ++ sshApps ++ darwinOnlyApps; 
    } // {
      "setup-dev" = mkSetupDevApp system;
    };

  # Export for potential reuse
  inherit mkApp mkSetupDevApp;
}