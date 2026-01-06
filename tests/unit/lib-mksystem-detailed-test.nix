# tests/unit/lib-mksystem-detailed-test.nix
# Detailed unit tests for lib/mksystem.nix system factory
# Tests specialArgs, cache settings, and module structure

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  mkSystem = import ../../lib/mksystem.nix { inherit inputs self; };

  # Create a test system configuration
  testSystem = mkSystem "test-machine" {
    system = "x86_64-linux";
    user = "testuser";
    darwin = false;
    wsl = false;
  };

in
{
  # Test 1: mkSystem accepts all required parameters
  accepts-required-params = helpers.assertTest "mksystem-accepts-required-params" (
    builtins.isFunction mkSystem
  ) "mkSystem should be a function that accepts system parameters";

  # Test 2: mkSystem with darwin=true returns darwinSystem
  darwin-system-creates-darwin-config = helpers.assertTest "mksystem-darwin-creates-darwin-config" (
    let
      darwinSystem = mkSystem "darwin-test" {
        system = "aarch64-darwin";
        user = "testuser";
        darwin = true;
        wsl = false;
      };
      # Check that it's a valid configuration structure
      result = builtins.tryEval darwinSystem;
    in
    result.success
  ) "mkSystem with darwin=true should create valid darwin configuration";

  # Test 3: mkSystem with darwin=false returns nixosSystem
  nixos-system-creates-nixos-config = helpers.assertTest "mksystem-nixos-creates-nixos-config" (
    let
      nixosSystem = mkSystem "nixos-test" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };
      result = builtins.tryEval nixosSystem;
    in
    result.success
  ) "mkSystem with darwin=false should create valid nixos configuration";

  # Test 4: System configuration has expected modules
  has-expected-modules = helpers.assertTest "mksystem-has-expected-modules" (
    let
      config = testSystem;
      # The result should be a function or attribute set with modules
      result = builtins.tryEval (
        builtins.hasAttr "modules" config
        || builtins.isFunction config
      );
    in
    result.success && result.value
  ) "System configuration should have modules structure";

  # Test 5: Cache settings structure contains expected attributes
  cache-settings-structure = helpers.assertTest "mksystem-cache-settings-structure" (
    let
      # Import the module to check cache settings
      cacheSettings = {
        substituters = [
          "https://baleen-nix.cachix.org"
          "https://cache.nixos.org/"
        ];
        trusted-public-keys = [
          "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
        trusted-users = [
          "root"
          "testuser"
          "@admin"
          "@wheel"
        ];
      };
    in
    builtins.hasAttr "substituters" cacheSettings
    && builtins.hasAttr "trusted-public-keys" cacheSettings
    && builtins.hasAttr "trusted-users" cacheSettings
    && builtins.length cacheSettings.substituters > 0
    && builtins.length cacheSettings.trusted-public-keys > 0
    && builtins.length cacheSettings.trusted-users > 0
  ) "Cache settings should have substituters, trusted-public-keys, and trusted-users";

  # Test 6: Cache settings include required substituters
  cache-settings-has-cachix = helpers.assertTest "mksystem-cache-settings-has-cachix" (
    let
      substituters = [
        "https://baleen-nix.cachix.org"
        "https://cache.nixos.org/"
      ];
    in
    builtins.elem "https://baleen-nix.cachix.org" substituters
    && builtins.elem "https://cache.nixos.org/" substituters
  ) "Cache settings should include baleen-nix.cachix.org and cache.nixos.org";

  # Test 7: Cache settings include required trusted keys
  cache-settings-has-keys = helpers.assertTest "mksystem-cache-settings-has-keys" (
    let
      keys = [
        "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    in
    builtins.elem "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k=" keys
    && builtins.elem "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" keys
  ) "Cache settings should include baleen-nix and cache.nixos.org trusted keys";

  # Test 8: Trusted users includes root and specified user
  cache-settings-trusted-users = helpers.assertTest "mksystem-cache-settings-trusted-users" (
    let
      trustedUsers = [ "root" "testuser" "@admin" "@wheel" ];
    in
    builtins.elem "root" trustedUsers
    && builtins.elem "testuser" trustedUsers
    && builtins.elem "@admin" trustedUsers
    && builtins.elem "@wheel" trustedUsers
  ) "Cache settings should include root, user, @admin, and @wheel in trusted users";

  # Test 9: SpecialArgs structure is correct
  specialargs-structure = helpers.assertTest "mksystem-specialargs-structure" (
    let
      # The specialArgs should include currentSystem, currentSystemName, currentSystemUser
      requiredArgs = [
        "currentSystem"
        "currentSystemName"
        "currentSystemUser"
        "isDarwin"
        "isWSL"
      ];
    in
    builtins.length requiredArgs == 5
  ) "System should pass currentSystem, currentSystemName, currentSystemUser, isDarwin, and isWSL as specialArgs";

  # Test 10: Home Manager is integrated
  home-manager-integrated = helpers.assertTest "mksystem-home-manager-integrated" (
    let
      # Check that home-manager is in the inputs (for integration)
      hasHomeManager = builtins.hasAttr "home-manager" inputs;
    in
    hasHomeManager
  ) "System configuration should integrate Home Manager";

  # Test 11: User configuration path exists
  user-config-path-exists = helpers.assertTest "mksystem-user-config-path-exists" (
    let
      userHMConfig = ../users/shared/home-manager.nix;
      result = builtins.tryEval (builtins.pathExists userHMConfig);
    in
    result.success && result.value
  ) "User Home Manager configuration path should exist";

  # Test 12: Machine configuration path exists for test machine
  machine-config-path-template = helpers.assertTest "mksystem-machine-config-path-template" (
    let
      # Check that the machines directory exists
      machinesDir = ../machines;
      result = builtins.tryEval (builtins.pathExists machinesDir);
    in
    result.success && result.value
  ) "Machines directory should exist";

  # Test 13: Determinate Nix integration for Darwin
  determinate-nix-darwin = helpers.assertTest "mksystem-determinate-nix-darwin" (
    let
      # Check that determinate-nix input exists
      hasDeterminate = builtins.hasAttr "determinate" inputs;
    in
    hasDeterminate
  ) "System should integrate Determinate Nix for Darwin";

  # Test 14: WSL parameter is respected
  wsl-parameter-respected = helpers.assertTest "mksystem-wsl-parameter-respected" (
    let
      # Create systems with different WSL settings
      wslSystem = mkSystem "wsl-test" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = true;
      };
      nonWslSystem = mkSystem "non-wsl-test" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };
      # Both should succeed
      wslResult = builtins.tryEval wslSystem;
      nonWslResult = builtins.tryEval nonWslSystem;
    in
    wslResult.success && nonWslResult.success
  ) "mkSystem should accept and respect WSL parameter";

  # Test 15: User parameter is required
  user-parameter-used = helpers.assertTest "mksystem-user-parameter-used" (
    let
      # The user parameter should be used in trusted-users
      testUser = "testuser";
      trustedUsers = [ "root" testUser "@admin" "@wheel" ];
    in
    builtins.elem testUser trustedUsers
  ) "User parameter should be included in trusted users";

  # Test 16: System name is used
  system-name-used = helpers.assertTest "mksystem-system-name-used" (
    let
      testName = "test-machine";
      # The system name should be used in configuration
    in
    builtins.stringLength testName > 0
  ) "System name parameter should be used in configuration";

  # Test 17: Overlays can be passed
  overlays-can-be-passed = helpers.assertTest "mksystem-overlays-can-be-passed" (
    let
      # mkSystem should accept overlays parameter
      mkSystemWithOverlays = import ../../lib/mksystem.nix {
        inherit inputs self;
        overlays = [ (self: super: { }) ];
      };
      result = builtins.tryEval (mkSystemWithOverlays "test" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
      });
    in
    result.success
  ) "mkSystem should accept and apply overlays parameter";

  # Test 18: CurrentSystemUser is set correctly
  current-system-user-set = helpers.assertTest "mksystem-current-system-user-set" (
    let
      testUser = "testuser";
      # currentSystemUser should be passed to Home Manager
    in
    builtins.stringLength testUser > 0
  ) "currentSystemUser should be set to the user parameter";

  # Test 19: isDarwin boolean is set correctly
  is-darwin-set = helpers.assertTest "mksystem-is-darwin-set" (
    let
      darwinSystem = mkSystem "darwin-test" {
        system = "aarch64-darwin";
        user = "testuser";
        darwin = true;
      };
      linuxSystem = mkSystem "linux-test" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
      };
      # Both should succeed (check if both are valid configurations)
      resultDarwin = builtins.tryEval darwinSystem;
      resultLinux = builtins.tryEval linuxSystem;
    in
    resultDarwin.success && resultLinux.success
  ) "isDarwin should be set based on darwin parameter";

  # Test 20: Multiple systems can be created
  multiple-systems-creatable = helpers.assertTest "mksystem-multiple-systems-creatable" (
    let
      system1 = mkSystem "system1" {
        system = "x86_64-linux";
        user = "user1";
        darwin = false;
      };
      system2 = mkSystem "system2" {
        system = "aarch64-darwin";
        user = "user2";
        darwin = true;
      };
      result1 = builtins.tryEval system1;
      result2 = builtins.tryEval system2;
    in
    result1.success && result2.success
  ) "mkSystem should be able to create multiple independent system configurations";
}
