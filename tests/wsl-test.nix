# WSL Configuration Test
# Tests that machines/wsl.nix follows proper NixOS module structure and contains required WSL settings

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

# WSL configuration tests are relevant for Linux platforms only
let
  testHelpers = import ./lib/test-helpers.nix { inherit pkgs lib; };
  helpers = import ./lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Import the WSL configuration to test its structure
  wslModule = import ../machines/wsl.nix;

in
{
  platforms = [ "linux" ];
  test = testHelpers.testSuite "wsl-configuration" [
    # Test 1: Verify WSL module is a proper function that accepts config, pkgs, lib parameters
    (helpers.assertTestWithDetails "wsl-module-is-function" (lib.isFunction wslModule)
      "WSL module should be a function that accepts config, pkgs, lib parameters"
      "function"
      (if lib.isFunction wslModule then "function" else "not a function")
      null
      null
    )

    # Test 2: Verify WSL module evaluation succeeds with proper parameters
    (helpers.assertTestWithDetails "wsl-module-evaluates-successfully"
      (builtins.isAttrs (wslModule {
        config = { };
        pkgs = pkgs;
        lib = lib;
        inherit inputs;
      }))
      "WSL module should evaluate successfully with config, pkgs, lib, inputs parameters"
      "attrs"
      (
        if
          builtins.isAttrs (wslModule {
            config = { };
            pkgs = pkgs;
            lib = lib;
            inherit inputs;
          })
        then
          "attrs"
        else
          "not attrs"
      )
      null
      null
    )

    # Test 3: Verify WSL configuration contains required WSL settings
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-wsl-settings"
        (builtins.hasAttr "wsl" evaluatedConfig && evaluatedConfig.wsl.enable == true)
        "WSL configuration should have wsl.enable = true"
        "wsl.enable = true"
        (
          if builtins.hasAttr "wsl" evaluatedConfig then
            "wsl.enable = ${toString evaluatedConfig.wsl.enable}"
          else
            "no wsl attribute"
        )
        null
        null
    )

    # Test 4: Verify WSL configuration has systemd performance optimizations
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-systemd-config"
        (
          builtins.hasAttr "systemd" evaluatedConfig
          && builtins.hasAttr "settings" evaluatedConfig.systemd
          && builtins.hasAttr "Manager" evaluatedConfig.systemd.settings
        )
        "WSL configuration should have systemd performance optimizations"
        "systemd.settings with performance optimizations"
        (
          if builtins.hasAttr "systemd" evaluatedConfig then
            if builtins.hasAttr "settings" evaluatedConfig.systemd then
              if builtins.hasAttr "Manager" evaluatedConfig.systemd.settings then
                "systemd.settings.Manager exists"
              else
                "no systemd.settings.Manager"
            else
              "no systemd.settings"
          else
            "no systemd attribute"
        )
        null
        null
    )

    # Test 5: Verify WSL configuration has Windows interoperability settings
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-windows-interop"
        (
          builtins.hasAttr "environment" evaluatedConfig
          && builtins.hasAttr "variables" evaluatedConfig.environment
          && builtins.hasAttr "WSLENV" evaluatedConfig.environment.variables
        )
        "WSL configuration should have Windows interoperability environment variables"
        "environment.variables.WSLENV set"
        (
          if builtins.hasAttr "environment" evaluatedConfig then
            if builtins.hasAttr "variables" evaluatedConfig.environment then
              if builtins.hasAttr "WSLENV" evaluatedConfig.environment.variables then
                "WSLENV exists"
              else
                "no WSLENV variable"
            else
              "no environment.variables"
          else
            "no environment attribute"
        )
        null
        null
    )

    # Test 6: Verify WSL configuration enables essential services
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-essential-services"
        (
          builtins.hasAttr "services" evaluatedConfig
          && builtins.hasAttr "sshd" evaluatedConfig.services
          && evaluatedConfig.services.sshd.enable == true
        )
        "WSL configuration should enable essential services like SSH"
        "services.sshd.enable = true"
        (
          if builtins.hasAttr "services" evaluatedConfig then
            if builtins.hasAttr "sshd" evaluatedConfig.services then
              "services.sshd.enable = ${toString evaluatedConfig.services.sshd.enable}"
            else
              "no sshd service"
          else
            "no services attribute"
        )
        null
        null
    )

    # Test 7: Verify WSL configuration enables Docker
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-docker"
        (
          builtins.hasAttr "virtualisation" evaluatedConfig
          && builtins.hasAttr "docker" evaluatedConfig.virtualisation
          && evaluatedConfig.virtualisation.docker.enable == true
        )
        "WSL configuration should enable Docker for development"
        "virtualisation.docker.enable = true"
        (
          if builtins.hasAttr "virtualisation" evaluatedConfig then
            if builtins.hasAttr "docker" evaluatedConfig.virtualisation then
              "virtualisation.docker.enable = ${toString evaluatedConfig.virtualisation.docker.enable}"
            else
              "no docker virtualisation"
          else
            "no virtualisation attribute"
        )
        null
        null
    )

    # Test 8: Verify WSL configuration has fonts
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-fonts"
        (
          builtins.hasAttr "fonts" evaluatedConfig
          && builtins.hasAttr "packages" evaluatedConfig.fonts
          && builtins.isList evaluatedConfig.fonts.packages
          && builtins.length evaluatedConfig.fonts.packages > 0
        )
        "WSL configuration should include fonts for development"
        "fonts.packages with Fira Code and Cascadia Code"
        (
          if builtins.hasAttr "fonts" evaluatedConfig then
            if builtins.hasAttr "packages" evaluatedConfig.fonts then
              "fonts.packages with ${toString (builtins.length evaluatedConfig.fonts.packages)} fonts"
            else
              "no fonts.packages"
          else
            "no fonts attribute"
        )
        null
        null
    )

    # Test 9: Verify WSL configuration has system packages
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-system-packages"
        (
          builtins.hasAttr "environment" evaluatedConfig
          && builtins.hasAttr "systemPackages" evaluatedConfig.environment
          && builtins.isList evaluatedConfig.environment.systemPackages
          && builtins.length evaluatedConfig.environment.systemPackages > 0
        )
        "WSL configuration should include essential system packages"
        "environment.systemPackages with cachix, gnumake, killall, xclip"
        (
          if builtins.hasAttr "environment" evaluatedConfig then
            if builtins.hasAttr "systemPackages" evaluatedConfig.environment then
              "environment.systemPackages with ${toString (builtins.length evaluatedConfig.environment.systemPackages)} packages"
            else
              "no environment.systemPackages"
          else
            "no environment attribute"
        )
        null
        null
    )

    # Test 10: Verify WSL configuration has hostname
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-hostname"
        (
          builtins.hasAttr "networking" evaluatedConfig
          && builtins.hasAttr "hostName" evaluatedConfig.networking
        )
        "WSL configuration should define a hostname"
        "networking.hostName set"
        (
          if builtins.hasAttr "networking" evaluatedConfig then
            if builtins.hasAttr "hostName" evaluatedConfig.networking then
              "networking.hostName = ${evaluatedConfig.networking.hostName}"
            else
              "no networking.hostName"
          else
            "no networking attribute"
        )
        null
        null
    )

    # Test 11: Verify WSL configuration has timezone
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-timezone"
        (builtins.hasAttr "time" evaluatedConfig && builtins.hasAttr "timeZone" evaluatedConfig.time)
        "WSL configuration should define a timezone"
        "time.timeZone set"
        (
          if builtins.hasAttr "time" evaluatedConfig then
            if builtins.hasAttr "timeZone" evaluatedConfig.time then
              "time.timeZone = ${evaluatedConfig.time.timeZone}"
            else
              "no time.timeZone"
          else
            "no time attribute"
        )
        null
        null
    )

    # Test 12: Verify WSL configuration has locale
    (
      let
        evaluatedConfig = wslModule {
          config = { };
          pkgs = pkgs;
          lib = lib;
          inherit inputs;
        };
      in
      helpers.assertTestWithDetails "wsl-configuration-has-locale"
        (builtins.hasAttr "i18n" evaluatedConfig && builtins.hasAttr "defaultLocale" evaluatedConfig.i18n)
        "WSL configuration should define a default locale"
        "i18n.defaultLocale set"
        (
          if builtins.hasAttr "i18n" evaluatedConfig then
            if builtins.hasAttr "defaultLocale" evaluatedConfig.i18n then
              "i18n.defaultLocale = ${evaluatedConfig.i18n.defaultLocale}"
            else
              "no i18n.defaultLocale"
          else
            "no i18n attribute"
        )
        null
        null
    )

  ];
}
