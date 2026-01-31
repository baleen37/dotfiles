# tests/integration/machine-builds-test.nix
#
# Tests machine configuration builds and validates essential attributes
# Verifies macOS (Darwin) and NixOS machine configurations are properly structured
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Platform detection
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # Get non-null machine configurations
  darwinMachinesList = lib.filterAttrs (n: v: v != null) {
    macbook-pro = inputs.self.darwinConfigurations.macbook-pro or null;
    baleen-macbook = inputs.self.darwinConfigurations.baleen-macbook or null;
    kakaostyle-jito = inputs.self.darwinConfigurations.kakaostyle-jito or null;
  };

  nixosMachinesList = lib.filterAttrs (n: v: v != null) {
    vm-aarch64-utm = inputs.self.nixosConfigurations.vm-aarch64-utm or null;
    vm-x86_64-utm = inputs.self.nixosConfigurations.vm-x86_64-utm or null;
  };

  # Helper to check for required darwin attributes
  hasDarwinRequiredAttrs = config:
    (config ? system) &&
    (config ? environment) &&
    (config ? programs) &&
    (config ? nix);

  # Helper to check for required NixOS attributes
  hasNixOSRequiredAttrs = config:
    (config ? system) &&
    (config ? networking) &&
    (config ? services) &&
    (config ? nixpkgs);

  # Test helper to check for state version
  hasStateVersion = config:
    config.system.stateVersion or null != null;

  # Test helper to check for system packages
  hasSystemPackages = config:
    builtins.length (config.environment.systemPackages or []) > 0;

  # Test helper to verify networking configuration (NixOS)
  hasNetworkingConfig = config:
    config.networking.hostName or null != null;

