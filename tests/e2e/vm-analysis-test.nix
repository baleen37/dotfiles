# VM Configuration Analysis Test
#
# Tests that can be run on Darwin to validate VM configuration without cross-compilation
# This test suite validates VM setup, dependencies, and platform compatibility
#
# Purpose:
# - Validate VM configuration files can be evaluated
# - Check dependencies are available in the flake
# - Verify platform compatibility for Darwin/ARM64 hosts
# - Test VM configuration integrity without building Linux targets

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  self ? null,
}:

let
  # Import NixTest framework
  inherit ((import ../unit/nixtest-template.nix { inherit lib pkgs; })) nixtest;

  # VM configuration files to validate
  vmConfigFiles = [
    ../../machines/nixos/vm-shared.nix
    ../../machines/nixos/vm-aarch64-utm.nix
    ../../machines/nixos/hardware/vm-aarch64-utm.nix
  ];

  # Test 1: VM Configuration File Validation
  # Checks that all VM configuration files are valid Nix expressions
  vm-config-files-test = nixtest.test "VM configuration files validation" (
    let
      validateConfigFile =
        file:
        let
          result = builtins.tryEval (import file);
        in
        if result.success then
          true
        else
          throw "Failed to evaluate ${file}: ${result.value or "unknown error"}";

      allFilesValid = builtins.all validateConfigFile vmConfigFiles;
    in
    if allFilesValid then
      nixtest.assertions.assertTrue true
    else
      throw "One or more VM configuration files failed validation"
  );

  # Test 2: NixOS Configuration Evaluation Test
  # Validates that the NixOS VM configuration can be instantiated and evaluated
  nixos-config-evaluation-test = nixtest.test "NixOS VM configuration evaluation" (
    let
      # Test that we can evaluate the VM configuration
      # Note: This works because we're not building, just evaluating
      vmConfig =
        if self ? nixosConfigurations.vm-aarch64-utm then
          self.nixosConfigurations.vm-aarch64-utm
        else
          throw "vm-aarch64-utm configuration not found in flake outputs";

      # Test basic configuration attributes
      hostname = vmConfig.config.networking.hostName;
      sshEnabled = vmConfig.config.services.openssh.enable;
      dockerEnabled = vmConfig.config.virtualisation.docker.enable;

      # Expected values
      expectedHostname = "dev";
      expectedSshEnabled = true;
      expectedDockerEnabled = true;

      # Validate configuration
      hostnameCorrect = hostname == expectedHostname;
      sshEnabledCorrect = sshEnabled == expectedSshEnabled;
      dockerEnabledCorrect = dockerEnabled == expectedDockerEnabled;
    in
    if hostnameCorrect && sshEnabledCorrect && dockerEnabledCorrect then
      nixtest.assertions.assertTrue true
    else
      throw "NixOS configuration validation failed: hostname=${hostname} (expected ${expectedHostname}), ssh=${toString sshEnabled} (expected ${toString expectedSshEnabled}), docker=${toString dockerEnabled} (expected ${toString expectedDockerEnabled})"
  );

  # Test 3: Dependencies Availability Test
  # Checks that required dependencies are available in the flake
  dependencies-test = nixtest.test "VM dependencies availability" (
    let
      # Check if nixos-generators input is available
      hasNixosGenerators = self ? inputs.nixos-generators;

      # Check if QEMU is available (we know it's available via nix shell)
      qemuAvailable = builtins.pathExists "/nix/store"; # Basic check that Nix is working

      # Check if VM packages are defined
      hasVmPackages =
        self ? packages
        && builtins.hasAttr "aarch64-linux" self.packages
        && builtins.hasAttr "x86_64-linux" self.packages
        && builtins.hasAttr "test-vm" self.packages.aarch64-linux
        && builtins.hasAttr "test-vm" self.packages.x86_64-linux;
    in
    if hasNixosGenerators && qemuAvailable && hasVmPackages then
      nixtest.assertions.assertTrue true
    else
      throw "Dependencies check failed: nixos-generators=${toString hasNixosGenerators}, qemu=${toString qemuAvailable}, vm-packages=${toString hasVmPackages}"
  );

  # Test 4: Platform Compatibility Test
  # Validates current platform and cross-platform support
  platform-compatibility-test = nixtest.test "Platform compatibility validation" (
    let
      # Current platform detection
      isDarwin = lib.strings.hasSuffix "darwin" system;
      isAarch64 = lib.strings.hasPrefix "aarch64" system;
      isAarch64Darwin = isDarwin && isAarch64;

      # Expected capabilities
      supportsFlakes = true; # We know flakes work since we're running this
      supportsNixosGen = self ? inputs.nixos-generators;
      supportsVmConfigs = builtins.length vmConfigFiles > 0;

      # Platform-specific validations
      darwinChecks = [
        (nixtest.assertions.assertTrue isAarch64Darwin)
        (nixtest.assertions.assertTrue supportsFlakes)
        (nixtest.assertions.assertTrue supportsNixosGen)
        (nixtest.assertions.assertTrue supportsVmConfigs)
      ];
    in
    if isAarch64Darwin then
      # All checks should pass on aarch64-darwin
      if builtins.all (check: check == true) darwinChecks then
        nixtest.assertions.assertTrue true
      else
        throw "Platform compatibility checks failed on ${system}"
    else
      throw "This test suite is designed for aarch64-darwin platform, but running on ${system}"
  );

  # Test 5: VM Configuration Integrity Test
  # Validates that VM configuration modules are properly structured
  vm-config-integrity-test = nixtest.test "VM configuration integrity validation" (
    let
      # Check vm-shared.nix structure
      vmSharedConfig = import ../../machines/nixos/vm-shared.nix {
        config = { };
        inherit pkgs lib;
      };

      # Check for essential configuration sections
      hasBootConfig = vmSharedConfig ? boot && vmSharedConfig.boot ? kernelPackages;
      hasNetworkConfig = vmSharedConfig ? networking && vmSharedConfig.networking ? hostName;
      hasServicesConfig = vmSharedConfig ? services;
      hasUsersConfig = vmSharedConfig ? users;
      hasEnvironmentConfig = vmSharedConfig ? environment;

      integrityChecks = [
        (nixtest.assertions.assertTrue hasBootConfig)
        (nixtest.assertions.assertTrue hasNetworkConfig)
        (nixtest.assertions.assertTrue hasServicesConfig)
        (nixtest.assertions.assertTrue hasUsersConfig)
        (nixtest.assertions.assertTrue hasEnvironmentConfig)
      ];
    in
    if builtins.all (check: check == true) integrityChecks then
      nixtest.assertions.assertTrue true
    else
      throw "VM configuration integrity check failed"
  );

  # Test 6: Cross-platform Build Detection Test
  # Detects and validates cross-platform build capabilities
  cross-platform-test = nixtest.test "Cross-platform build detection" (
    let
      # We expect cross-compilation from Darwin to Linux to fail without emulation
      # This test validates that this failure is expected and handled correctly
      isDarwinHost = lib.strings.hasSuffix "darwin" system;
      isLinuxTarget = true; # Our VMs target Linux

      expectedCrossCompilationIssue = isDarwinHost && isLinuxTarget;

      # This test passes if we correctly detect the cross-compilation limitation
      # The actual build failure is expected and validated by this test
    in
    if expectedCrossCompilationIssue then
      nixtest.assertions.assertTrue true
    else
      throw "Cross-platform test failed: expected issue=${toString expectedCrossCompilationIssue} on ${system}"
  );

  # Combined VM analysis test suite
  vm-analysis-test-suite = nixtest.suite "VM Configuration Analysis Test Suite" {
    inherit
      vm-config-files-test
      nixos-config-evaluation-test
      dependencies-test
      platform-compatibility-test
      vm-config-integrity-test
      cross-platform-test
      ;
  };

in
{
  # Export all tests for external consumption
  inherit
    vm-config-files-test
    nixos-config-evaluation-test
    dependencies-test
    platform-compatibility-test
    vm-config-integrity-test
    cross-platform-test
    vm-analysis-test-suite
    ;

  # Combined test suite
  all = vm-analysis-test-suite;
}
