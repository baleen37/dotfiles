# Neru configuration integration tests
# Validates the Home Manager file mapping and the version-controlled TOML.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  moduleResult = builtins.tryEval (
    import ../../users/shared/programs/neru.nix {
      inherit pkgs lib;
      config = {
        modules.programs.neru.enable = true;
      };
    }
  );
  moduleRaw = if moduleResult.success then moduleResult.value else { };
  moduleConfig = if moduleResult.success then moduleRaw.config.content else { };
  homeFiles = moduleConfig.home.file or { };
  configFile = homeFiles.".config/neru/config.toml" or { };
  configSource = ../../users/shared/programs/.config/neru/config.toml;
  sourceResult = builtins.tryEval (builtins.readFile configSource);
  sourceContent = if sourceResult.success then sourceResult.value else "";

  hasHotkey = lib.hasInfix "\"Primary+Shift+Space\" = \"hints\"" sourceContent;
  hasEnabledMode = mode: lib.hasInfix "[${mode}]\nenabled = true" sourceContent;
  hasScrollSettings =
    lib.hasInfix "[scroll]" sourceContent && lib.hasInfix "scroll_step = 50" sourceContent;
  hasCurrentRoleNames =
    lib.hasInfix "\"button\"" sourceContent
    && lib.hasInfix "\"menu_item\"" sourceContent
    && lib.hasInfix "\"ax:AXGenericElement\"" sourceContent;
  lacksLegacyRoleNames = !(lib.hasInfix "\"AXButton\"" sourceContent);
  sourceIsNeruConfig = lib.hasSuffix "/users/shared/programs/.config/neru/config.toml" (
    builtins.toString (configFile.source or "")
  );

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "neru" [
    (helpers.assertTest "neru-module-importable" moduleResult.success "neru.nix should be importable")
    (helpers.assertTest "neru-config-file-present"
      (builtins.hasAttr ".config/neru/config.toml" homeFiles)
      "Neru should expose a Home Manager config file"
    )
    (helpers.assertTest "neru-config-file-forced" (configFile.force or false
    ) "Neru config should use force=true so Home Manager can manage the existing file")
    (helpers.assertTest "neru-config-source" sourceIsNeruConfig
      "Neru config should be sourced from the version-controlled TOML"
    )
    (helpers.assertTest "neru-source-readable" sourceResult.success
      "Neru TOML source should be readable"
    )
    (helpers.assertTest "neru-default-hints-hotkey" hasHotkey
      "Neru should use its default Primary+Shift+Space hints shortcut"
    )
    (helpers.assertTest "neru-hints-enabled" (hasEnabledMode "hints")
      "Neru hints mode should be enabled"
    )
    (helpers.assertTest "neru-grid-enabled" (hasEnabledMode "grid") "Neru grid mode should be enabled")
    (helpers.assertTest "neru-scroll-configured" hasScrollSettings
      "Neru scroll mode should have its vim-style navigation settings"
    )
    (helpers.assertTest "neru-current-role-names" (
      hasCurrentRoleNames && lacksLegacyRoleNames
    ) "Neru hints should use the current semantic accessibility role names")
  ];
}
