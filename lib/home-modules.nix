# Home Manager modules under users/shared/{programs,packages}, discovered from
# the directory layout so adding a tool is one file.
#
# A module is `<name>.nix` or a `<name>/` directory with a `default.nix`; it
# declares `options.modules.<category>.<name>.enable`. Hidden entries
# (`.config/`) and non-Nix assets (`*.sh`, `*.vim`) are skipped. Helper files a
# module imports itself belong inside that module's directory (see `zsh/`).
#
# Returns `{ programs = { <name> = <path>; }; packages = { ... }; }`.
{ lib }:

let
  discover =
    dir:
    lib.concatMapAttrs (
      entry: type:
      if lib.hasPrefix "." entry then
        { }
      else if type == "regular" && lib.hasSuffix ".nix" entry then
        { ${lib.removeSuffix ".nix" entry} = dir + "/${entry}"; }
      else if type == "directory" && builtins.pathExists (dir + "/${entry}/default.nix") then
        { ${entry} = dir + "/${entry}"; }
      else
        { }
    ) (builtins.readDir dir);
in
{
  programs = discover ../users/shared/programs;
  packages = discover ../users/shared/packages;
}
