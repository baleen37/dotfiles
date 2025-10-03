# Simplified Config Validation System
# Provides basic type validation for configuration files
{ lib }:

let
  inherit (lib) types;
  inherit (lib.attrsets) hasAttr getAttr mapAttrs;
  inherit (lib.lists) isList length elem;
  inherit (lib.strings) isString;
  inherit (builtins)
    isInt
    isBool
    isFloat
    typeOf
    ;

  # Available config types
  availableTypes = [
    "platforms"
    "cache"
    "network"
    "performance"
    "security"
  ];

  # Basic type validation
  validateType =
    expected: value:
    if expected == "string" then
      isString value
    else if expected == "int" then
      isInt value
    else if expected == "bool" then
      isBool value
    else if expected == "list" then
      isList value
    else if expected == "attrset" then
      lib.isAttrs value
    else
      true; # Default to valid for unknown types

  # Validate a configuration against basic constraints
  validateBasicConfig =
    configType: config:
    let
      # Basic structural checks for each config type
      platformsValid =
        configType != "platforms"
        || (lib.isAttrs config && hasAttr "platforms" config && hasAttr "system_detection" config);

      cacheValid = configType != "cache" || (lib.isAttrs config && hasAttr "cache" config);

      networkValid = configType != "network" || (lib.isAttrs config && hasAttr "network" config);

      performanceValid =
        configType != "performance" || (lib.isAttrs config && hasAttr "performance" config);

      securityValid = configType != "security" || (lib.isAttrs config && hasAttr "security" config);

      allValid = platformsValid && cacheValid && networkValid && performanceValid && securityValid;

      errors = lib.concatLists [
        (lib.optional (!platformsValid) "Invalid platforms config structure")
        (lib.optional (!cacheValid) "Invalid cache config structure")
        (lib.optional (!networkValid) "Invalid network config structure")
        (lib.optional (!performanceValid) "Invalid performance config structure")
        (lib.optional (!securityValid) "Invalid security config structure")
      ];
    in
    {
      valid = allValid;
      inherit errors;
    };

in
{
  # Main validation function - simplified version
  validateConfig = configType: config: validateBasicConfig configType config;

  # Validate all config types
  validateAllConfigs =
    configs:
    let
      validations = mapAttrs (configType: config: validateBasicConfig configType config) configs;

      allValid = lib.all (result: result.valid) (lib.attrValues validations);
      allErrors = lib.concatLists (map (result: result.errors) (lib.attrValues validations));
    in
    {
      valid = allValid;
      errors = allErrors;
      details = validations;
    };

  # Get schema for a config type (placeholder)
  getSchema =
    configType:
    if elem configType availableTypes then
      {
        type = "attrset";
        description = "Configuration for ${configType}";
      }
    else
      null;

  # List all available schema types
  inherit availableTypes;
}
