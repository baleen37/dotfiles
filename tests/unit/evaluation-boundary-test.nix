{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  flakeSource = builtins.readFile ../../flake.nix;
  argsSource = builtins.readFile ../../flake-modules/args.nix;
  makeSource = builtins.readFile ../../Makefile;
  envrcSource = builtins.readFile ../../.envrc;
  ciSource = builtins.readFile ../../.github/workflows/ci.yml;

  # Every .nix file the flake evaluates. docs/ holds historical plans, not code.
  nixSources =
    lib.concatMap (dir: lib.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive dir))
      [
        ../../flake-modules
        ../../lib
        ../../machines
        ../../tests
        ../../users
      ];
  # Split so this file does not match itself.
  channelLookup = "<" + "nixpkgs";
  channelLookups = lib.filter (file: lib.hasInfix channelLookup (builtins.readFile file)) nixSources;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "evaluation-boundary" [
    (helpers.assertTest "intel-darwin-absent" (
      !(lib.hasInfix "x86_64-darwin" flakeSource)
    ) "Intel Darwin is removed")
    (helpers.assertTest "no-flake-user-read" (
      !(lib.hasInfix "builtins.getEnv" flakeSource) && !(lib.hasInfix "builtins.getEnv" argsSource)
    ) "flake is pure")
    (helpers.assertTest "no-user-injection" (
      !(lib.hasInfix "export USER=" makeSource)
      && !(lib.hasInfix "export USER=" envrcSource)
      && !(lib.hasInfix "export USER=" ciSource)
    ) "workflow does not inject USER")
    (helpers.assertTest "no-channel-lookup" (
      channelLookups == [ ]
    ) "channel lookups resolve through NIX_PATH, bypassing flake.lock: ${toString channelLookups}")
  ];
}
