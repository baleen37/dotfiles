# WSL Configuration Test
# Tests that machines/wsl.nix follows proper NixOS module structure and contains required WSL settings

{ inputs, system, pkgs ? import inputs.nixpkgs { inherit system; }, lib ? pkgs.lib, ... }:

# WSL configuration tests are relevant for Linux platforms only
let
  testHelpers = import ./lib/test-helpers.nix { inherit pkgs lib; };
  helpers = import ./lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Import the WSL configuration to test its structure
  wslModule = import ../machines/wsl.nix;

in
{
  platforms = ["linux"];
  test = testHelpers.testSuite "wsl-configuration" [
  # Test 1: Verify WSL module is a proper function that accepts config, pkgs, lib parameters
  (helpers.assertTestWithDetails "wsl-module-is-function"
    (lib.isFunction wslModule)
    "WSL module should be a function that accepts config, pkgs, lib parameters"
    "function"
    (if lib.isFunction wslModule then "function" else "not a function")
    null
    null
  )

  # Test 2: Verify WSL module evaluation succeeds with proper parameters
  (helpers.assertTestWithDetails "wsl-module-evaluates-successfully"
    (builtins.isAttrs (wslModule { config = {}; pkgs = pkgs; lib = lib; inherit inputs; }))
    "WSL module should evaluate successfully with config, pkgs, lib, inputs parameters"
    "attrs"
    (if builtins.isAttrs (wslModule { config = {}; pkgs = pkgs; lib = lib; inherit inputs; }) then "attrs" else "not attrs")
    null
    null
  )

  # Test 3: Verify WSL configuration contains required WSL settings
  (let
    evaluatedConfig = wslModule { config = {}; pkgs = pkgs; lib = lib; inherit inputs; };
  in
  helpers.assertTestWithDetails "wsl-configuration-has-wsl-settings"
    (builtins.hasAttr "wsl" evaluatedConfig && evaluatedConfig.wsl.enable == true)
    "WSL configuration should have wsl.enable = true"
    "wsl.enable = true"
    (if builtins.hasAttr "wsl" evaluatedConfig
     then "wsl.enable = ${toString evaluatedConfig.wsl.enable}"
     else "no wsl attribute")
    null
    null
  )

  # Test 4: Verify WSL configuration has systemd performance optimizations
  (let
    evaluatedConfig = wslModule { config = {}; pkgs = pkgs; lib = lib; inherit inputs; };
  in
  helpers.assertTestWithDetails "wsl-configuration-has-systemd-config"
    (builtins.hasAttr "systemd" evaluatedConfig &&
     builtins.hasAttr "extraConfig" evaluatedConfig.systemd &&
     builtins.isString evaluatedConfig.systemd.extraConfig)
    "WSL configuration should have systemd performance optimizations"
    "systemd.extraConfig with performance settings"
    (if builtins.hasAttr "systemd" evaluatedConfig
     then if builtins.hasAttr "extraConfig" evaluatedConfig.systemd
          then "systemd.extraConfig exists"
          else "no systemd.extraConfig"
     else "no systemd attribute")
    null
    null
  )

  # Test 5: Verify WSL configuration has Windows interoperability settings
  (let
    evaluatedConfig = wslModule { config = {}; pkgs = pkgs; lib = lib; inherit inputs; };
  in
  helpers.assertTestWithDetails "wsl-configuration-has-windows-interop"
    (builtins.hasAttr "environment" evaluatedConfig &&
     builtins.hasAttr "variables" evaluatedConfig.environment &&
     builtins.hasAttr "WSLENV" evaluatedConfig.environment.variables)
    "WSL configuration should have Windows interoperability environment variables"
    "environment.variables.WSLENV set"
    (if builtins.hasAttr "environment" evaluatedConfig
     then if builtins.hasAttr "variables" evaluatedConfig.environment
          then if builtins.hasAttr "WSLENV" evaluatedConfig.environment.variables
               then "WSLENV exists"
               else "no WSLENV variable"
          else "no environment.variables"
     else "no environment attribute")
    null
    null
  )

  # Test 6: Verify WSL configuration enables essential services
  (let
    evaluatedConfig = wslModule { config = {}; pkgs = pkgs; lib = lib; inherit inputs; };
  in
  helpers.assertTestWithDetails "wsl-configuration-has-essential-services"
    (builtins.hasAttr "services" evaluatedConfig &&
     builtins.hasAttr "sshd" evaluatedConfig.services &&
     evaluatedConfig.services.sshd.enable == true)
    "WSL configuration should enable essential services like SSH"
    "services.sshd.enable = true"
    (if builtins.hasAttr "services" evaluatedConfig
     then if builtins.hasAttr "sshd" evaluatedConfig.services
          then "services.sshd.enable = ${toString evaluatedConfig.services.sshd.enable}"
          else "no sshd service"
     else "no services attribute")
    null
    null
  )
  ];
}