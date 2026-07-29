# tests/unit/claude-test.nix
#
# Covers the payload users/shared/programs/claude-code.nix deploys into
# ~/.claude. The files are read at eval time, so a malformed settings.json or a
# CLAUDE.md that got truncated fails here rather than at activation.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  claudeDir = ../../users/shared/programs/.config/claude;
  claudeCodeModule = builtins.readFile ../../users/shared/programs/claude-code.nix;

  settingsPath = claudeDir + "/settings.json";
  settings = builtins.tryEval (builtins.fromJSON (builtins.readFile settingsPath));
  claudeMd = builtins.readFile (claudeDir + "/CLAUDE.md");
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "claude" [
    (helpers.assertTest "settings-json-parses" (
      settings.success && builtins.attrNames settings.value != [ ]
    ) "users/shared/programs/.config/claude/settings.json must be non-empty valid JSON")

    # A heading means the file survived generation; a stub would fail the length
    # check and a stray plain-text file would fail this one.
    (helpers.assertTest "claude-md-has-content" (
      builtins.stringLength claudeMd > 100 && lib.hasInfix "#" claudeMd
    ) "CLAUDE.md must carry real markdown content, not a stub")

    # CLAUDE.md is the declarative instruction source, so activation has to
    # overwrite whatever is already in ~/.claude instead of skipping it.
    (helpers.assertTest "claude-md-refreshes-on-switch" (
      lib.hasInfix "run cp \${src}/CLAUDE.md ~/.claude/CLAUDE.md" claudeCodeModule
    ) "claude-code.nix should overwrite ~/.claude/CLAUDE.md during activation")
  ];
}
