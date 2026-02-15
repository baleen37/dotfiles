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

  # Extract configuration sections
  homeFiles = opencodeConfig.home.file or { };
  xdgConfigFiles = opencodeConfig.xdg.configFile or { };

  # Test if opencode.json is configured via xdg.configFile
  hasOpencodeJson = builtins.hasAttr "opencode/opencode.json" xdgConfigFiles;

  # Extract the generated JSON text
  opencodeJsonText = xdgConfigFiles."opencode/opencode.json".text or "";

  # Parse and validate JSON content
  opencodeJsonParsed = builtins.tryEval (builtins.fromJSON opencodeJsonText);
  hasValidJson = opencodeJsonParsed.success;
  hasSchemaField =
    opencodeJsonParsed.success
    && builtins.hasAttr "$schema" opencodeJsonParsed.value;
  hasPermissionConfig =
    opencodeJsonParsed.success
    && builtins.hasAttr "permission" opencodeJsonParsed.value;
  hasMcpConfig =
    opencodeJsonParsed.success
    && builtins.hasAttr "mcp" opencodeJsonParsed.value;

  requiredAgentNames = [
    "codemap"
    "designer"
    "explorer"
    "fixer"
    "librarian"
    "oracle"
    "orchestrator"
  ];

  # Agent directory tests
  hasAgentDir = builtins.hasAttr "opencode/agent" xdgConfigFiles;
  hasAgentDirRecursiveEnabled =
    builtins.hasAttr "opencode/agent" xdgConfigFiles
    && xdgConfigFiles."opencode/agent".recursive or false;

  opencodeAgentDir = ../../users/shared/.config/opencode/agent;

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

in
helpers.testSuite "opencode" (
  [
    # Test that xdg.configFile configuration exists
    (helpers.assertTest "xdg-configfile-exists" (xdgConfigFiles != null)
      "xdg.configFile should exist in opencode configuration")
  ]
  # Configuration tests
  ++ [
    (helpers.assertTest "opencode-json-configured" hasOpencodeJson
      "opencode.json should be configured in xdg.configFile")
  ]
  # JSON content validation tests
  ++ [
    (helpers.assertTest "opencode-json-valid" hasValidJson
      "opencode.json should contain valid JSON")
    (helpers.assertTest "opencode-json-has-schema" hasSchemaField
      "opencode.json should have $schema field")
    (helpers.assertTest "opencode-json-has-permission" hasPermissionConfig
      "opencode.json should have permission configuration")
    (helpers.assertTest "opencode-json-has-mcp" hasMcpConfig
      "opencode.json should have MCP configuration")
  ]
  # Agent directory configuration tests
  ++ [
    (helpers.assertTest "opencode-agent-dir-configured" hasAgentDir
      "opencode agent directory should be configured in xdg.configFile")
    (helpers.assertTest "opencode-agent-dir-recursive-enabled" hasAgentDirRecursiveEnabled
      "opencode agent directory should have recursive=true")
  ]
  # Agent source file tests
  ++ (lib.flatten (map makeAgentSourceTests requiredAgentNames))
)
