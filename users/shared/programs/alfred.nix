# Alfred workflow configuration.
#
# Only workflow source directories are managed here. Alfred owns the surrounding
# preferences directory and writes runtime state such as prefs.plist itself.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.alfred;
  workflowRoot = ./.config/alfred/workflows;
  workflowDirectories = lib.filterAttrs (_name: fileType: fileType == "directory") (
    builtins.readDir workflowRoot
  );
  workflowFiles = lib.mapAttrs' (
    name: _fileType:
    lib.nameValuePair "${cfg.preferencesPath}/workflows/${name}" {
      source = workflowRoot + "/${name}";
      recursive = true;
    }
  ) workflowDirectories;
in
{
  options.modules.programs.alfred = {
    enable = lib.mkEnableOption "Alfred workflows" // {
      default = pkgs.stdenv.hostPlatform.isDarwin;
    };

    preferencesPath = lib.mkOption {
      type = lib.types.str;
      default = "Library/Application Support/Alfred/Alfred.alfredpreferences";
      example = "Dropbox/Alfred/Alfred.alfredpreferences";
      description = ''
        Alfred.alfredpreferences path relative to the home directory.
        Set this when Alfred preferences are synced somewhere other than the
        default local path.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = workflowFiles;
  };
}
