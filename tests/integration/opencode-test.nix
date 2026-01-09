# OpenCode Configuration Integration Test
#
# Tests the OpenCode configuration in users/shared/opencode.nix
# Verifies AGENTS.md symlink, commands directory sharing, and force settings.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  ...
} @ args:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import opencode configuration
  opencodeConfig = import ../../users/shared/opencode.nix {
    inherit pkgs lib;
    config = { };
  };

  # Extract home.file configuration
  homeFiles = opencodeConfig.home.file;

  # Test if AGENTS.md file is configured
  hasAgentsMd = builtins.hasAttr ".config/opencode/AGENTS.md" homeFiles;

  # Generic helper to extract a boolean attribute from home.file configuration
  # Usage: getFileBoolAttr "force" ".config/opencode/AGENTS.md" -> true/false
  getFileBoolAttr = attrName: fileAttr:
    builtins.hasAttr fileAttr homeFiles && homeFiles.${fileAttr}.${attrName} or false;

  # Shorthand helpers for common attributes
  hasForceEnabled = getFileBoolAttr "force";
  isRecursive = getFileBoolAttr "recursive";

  # Source paths for behavioral tests
  opencodeConfigDir = ../../users/shared/.config/opencode;
  agentsMdSource = opencodeConfigDir + "/AGENTS.md";

  # Check readability of source files/directories
  # AGENTS.md is a file
  agentsMdReadable = builtins.tryEval (builtins.readFile agentsMdSource);

  # Helper to create readable and has-content tests for a source
  # Usage: makeSourceTests "agents-md" agentsMdReadable isDirectory -> [readableTest, hasContentTest]
  makeSourceTests =
    name: readableResult: isDirectory:
    let
      hasContent =
        if isDirectory then
          readableResult.success && builtins.length (builtins.attrNames readableResult.value) > 0
        else
          readableResult.success && builtins.stringLength readableResult.value > 0;
    in
    [
      (helpers.assertTest "${name}-source-readable" readableResult.success
        "${name} source should be readable")
      (helpers.assertTest "${name}-source-has-content" hasContent
        "${name} source should have content")
    ];

in
helpers.testSuite "opencode" (
  [
    # Test that home.file configuration exists
    (helpers.assertTest "home-file-exists" (homeFiles != null)
      "home.file should exist in opencode configuration")
  ]
  # Configuration tests using helpers.assertHasAttr pattern
  ++ [
    (helpers.assertTest "agents-md-configured" hasAgentsMd
      "AGENTS.md should be configured in home.file")
  ]
  # Force and recursive attribute tests
  ++ [
    (helpers.assertTest "agents-md-force-enabled" (hasForceEnabled ".config/opencode/AGENTS.md")
      "AGENTS.md should have force=true to overwrite existing files")
  ]
  # Behavioral tests for source files using helper
  ++ (makeSourceTests "agents-md" agentsMdReadable false)
)
