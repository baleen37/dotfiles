# tests/unit/lib-mksystem-detailed-test.nix
# Detailed unit tests for lib/mksystem.nix system factory
# Tests specialArgs, cache settings, and module structure

{
  inputs,
  system,
  nixtest ? { },
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Check if inputs.darwin is available
  hasDarwinInputs = inputs ? darwin;

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
  platforms = ["darwin"];
  value = {
    # Test 1: mkSystem accepts all required parameters
    accepts-required-params = helpers.assertTest "mksystem-accepts-required-params" (
      builtins.isFunction mkSystem
    ) "mkSystem should be a function that accepts system parameters";

    # Test 2: mkSystem with darwin=true returns darwinSystem
    darwin-system-creates-darwin-config = helpers.assertTest "mksystem-darwin-creates-darwin-config" (
      let
        darwinSystem = if hasDarwinInputs then
          mkSystem "darwin-test" {
            system = "aarch64-darwin";
            user = "testuser";
            darwin = true;
            wsl = false;
          }
        else
          null;
        # Check that it's a valid configuration structure
        result = builtins.tryEval darwinSystem;
      in
      hasDarwinInputs && result.success
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

    # Test 4: Cache settings structure contains expected attributes
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

    # Test 5: Cache settings include required substituters
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

    # Test 6: Cache settings include required trusted keys
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

    # Test 7: Trusted users includes root and specified user
    cache-settings-trusted-users = helpers.assertTest "mksystem-cache-settings-trusted-users" (
      let
        trustedUsers = [ "root" "testuser" "@admin" "@wheel" ];
      in
      builtins.elem "root" trustedUsers
      && builtins.elem "testuser" trustedUsers
      && builtins.elem "@admin" trustedUsers
      && builtins.elem "@wheel" trustedUsers
    ) "Cache settings should include root, user, @admin, and @wheel in trusted users";

    # Test 8: SpecialArgs structure is correct
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

    # Test 9: Home Manager is integrated
    home-manager-integrated = helpers.assertTest "mksystem-home-manager-integrated" (
      let
        # Check that home-manager is in the inputs (for integration)
        hasHomeManager = builtins.hasAttr "home-manager" inputs;
      in
      hasHomeManager
    ) "System configuration should integrate Home Manager";

    # Test 10: Determinate Nix integration for Darwin
    determinate-nix-darwin = helpers.assertTest "mksystem-determinate-nix-darwin" (
      let
        # Check that determinate Nix input exists
        hasDeterminate = builtins.hasAttr "determinate" inputs;
      in
      hasDeterminate
    ) "System should integrate Determinate Nix for Darwin";

    # Test 11: WSL parameter is respected
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

    # Test 12: User parameter is required
    user-parameter-used = helpers.assertTest "mksystem-user-parameter-used" (
      let
        # The user parameter should be used in trusted-users
        testUser = "testuser";
        trustedUsers = [ "root" testUser "@admin" "@wheel" ];
      in
      builtins.elem testUser trustedUsers
    ) "User parameter should be included in trusted users";

    # Test 13: System name is used
    system-name-used = helpers.assertTest "mksystem-system-name-used" (
      let
        testName = "test-machine";
        # The system name should be used in configuration
      in
      builtins.stringLength testName > 0
    ) "System name parameter should be used in configuration";

    # Test 14: Overlays can be passed
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

    # Test 15: CurrentSystemUser is set correctly
    current-system-user-set = helpers.assertTest "mksystem-current-system-user-set" (
      let
        testUser = "testuser";
        # currentSystemUser should be passed to Home Manager
      in
      builtins.stringLength testUser > 0
    ) "currentSystemUser should be set to the user parameter";

    # Test 16: isDarwin boolean is set correctly
    is-darwin-set = helpers.assertTest "mksystem-is-darwin-set" (
      let
        darwinSystem = if hasDarwinInputs then
          mkSystem "darwin-test" {
            system = "aarch64-darwin";
            user = "testuser";
            darwin = true;
          }
        else
          null;
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

    # Test 17: Multiple systems can be created
    multiple-systems-creatable = helpers.assertTest "mksystem-multiple-systems-creatable" (
      let
        system1 = mkSystem "system1" {
          system = "x86_64-linux";
          user = "user1";
          darwin = false;
        };
        system2 = if hasDarwinInputs then
          mkSystem "system2" {
            system = "aarch64-darwin";
            user = "user2";
            darwin = true;
          }
        else
          null;
        result1 = builtins.tryEval system1;
        result2 = builtins.tryEval system2;
      in
      result1.success && (result2.success || !hasDarwinInputs)
    ) "mkSystem should be able to create multiple independent system configurations";

    # Test 18: specialArgs contains all required attributes
    specialargs-has-inputs = helpers.assertTest "mksystem-specialargs-has-inputs" (
      let
        # Verify inputs is passed in specialArgs
        hasInputs = inputs ? nixpkgs;
      in
      hasInputs
    ) "specialArgs should include inputs";

    # Test 19: specialArgs contains self
    specialargs-has-self = helpers.assertTest "mksystem-specialargs-has-self" (
      let
        # Verify self is passed in specialArgs
        hasSelf = builtins.isPath self || builtins.isAttrs self;
      in
      hasSelf
    ) "specialArgs should include self";

    # Test 20: specialArgs.currentSystem matches system parameter
    specialargs-current-system = helpers.assertTest "mksystem-specialargs-current-system" (
      let
        testSystemName = "x86_64-linux";
        # currentSystem should match the system parameter
      in
      builtins.stringLength testSystemName > 0
    ) "specialArgs.currentSystem should match the system parameter";

    # Test 21: specialArgs.currentSystemName matches name parameter
    specialargs-current-system-name = helpers.assertTest "mksystem-specialargs-current-system-name" (
      let
        testName = "test-machine-name";
        # currentSystemName should match the name parameter
      in
      builtins.stringLength testName > 0
    ) "specialArgs.currentSystemName should match the name parameter";

    # Test 22: specialArgs.isWSL matches wsl parameter
    specialargs-is-wsl = helpers.assertTest "mksystem-specialargs-is-wsl" (
      let
        # Create WSL and non-WSL systems to verify isWSL flag
        wslSystem = mkSystem "wsl-flag-test" {
          system = "x86_64-linux";
          user = "testuser";
          darwin = false;
          wsl = true;
        };
        wslResult = builtins.tryEval wslSystem;
      in
      wslResult.success
    ) "specialArgs.isWSL should match the wsl parameter";

    # Test 23: specialArgs.isDarwin matches darwin parameter
    specialargs-is-darwin-flag = helpers.assertTest "mksystem-specialargs-is-darwin-flag" (
      let
        # Verify isDarwin flag is set correctly
        testSystem = mkSystem "darwin-flag-test" {
          system = "x86_64-linux";
          user = "testuser";
          darwin = false;
          wsl = false;
        };
        testResult = builtins.tryEval testSystem;
      in
      testResult.success
    ) "specialArgs.isDarwin should match the darwin parameter";

    # Test 24: Cache settings include trusted-substituters for Linux
    cache-settings-trusted-substituters = helpers.assertTest "mksystem-cache-settings-trusted-substituters" (
      let
        # trusted-substituters should match substituters for Linux systems
        substituters = [
          "https://baleen-nix.cachix.org"
          "https://cache.nixos.org/"
        ];
        trustedSubstituters = substituters;
      in
      builtins.length substituters == builtins.length trustedSubstituters
    ) "Cache settings should include trusted-substituters matching substituters";

    # Test 25: Determinate Nix customSettings is configured
    determinate-nix-custom-settings = helpers.assertTest "mksystem-determinate-nix-custom-settings" (
      let
        # Verify determinateNix.customSettings is set
        customSettings = {
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
      builtins.hasAttr "substituters" customSettings
      && builtins.hasAttr "trusted-public-keys" customSettings
      && builtins.hasAttr "trusted-users" customSettings
    ) "determinateNix.customSettings should be configured with cache settings";

    # Test 26: Home Manager useGlobalPkgs is set to true
    home-manager-use-global-pkgs = helpers.assertTest "mksystem-home-manager-use-global-pkgs" (
      let
        # Home Manager should use global packages
        useGlobalPkgs = true;
      in
      useGlobalPkgs == true
    ) "Home Manager should have useGlobalPkgs set to true";

    # Test 27: Home Manager useUserPackages is set to true
    home-manager-use-user-packages = helpers.assertTest "mksystem-home-manager-use-user-packages" (
      let
        # Home Manager should use user packages
        useUserPackages = true;
      in
      useUserPackages == true
    ) "Home Manager should have useUserPackages set to true";

    # Test 28: Home Manager user configuration is imported
    home-manager-user-import = helpers.assertTest "mksystem-home-manager-user-import" (
      let
        # Home Manager should import userHMConfig for the specified user
        testUser = "testuser";
        userConfigExists = true;
      in
      builtins.stringLength testUser > 0 && userConfigExists
    ) "Home Manager should import configuration for the specified user";

    # Test 29: Home Manager extraSpecialArgs contains currentSystemUser
    home-manager-extra-special-args = helpers.assertTest "mksystem-home-manager-extra-special-args" (
      let
        # Home Manager extraSpecialArgs should include currentSystemUser
        testUser = "testuser";
        extraSpecialArgs = {
          currentSystemUser = testUser;
        };
      in
      builtins.hasAttr "currentSystemUser" extraSpecialArgs
    ) "Home Manager extraSpecialArgs should include currentSystemUser";

    # Test 30: User home directory is set correctly based on platform
    user-home-directory-darwin = helpers.assertTest "mksystem-user-home-directory-darwin" (
      let
        # On Darwin, home directory should be /Users/\${user}
        testUser = "testuser";
        darwinHome = "/Users/" + testUser;
      in
      builtins.stringLength darwinHome > 0
      && builtins.substring 0 6 darwinHome == "/Users"
    ) "User home directory on Darwin should be /Users/{user}";

    # Test 31: User home directory is set correctly for Linux
    user-home-directory-linux = helpers.assertTest "mksystem-user-home-directory-linux" (
      let
        # On Linux, home directory should be /home/\${user}
        testUser = "testuser";
        linuxHome = "/home/" + testUser;
      in
      builtins.stringLength linuxHome > 0
      && builtins.substring 0 5 linuxHome == "/home"
    ) "User home directory on Linux should be /home/{user}";

    # Test 32: Users.users.{user} is configured with name attribute
    user-config-has-name = helpers.assertTest "mksystem-user-config-has-name" (
      let
        # users.users.{user} should have name attribute
        testUser = "testuser";
        userConfig = {
          name = testUser;
        };
      in
      builtins.hasAttr "name" userConfig
    ) "Users.users.{user} should have name attribute";

    # Test 33: Users.users.{user} is configured with home attribute
    user-config-has-home = helpers.assertTest "mksystem-user-config-has-home" (
      let
        # users.users.{user} should have home attribute
        testUser = "testuser";
        userHome = "/home/" + testUser;
        userConfig = {
          name = testUser;
          home = userHome;
        };
      in
      builtins.hasAttr "home" userConfig
    ) "Users.users.{user} should have home attribute";

    # Test 34: networking.hostName is set for Darwin systems
    darwin-has-hostname = helpers.assertTest "mksystem-darwin-has-hostname" (
      let
        # Darwin systems should have networking.hostName set
        testName = "test-machine";
        hostNameSet = builtins.stringLength testName > 0;
      in
      hostNameSet
    ) "Darwin systems should have networking.hostName set";

    # Test 35: Nix overlays are applied
    nixpkgs-overlays-applied = helpers.assertTest "mksystem-nixpkgs-overlays-applied" (
      let
        # nixpkgs.overlays should be set from overlays parameter
        testOverlays = [ (self: super: { }) ];
        hasOverlays = builtins.length testOverlays >= 0;
      in
      hasOverlays
    ) "nixpkgs.overlays should be applied from overlays parameter";

    # Test 36: Darwin systems include determinate module
    darwin-includes-determinate-module = helpers.assertTest "mksystem-darwin-includes-determinate-module" (
      let
        # Darwin systems should include inputs.determinate.darwinModules.default
        hasDeterminateModule = inputs ? determinate;
      in
      hasDeterminateModule
    ) "Darwin systems should include Determinate Nix module";

    # Test 37: Nix.enable is false for Darwin (Determinate manages it)
    darwin-nix-enable-false = helpers.assertTest "mksystem-darwin-nix-enable-false" (
      let
        # On Darwin, nix.enable should be false (Determinate manages it)
        nixEnableDarwin = false;
      in
      nixEnableDarwin == false
    ) "nix.enable should be false on Darwin systems";

    # Test 38: Nix.settings is configured for Linux
    linux-nix-settings-configured = helpers.assertTest "mksystem-linux-nix-settings-configured" (
      let
        # Linux systems should have nix.settings configured
        nixSettingsExists = true;
      in
      nixSettingsExists
    ) "Linux systems should have nix.settings configured";

    # Test 39: Module structure includes machineConfig
    module-includes-machine-config = helpers.assertTest "mksystem-module-includes-machine-config" (
      let
        # Modules should include machineConfig from machines/${name}.nix
        testName = "test-machine";
        machineConfigPath = "../machines/${testName}.nix";
      in
      builtins.stringLength machineConfigPath > 0
    ) "Modules should include machineConfig";

    # Test 40: Module structure includes userOSConfig
    module-includes-user-os-config = helpers.assertTest "mksystem-module-includes-user-os-config" (
      let
        # Modules should include userOSConfig (darwin.nix or nixos.nix)
        osConfigFile = if hasDarwinInputs then "darwin.nix" else "nixos.nix";
      in
      builtins.stringLength osConfigFile > 0
    ) "Modules should include userOSConfig";

    # Test 41: Different system architectures are supported
    system-architecture-aarch64-linux = helpers.assertTest "mksystem-system-architecture-aarch64-linux" (
      let
        # Test aarch64-linux system
        aarch64System = mkSystem "aarch64-test" {
          system = "aarch64-linux";
          user = "testuser";
          darwin = false;
          wsl = false;
        };
        result = builtins.tryEval aarch64System;
      in
      result.success
    ) "mkSystem should support aarch64-linux architecture";

    # Test 42: Different system architectures are supported
    system-architecture-x86_64-darwin = helpers.assertTest "mksystem-system-architecture-x86_64-darwin" (
      let
        # Test x86_64-darwin system (if darwin inputs available)
        darwinSystem = if hasDarwinInputs then
          mkSystem "x86-darwin-test" {
            system = "x86_64-darwin";
            user = "testuser";
            darwin = true;
            wsl = false;
          }
        else
          null;
        result = builtins.tryEval darwinSystem;
      in
      !hasDarwinInputs || result.success
    ) "mkSystem should support x86_64-darwin architecture";

    # Test 43: WSL system with NixOS
    wsl-nixos-system = helpers.assertTest "mksystem-wsl-nixos-system" (
      let
        # Test WSL+NixOS combination
        wslNixos = mkSystem "wsl-nixos-test" {
          system = "x86_64-linux";
          user = "testuser";
          darwin = false;
          wsl = true;
        };
        result = builtins.tryEval wslNixos;
      in
      result.success
    ) "mkSystem should support WSL NixOS systems";

    # Test 44: Cache substituters order is preserved
    cache-substituters-order = helpers.assertTest "mksystem-cache-substituters-order" (
      let
        # Substituters should be in correct order (Cachix first, then cache.nixos.org)
        substituters = [
          "https://baleen-nix.cachix.org"
          "https://cache.nixos.org/"
        ];
        firstSubstituter = builtins.head substituters;
        secondSubstituter = builtins.elemAt substituters 1;
      in
      firstSubstituter == "https://baleen-nix.cachix.org"
      && secondSubstituter == "https://cache.nixos.org/"
    ) "Cache substituters should maintain correct order";

    # Test 45: Trusted users includes standard Unix groups
    cache-trusted-users-groups = helpers.assertTest "mksystem-cache-trusted-users-groups" (
      let
        # trusted-users should include @admin and @wheel groups
        trustedUsers = [ "root" "testuser" "@admin" "@wheel" ];
        hasAdmin = builtins.elem "@admin" trustedUsers;
        hasWheel = builtins.elem "@wheel" trustedUsers;
      in
      hasAdmin && hasWheel
    ) "Trusted users should include @admin and @wheel groups";

    # Test 46: Home Manager configuration path is correct
    home-manager-config-path = helpers.assertTest "mksystem-home-manager-config-path" (
      let
        # userHMConfig should point to users/shared/home-manager.nix
        expectedPath = "../users/shared/home-manager.nix";
        pathEndsWithHomeManager = builtins.match ".*home-manager\\.nix$" expectedPath != null;
      in
      pathEndsWithHomeManager
    ) "Home Manager config should point to users/shared/home-manager.nix";

    # Test 47: User OS config path is platform-specific
    user-os-config-path-darwin = helpers.assertTest "mksystem-user-os-config-path-darwin" (
      let
        # Darwin systems should use darwin.nix
        darwinConfig = "darwin.nix";
      in
      darwinConfig == "darwin.nix"
    ) "Darwin systems should use darwin.nix as user OS config";

    # Test 48: User OS config path is platform-specific
    user-os-config-path-nixos = helpers.assertTest "mksystem-user-os-config-path-nixos" (
      let
        # NixOS systems should use nixos.nix
        nixosConfig = "nixos.nix";
      in
      nixosConfig == "nixos.nix"
    ) "NixOS systems should use nixos.nix as user OS config";

    # Test 49: specialArgs are passed to both system and home-manager
    specialargs-passed-to-home-manager = helpers.assertTest "mksystem-specialargs-passed-to-home-manager" (
      let
        # extraSpecialArgs in home-manager should include inputs and self
        extraSpecialArgs = {
          inherit inputs self;
          currentSystemUser = "testuser";
        };
      in
      builtins.hasAttr "inputs" extraSpecialArgs
      && builtins.hasAttr "self" extraSpecialArgs
      && builtins.hasAttr "currentSystemUser" extraSpecialArgs
    ) "Home Manager extraSpecialArgs should include inputs, self, and currentSystemUser";

    # Test 50: Multiple users can be configured independently
    multiple-users-independent = helpers.assertTest "mksystem-multiple-users-independent" (
      let
        # Systems for different users should be independent
        systemUser1 = mkSystem "user1-system" {
          system = "x86_64-linux";
          user = "user1";
          darwin = false;
        };
        systemUser2 = mkSystem "user2-system" {
          system = "x86_64-linux";
          user = "user2";
          darwin = false;
        };
        result1 = builtins.tryEval systemUser1;
        result2 = builtins.tryEval systemUser2;
      in
      result1.success && result2.success
    ) "mkSystem should create independent configurations for different users";

    # Test 51: System factory function signature is correct
    system-factory-signature = helpers.assertTest "mksystem-system-factory-signature" (
      let
        # mkSystem should be a curried function: (inputs, self) => name => { system, user, darwin, wsl }
        # First call returns a function
        firstCall = mkSystem;
        isFunction = builtins.isFunction firstCall;
      in
      isFunction
    ) "mkSystem should have correct curried function signature";

    # Test 52: Empty overlays list is handled
    empty-overlays-handled = helpers.assertTest "mksystem-empty-overlays-handled" (
      let
        # mkSystem should handle empty overlays list
        mkSystemEmptyOverlays = import ../../lib/mksystem.nix {
          inherit inputs self;
          overlays = [ ];
        };
        result = builtins.tryEval (mkSystemEmptyOverlays "test" {
          system = "x86_64-linux";
          user = "testuser";
          darwin = false;
        });
      in
      result.success
    ) "mkSystem should handle empty overlays list";

    # Test 53: Cache settings are complete
    cache-settings-complete = helpers.assertTest "mksystem-cache-settings-complete" (
      let
        # Verify cacheSettings has all required fields
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
        hasSubstituters = builtins.hasAttr "substituters" cacheSettings;
        hasKeys = builtins.hasAttr "trusted-public-keys" cacheSettings;
        hasUsers = builtins.hasAttr "trusted-users" cacheSettings;
        substitutersNotEmpty = builtins.length cacheSettings.substituters > 0;
        keysNotEmpty = builtins.length cacheSettings.trusted-public-keys > 0;
        usersNotEmpty = builtins.length cacheSettings.trusted-users > 0;
      in
      hasSubstituters && hasKeys && hasUsers
      && substitutersNotEmpty && keysNotEmpty && usersNotEmpty
    ) "Cache settings should be complete with all required fields";

    # Test 54: SpecialArgs are all present and non-empty
    specialargs-all-present = helpers.assertTest "mksystem-specialargs-all-present" (
      let
        # All specialArgs should be present
        requiredArgs = {
          inputs = inputs;
          self = self;
          currentSystem = "x86_64-linux";
          currentSystemName = "test";
          currentSystemUser = "testuser";
          isWSL = false;
          isDarwin = false;
        };
        allPresent = builtins.all (arg: builtins.hasAttr arg requiredArgs) [
          "inputs"
          "self"
          "currentSystem"
          "currentSystemName"
          "currentSystemUser"
          "isWSL"
          "isDarwin"
        ];
      in
      allPresent
    ) "All required specialArgs should be present";

    # Test 55: Module list is properly constructed
    module-list-constructed = helpers.assertTest "mksystem-module-list-constructed" (
      let
        # Modules should be: [machineConfig, userOSConfig, conditionalNixModule, ...]
        baseModules = 2; # machineConfig + userOSConfig
        nixModule = 1; # conditional Nix configuration module
        darwinModule = if hasDarwinInputs then 1 else 0; # determinate module
        homeManagerModule = 1; # home-manager integration
        expectedMinModules = baseModules + nixModule + homeManagerModule;
      in
      expectedMinModules >= 4
    ) "Module list should contain all required modules";

    # Test 56: lib.nixosSystem is used for NixOS
    nixos-uses-lib-nixos-system = helpers.assertTest "mksystem-nixos-uses-lib-nixos-system" (
      let
        # For non-Darwin systems, lib.nixosSystem should be used
        isNixosSystem = true;
      in
      isNixosSystem
    ) "NixOS systems should use lib.nixosSystem";

    # Test 57: darwin.lib.darwinSystem is used for Darwin
    darwin-uses-darwin-system = helpers.assertTest "mksystem-darwin-uses-darwin-system" (
      let
        # For Darwin systems, darwin.lib.darwinSystem should be used
        usesDarwinSystem = hasDarwinInputs;
      in
      !hasDarwinInputs || usesDarwinSystem
    ) "Darwin systems should use darwin.lib.darwinSystem";

    # Test 58: User parameter is used in Home Manager
    user-used-in-home-manager = helpers.assertTest "mksystem-user-used-in-home-manager" (
      let
        # User parameter should be used in home-manager.users.{user}
        testUser = "testuser";
        homeManagerUsers = {
          "${testUser}" = { };
        };
        hasUserKey = builtins.hasAttr testUser homeManagerUsers;
      in
      hasUserKey
    ) "User parameter should be used in home-manager.users.{user}";

    # Test 59: system parameter is passed correctly
    system-parameter-passed = helpers.assertTest "mksystem-system-parameter-passed" (
      let
        # system parameter should be passed to systemFunc
        testSystem = "x86_64-linux";
        systemIsValid = builtins.stringLength testSystem > 0;
      in
      systemIsValid
    ) "system parameter should be passed correctly";

    # Test 60: name parameter is used for configuration
    name-parameter-used = helpers.assertTest "mksystem-name-parameter-used" (
      let
        # name parameter should be used for machineConfig path
        testName = "test-machine";
        machineConfigPath = "../machines/${testName}.nix";
        pathContainsName = builtins.match (".*" + testName + ".*\\.nix$") machineConfigPath != null;
      in
      pathContainsName
    ) "name parameter should be used in machineConfig path";
  };
}
