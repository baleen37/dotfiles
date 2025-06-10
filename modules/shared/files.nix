{ pkgs, config, user, self, lib, ... }:

let
  userHome = if pkgs.stdenv.isDarwin 
    then config.users.users.${user}.home or "/Users/${user}"
    else builtins.getEnv "HOME";

  # Generate file entries for all markdown files in commands directory
  mkCommandFiles = dir:
    let files = builtins.readDir dir;
    in lib.concatMapAttrs (name: type:
      if type == "regular" && lib.hasSuffix ".md" name
      then { "${userHome}/.claude/commands/${name}".text = builtins.readFile (dir + "/${name}"); }
      else {}
    ) files;

in
{
  # Claude configuration files
  "${userHome}/.claude/CLAUDE.md".text = builtins.readFile ./config/claude/CLAUDE.md;
  "${userHome}/.claude/settings.json".text = builtins.readFile ./config/claude/settings.json;
  "${userHome}/.gitconfig_global".text = "";
} // mkCommandFiles ./config/claude/commands

