{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;

  # Import the files.nix module to test
  mockUser = "testuser";
  mockUserHome = "/home/${mockUser}";
  mockConfig = {
    users.users.${mockUser}.home = mockUserHome;
  };

  # Import the actual files.nix module
  filesModule = import ../../modules/shared/files.nix {
    inherit lib pkgs;
    config = mockConfig;
    user = mockUser;
    self = src;
  };

in
pkgs.runCommand "claude-config-copy-unit-test" { } ''
  echo "=== Claude Config Copy Unit Test ==="

  # Test that CLAUDE.md is generated with text content
  ${if filesModule ? "${mockUserHome}/.claude/CLAUDE.md" &&
       filesModule."${mockUserHome}/.claude/CLAUDE.md" ? text
    then ''echo "✓ CLAUDE.md has text content (not symlink)"''
    else ''echo "✗ CLAUDE.md missing or is symlink"; exit 1''}

  # Test that settings.json is generated with text content
  ${if filesModule ? "${mockUserHome}/.claude/settings.json" &&
       filesModule."${mockUserHome}/.claude/settings.json" ? text
    then ''echo "✓ settings.json has text content (not symlink)"''
    else ''echo "✗ settings.json missing or is symlink"; exit 1''}

  # Test that command files are generated
  ${let
    commandFiles = lib.filterAttrs (path: value:
      lib.hasPrefix "${mockUserHome}/.claude/commands/" path &&
      lib.hasSuffix ".md" path &&
      value ? text
    ) filesModule;
    commandCount = builtins.length (lib.attrNames commandFiles);
  in
    if commandCount >= 3 then ''echo "✓ Found ${toString commandCount} command files with text content"''
    else ''echo "✗ Expected at least 3 command files, found ${toString commandCount}"; exit 1''
  }

  # Test that gitconfig is included
  ${if filesModule ? "${mockUserHome}/.gitconfig_global"
    then ''echo "✓ gitconfig_global is included"''
    else ''echo "✗ gitconfig_global missing"; exit 1''}

  echo "All tests passed!"
  touch $out
''
