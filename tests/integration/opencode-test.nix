# OpenCode Configuration Integration Test
#
# Tests the OpenCode configuration in users/shared/opencode.nix
# Verifies opencode.json configuration.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import opencode module and extract config body via .content
  # (lib.mkIf true {...}).content unwraps the conditional when enable=true
  opencodeModule = import ../../users/shared/programs/opencode.nix {
    inherit pkgs lib;
    config = {
      modules.programs.opencode.enable = true;
    };
  };
  opencodeConfig = opencodeModule.config.content;

  # Extract configuration sections
  xdgConfigFiles = opencodeConfig.xdg.configFile or { };

  # Test if opencode.json is configured via xdg.configFile
  hasOpencodeJson = builtins.hasAttr "opencode/opencode.json" xdgConfigFiles;

  # Extract the generated JSON text
  opencodeJsonText = xdgConfigFiles."opencode/opencode.json".text or "";

  # Parse and validate JSON content
  opencodeJsonParsed = builtins.tryEval (builtins.fromJSON opencodeJsonText);
  hasValidJson = opencodeJsonParsed.success;
  hasSchemaField = opencodeJsonParsed.success && builtins.hasAttr "$schema" opencodeJsonParsed.value;
  hasPermissionConfig =
    opencodeJsonParsed.success && builtins.hasAttr "permission" opencodeJsonParsed.value;
  hasMcpConfig = opencodeJsonParsed.success && builtins.hasAttr "mcp" opencodeJsonParsed.value;

in
helpers.testSuite "opencode" (
  [
    # Test that xdg.configFile configuration exists
    (helpers.assertTest "xdg-configfile-exists" (
      xdgConfigFiles != null
    ) "xdg.configFile should exist in opencode configuration")
  ]
  # Configuration tests
  ++ [
    (helpers.assertTest "opencode-json-configured" hasOpencodeJson
      "opencode.json should be configured in xdg.configFile"
    )
  ]
  # JSON content validation tests
  ++ [
    (helpers.assertTest "opencode-json-valid" hasValidJson "opencode.json should contain valid JSON")
    (helpers.assertTest "opencode-json-has-schema" hasSchemaField
      "opencode.json should have $schema field"
    )
    (helpers.assertTest "opencode-json-has-permission" hasPermissionConfig
      "opencode.json should have permission configuration"
    )
    (helpers.assertTest "opencode-json-has-mcp" hasMcpConfig
      "opencode.json should have MCP configuration"
    )
  ]
)
