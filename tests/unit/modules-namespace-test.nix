# modules-namespace-test.nix
# Verifies that all 21 program/package modules declare their enable option
# under modules.programs.<name>.enable or modules.packages.<name>.enable.
#
# Strategy: lib.evalModules with _module.check = false to allow home-manager
# option assignments without pulling in the full home-manager module tree.

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  evalModule =
    modulePath:
    lib.evalModules {
      modules = [
        modulePath
        {
          _module.args = {
            inherit pkgs;
            currentSystemUser = "testuser";
            isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
          };
          _module.check = false;
        }
      ];
    };

  hasEnableOption =
    category: name: modulePath:
    let
      m = evalModule modulePath;
      opts = m.options;
    in
    (opts ? modules)
    && (opts.modules ? ${category})
    && (opts.modules.${category} ? ${name})
    && (opts.modules.${category}.${name} ? enable);

  programNames = [
    "git"
    "vim"
    "zsh"
    "tmux"
    "starship"
    "claude-code"
    "codex"
    "opencode"
    "ghostty"
    "hammerspoon"
    "karabiner"
  ];

  packageNames = [
    "core"
    "dev"
    "lsp"
    "nix-tools"
    "cloud"
    "security"
    "ssh"
    "media"
    "fonts"
    "databases"
    "ai"
  ];

  programModulePath =
    name:
    if name == "zsh" then
      ../../users/shared/programs/zsh
    else
      ../../users/shared/programs/${name}.nix;

  packageModulePath = name: ../../users/shared/packages/${name}.nix;

  programTests = lib.listToAttrs (
    map (n: {
      name = "program-${n}-has-enable";
      value = helpers.assertTest "modules.programs.${n}.enable" (
        hasEnableOption "programs" n (programModulePath n)
      ) "Module users/shared/programs/${n}.nix must declare options.modules.programs.${n}.enable";
    }) programNames
  );

  packageTests = lib.listToAttrs (
    map (n: {
      name = "package-${n}-has-enable";
      value = helpers.assertTest "modules.packages.${n}.enable" (
        hasEnableOption "packages" n (packageModulePath n)
      ) "Module users/shared/packages/${n}.nix must declare options.modules.packages.${n}.enable";
    }) packageNames
  );

in
{
  platforms = [ "any" ];
  value = programTests // packageTests;
}
