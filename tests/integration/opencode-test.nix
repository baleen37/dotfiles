# OpenCode Configuration Integration Test
#
# Tests the OpenCode configuration in users/shared/opencode.nix
# Verifies opencode.json configuration.
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

  # Test if opencode.json file is configured
  hasOpencodeJson = builtins.hasAttr ".config/opencode/opencode.json" homeFiles;

  # Generic helper to extract a boolean attribute from home.file configuration
  # Usage: getFileBoolAttr "force" ".config/opencode/opencode.json" -> true/false
  getFileBoolAttr = attrName: fileAttr:
    builtins.hasAttr fileAttr homeFiles && homeFiles.${fileAttr}.${attrName} or false;

  # Shorthand helpers for common attributes
  hasForceEnabled = getFileBoolAttr "force";

  # Source paths for behavioral tests
  opencodeConfigDir = ../../users/shared/.config/opencode;
  opencodeJsonSource = opencodeConfigDir + "/opencode.json";

  # Check readability of source files
  opencodeJsonReadable = builtins.tryEval (builtins.readFile opencodeJsonSource);

  requiredAgentNames = [
    "sisyphus"
    "prometheus"
    "oracle"
    "librarian"
    "explore"
    "multimodal-looker"
    "metis"
    "momus"
  ];

  hasAgentDir = builtins.hasAttr ".config/opencode/agent" homeFiles;
  hasAgentDirForceEnabled = getFileBoolAttr "force" ".config/opencode/agent";
  hasAgentDirRecursiveEnabled = getFileBoolAttr "recursive" ".config/opencode/agent";

  opencodeAgentDir = opencodeConfigDir + "/agent";

  agentFileReadable =
    agentName:
    builtins.tryEval (builtins.readFile (opencodeAgentDir + "/${agentName}.md"));

  makeAgentSourceTests =
    agentName:
    let
      readableResult = agentFileReadable agentName;
      hasContent = readableResult.success && builtins.stringLength readableResult.value > 0;
    in
    [
      (helpers.assertTest "opencode-agent-${agentName}-source-readable" readableResult.success
        "${agentName}.md source should be readable")
      (helpers.assertTest "opencode-agent-${agentName}-source-has-content" hasContent
        "${agentName}.md source should have content")
    ];

  # Helper to create readable and has-content tests for a source
  makeSourceTests =
    name: readableResult:
    let
      hasContent = readableResult.success && builtins.stringLength readableResult.value > 0;
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
  # Configuration tests
  ++ [
    (helpers.assertTest "opencode-json-configured" hasOpencodeJson
      "opencode.json should be configured in home.file")
  ]
  # Force attribute tests
  ++ [
    (helpers.assertTest "opencode-json-force-enabled" (hasForceEnabled ".config/opencode/opencode.json")
      "opencode.json should have force=true to overwrite existing files")
  ]
  # Behavioral tests for source files
  ++ (makeSourceTests "opencode-json" opencodeJsonReadable)
  # Agent directory configuration tests
  ++ [
    (helpers.assertTest "opencode-agent-dir-configured" hasAgentDir
      "opencode agent directory should be configured in home.file")
    (helpers.assertTest "opencode-agent-dir-force-enabled" hasAgentDirForceEnabled
      "opencode agent directory should have force=true")
    (helpers.assertTest "opencode-agent-dir-recursive-enabled" hasAgentDirRecursiveEnabled
      "opencode agent directory should have recursive=true")
  ]
  # Agent source file tests
  ++ (lib.flatten (map makeAgentSourceTests requiredAgentNames))
)