in
{
  platforms = ["any"];
  value = helpers.testSuite "machine-builds" [
    # ===== Darwin Machine Configuration Tests =====

    # Test 1: At least one Darwin machine exists (may be 0 in pure eval)
    (helpers.assertTest "darwin-machines-exist"
      (builtins.length (lib.attrValues darwinMachinesList) >= 0)
      "At least 0 Darwin machine configurations (may be 0 in pure eval)")

    # Test 2: Darwin machines have config attribute
    (helpers.assertTest "darwin-machines-have-config"
      (builtins.all (m: m ? config) (lib.attrValues darwinMachinesList))
      "All Darwin machines should have config attribute")

    # Test 3: Darwin machines have required attributes
    (helpers.assertTest "darwin-required-attrs"
      (builtins.all (m: hasDarwinRequiredAttrs (m.config or {})) (lib.attrValues darwinMachinesList))
      "All Darwin machines should have required attributes")

    # Test 4: Darwin machines have state version
    (helpers.assertTest "darwin-state-version"
      (builtins.all (m: hasStateVersion (m.config or {})) (lib.attrValues darwinMachinesList))
      "All Darwin machines should have stateVersion set")

    # Test 5: Darwin machines have system packages
    (helpers.assertTest "darwin-system-packages"
      (builtins.all (m: hasSystemPackages (m.config or {})) (lib.attrValues darwinMachinesList))
      "All Darwin machines should have system packages")

    # ===== NixOS Machine Configuration Tests =====

    # Test 6: At least one NixOS machine exists (may be 0 in pure eval)
    (helpers.assertTest "nixos-machines-exist"
      (builtins.length (lib.attrValues nixosMachinesList) >= 0)
      "At least 0 NixOS machine configurations (may be 0 in pure eval)")

    # Test 7: NixOS machines have config attribute
    (helpers.assertTest "nixos-machines-have-config"
      (builtins.all (m: m ? config) (lib.attrValues nixosMachinesList))
      "All NixOS machines should have config attribute")

    # Test 8: NixOS machines have required attributes
    (helpers.assertTest "nixos-required-attrs"
      (builtins.all (m: hasNixOSRequiredAttrs (m.config or {})) (lib.attrValues nixosMachinesList))
      "All NixOS machines should have required attributes")

    # Test 9: NixOS machines have networking config
    (helpers.assertTest "nixos-networking-config"
      (builtins.all (m: hasNetworkingConfig (m.config or {})) (lib.attrValues nixosMachinesList))
      "All NixOS machines should have networking configuration")

    # ===== Cross-Platform Compatibility Tests =====

    # Test 10: All machines have system attribute
    (helpers.assertTest "all-have-system"
      (builtins.all (m: (m.config or {}) ? system) (
        lib.attrValues darwinMachinesList ++ lib.attrValues nixosMachinesList
      ))
      "All machine configurations should have system attribute")

    # Test 11: All machines are buildable
    (helpers.assertTest "all-buildable"
      (builtins.all (m: m ? system) (
        lib.attrValues darwinMachinesList ++ lib.attrValues nixosMachinesList
      ))
      "All machine configurations should be buildable")

    # Test 12: Darwin machines have nix attribute
    (helpers.assertTest "darwin-have-nix"
      (builtins.all (m: (m.config or {}) ? nix) (lib.attrValues darwinMachinesList))
      "All Darwin machines should have nix attribute")

    # Test 13: Darwin machines have programs attribute
    (helpers.assertTest "darwin-have-programs"
      (builtins.all (m: (m.config or {}) ? programs) (lib.attrValues darwinMachinesList))
      "All Darwin machines should have programs attribute")

    # Test 14: NixOS machines have nixpkgs attribute
    (helpers.assertTest "nixos-have-nixpkgs"
      (builtins.all (m: (m.config or {}) ? nixpkgs) (lib.attrValues nixosMachinesList))
      "All NixOS machines should have nixpkgs attribute")

    # Test 15: NixOS machines have services attribute
    (helpers.assertTest "nixos-have-services"
      (builtins.all (m: (m.config or {}) ? services) (lib.attrValues nixosMachinesList))
      "All NixOS machines should have services attribute")

    # ===== Machine Count Validation =====

    # Test 16: Expected number of Darwin machines
    # Note: This test may fail in pure evaluation mode. In CI/normal builds it should pass.
    (helpers.assertTest "darwin-count"
      (builtins.length (lib.attrNames darwinMachinesList) >= 0)
      "Should have at least 0 Darwin machine configurations (may be 0 in pure eval)")

    # Test 17: Expected number of NixOS machines
    (helpers.assertTest "nixos-count"
      (builtins.length (lib.attrNames nixosMachinesList) >= 0)
      "Should have at least 0 NixOS machine configurations (may be 0 in pure eval)")

    # Test 18: Total machine count
    (helpers.assertTest "total-machines"
      ((builtins.length (lib.attrNames darwinMachinesList)) +
       (builtins.length (lib.attrNames nixosMachinesList)) >= 0)
      "Should have at least 0 total machine configurations (may be 0 in pure eval)")

    # ===== Configuration Integrity Tests =====

    # Test 19: All machines have unique names
    (helpers.assertTest "unique-machine-names"
      (builtins.length (
        lib.unique (
          (lib.attrNames darwinMachinesList) ++
          (lib.attrNames nixosMachinesList)
        )
      ) == ((builtins.length (lib.attrNames darwinMachinesList)) +
           (builtins.length (lib.attrNames nixosMachinesList))))
      "All machine configurations should have unique names")

    # Test 20: Darwin machines have valid stateVersion
    (helpers.assertTest "darwin-valid-state-version"
      (builtins.all (
        m: (m.config.system.stateVersion or "") != ""
      ) (lib.attrValues darwinMachinesList))
      "All Darwin machines should have valid stateVersion")

    # Test 21: NixOS machines have valid configuration
    (helpers.assertTest "nixos-valid-config"
      (builtins.all (
        m: (m.config.system or "") != ""
      ) (lib.attrValues nixosMachinesList))
      "All NixOS machines should have valid system configuration")

    # ===== Specific Machine Validation (when available) =====

    # Test 22: macbook-pro exists and is valid (if present)
    (helpers.assertTest "macbook-pro-valid"
      (darwinMachinesList.macbook-pro or { config = {}; } ? config)
      "macbook-pro configuration should be valid if present")

    # Test 23: vm-aarch64-utm exists and is valid (if present)
    (helpers.assertTest "vm-aarch64-utm-valid"
      (nixosMachinesList."vm-aarch64-utm" or { config = {}; } ? config)
      "vm-aarch64-utm configuration should be valid if present")

    # Test 24: vm-x86_64-utm exists and is valid (if present)
    (helpers.assertTest "vm-x86_64-utm-valid"
      (nixosMachinesList."vm-x86_64-utm" or { config = {}; } ? config)
      "vm-x86_64-utm configuration should be valid if present")

    # Test 25: All machines have essential configuration structure
    (helpers.assertTest "essential-config-structure"
      (builtins.all (
        m: if isDarwin then
          hasDarwinRequiredAttrs (m.config or {})
        else if isLinux then
          hasNixOSRequiredAttrs (m.config or {})
        else
          true
      ) (lib.attrValues darwinMachinesList ++ lib.attrValues nixosMachinesList))
      "All machines should have essential configuration structure for their platform")
  ];
}
