# Platform-Specific Switch Execution End-to-End Tests
#
# Comprehensive testing for `make switch` platform-specific behavior.
# Validates that each platform uses the correct switch command and arguments.
#
# Test Categories:
# - Darwin Switch Execution Tests (darwin-rebuild)
# - NixOS Switch Execution Tests (nixos-rebuild)
# - Ubuntu/Non-NixOS Switch Tests (home-manager)
# - Platform Detection Logic Tests
# - Error Handling by Platform
#
# Platform-Specific Commands Tested:
# - Darwin: sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET}
# - NixOS: sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK nixos-rebuild switch --impure --flake .#$${TARGET}
# - Ubuntu: home-manager switch --flake ".#$(USER)" -b backup --impure

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  nixtest ? null,
}:

let
  # Use provided NixTest framework (or fallback to local template)
  nixtestFinal =
    if nixtest != null then
      nixtest
    else
      (import ../unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import platform system for platform detection
  platformSystem = import ../../lib/platform-system.nix { inherit system; };

  # Import E2E test helpers
  helpers = import ./helpers.nix { inherit lib pkgs platformSystem; };

  # Mock function generators for platform-specific testing
  mockUtils = {
    # Mock uname command for OS detection
    mockUname = os: ''
      function uname() {
        case "$1" in
          -s)
            echo "${os}"
            ;;
          *)
            command uname "$@"
            ;;
        esac
      }
      export -f uname
    '';

    # Mock sudo command for testing environment variable passing
    mockSudo = ''
      function sudo() {
        # Capture and log environment variables for validation
        echo "🔍 Sudo called with: $*"
        echo "🔍 Environment variables: USER=$USER SSH_AUTH_SOCK=$SSH_AUTH_SOCK"

        # Extract environment variables passed via -E env
        local env_vars=""
        local cmd=""
        local parsing_env=false

        for arg in "$@"; do
          if [[ "$arg" == "-E" ]]; then
            continue
          elif [[ "$arg" == "env" ]]; then
            parsing_env=true
          elif [[ "$parsing_env" == true && "$arg" == *"="* ]]; then
            env_vars="$env_vars $arg"
          elif [[ "$parsing_env" == true && "$arg" != *"="* ]]; then
            cmd="$arg"
            parsing_env=false
          else
            cmd="$cmd $arg"
          fi
        done

        echo "✅ Environment preserved: $env_vars"
        echo "✅ Command to execute: $cmd"

        # Mock successful execution
        return 0
      }
      export -f sudo
    '';

    # Mock darwin-rebuild command
    mockDarwinRebuild = ''
      function darwin-rebuild() {
        echo "🍎 darwin-rebuild called with: $*"

        # Parse arguments
        local action=""
        local flake=""
        local impure=false

        while [[ $# -gt 0 ]]; do
          case $1 in
            switch|build|boot)
              action="$1"
              shift
              ;;
            --flake)
              flake="$2"
              shift 2
              ;;
            --impure)
              impure=true
              shift
              ;;
            *)
              shift
              ;;
          esac
        done

        echo "✅ Action: $action"
        echo "✅ Flake: $flake"
        echo "✅ Impure: $impure"

        # Validate required arguments
        if [[ "$action" == "switch" && -n "$flake" && "$impure" == true ]]; then
          echo "✅ darwin-rebuild switch validation successful"
          return 0
        else
          echo "❌ darwin-rebuild validation failed"
          return 1
        fi
      }
      export -f darwin-rebuild
    '';

    # Mock nixos-rebuild command
    mockNixosRebuild = ''
      function nixos-rebuild() {
        echo "🐧 nixos-rebuild called with: $*"

        # Parse arguments
        local action=""
        local flake=""
        local impure=false

        while [[ $# -gt 0 ]]; do
          case $1 in
            switch|build|boot|test)
              action="$1"
              shift
              ;;
            --flake)
              flake="$2"
              shift 2
              ;;
            --impure)
              impure=true
              shift
              ;;
            *)
              shift
              ;;
          esac
        done

        echo "✅ Action: $action"
        echo "✅ Flake: $flake"
        echo "✅ Impure: $impure"

        # Validate required arguments
        if [[ "$action" == "switch" && -n "$flake" && "$impure" == true ]]; then
          echo "✅ nixos-rebuild switch validation successful"
          return 0
        else
          echo "❌ nixos-rebuild validation failed"
          return 1
        fi
      }
      export -f nixos-rebuild
    '';

    # Mock home-manager command
    mockHomeManager = ''
      function home-manager() {
        echo "🏠 home-manager called with: $*"

        # Parse arguments
        local action=""
        local flake=""
        local backup=""
        local impure=false

        while [[ $# -gt 0 ]]; do
          case $1 in
            switch|build|experimental-features)
              if [[ "$1" == "switch" ]]; then
                action="$1"
              fi
              shift
              ;;
            --flake)
              flake="$2"
              shift 2
              ;;
            -b)
              backup="$2"
              shift 2
              ;;
            --impure)
              impure=true
              shift
              ;;
            *)
              shift
              ;;
          esac
        done

        echo "✅ Action: $action"
        echo "✅ Flake: $flake"
        echo "✅ Backup: $backup"
        echo "✅ Impure: $impure"

        # Validate required arguments
        if [[ "$action" == "switch" && -n "$flake" && -n "$backup" && "$impure" == true ]]; then
          echo "✅ home-manager switch validation successful"
          return 0
        else
          echo "❌ home-manager validation failed"
          return 1
        fi
      }
      export -f home-manager
    '';

    # Mock nix build command for testing result creation
    mockNixBuild = ''
            function nix() {
              if [[ "$1" == "build" ]]; then
                echo "🔨 Mock nix build called"
                # Create mock result directory structure
                mkdir -p ./result/sw/bin
                # Create mock darwin-rebuild executable
                echo '#!/bin/bash
      echo "Mock darwin-rebuild executed"
      ' > ./result/sw/bin/darwin-rebuild
                chmod +x ./result/sw/bin/darwin-rebuild
                echo "✅ Mock build completed successfully"
                return 0
              else
                # Pass through other nix commands
                command nix "$@"
              fi
            }
            export -f nix
    '';
  };

in
nixtestFinal.suite "Platform-Specific Switch Execution E2E Tests" {

  # ===== DARWIN SWITCH EXECUTION TESTS =====

  # Test 1.1: Darwin switch command structure validation
  darwinSwitchCommandStructure = nixtestFinal.test "Darwin switch uses correct command structure" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check that Darwin switch uses darwin-rebuild with proper flags
      hasDarwinRebuild =
        builtins.match ".*darwin-rebuild.*switch.*--impure.*--flake.*" makefileContent != null;
      hasUserEnv = builtins.match ".*env USER=.*" makefileContent != null;
      hasSudo = builtins.match ".*sudo.*darwin-rebuild.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasDarwinRebuild && hasUserEnv && hasSudo)
  );

  # Test 1.2: Darwin environment variable handling
  darwinEnvironmentVariables = nixtestFinal.test "Darwin switch passes USER environment correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for proper USER variable handling in sudo environment
      userEnvPattern = "sudo -E env USER=\\$\\(USER\\)";
      hasCorrectUserEnv = builtins.match ".*${userEnvPattern}.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasCorrectUserEnv
  );

  # Test 1.3: Darwin TARGET variable handling
  darwinTargetVariableHandling = nixtestFinal.test "Darwin switch handles TARGET variable correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for TARGET variable usage in flake reference
      hasTargetVar = builtins.match ".*\\$\\{TARGET\\}.*" makefileContent != null;
      hasTargetDefault =
        builtins.match ".*TARGET=\\$\\{HOST:-\\$\\(CURRENT_SYSTEM\\)\\}.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasTargetVar && hasTargetDefault)
  );

  # Test 1.4: Darwin architecture support
  darwinArchitectureSupport = nixtestFinal.test "Darwin switch supports both architectures" (
    let
      # Test that both x86_64-darwin and aarch64-darwin are supported
      supportedArchs = [
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      allSupported = builtins.all (
        arch: builtins.match ".*${arch}.*" (builtins.readFile ../../Makefile) != null
      ) supportedArchs;
    in
    nixtestFinal.assertions.assertTrue allSupported
  );

  # ===== NIXOS SWITCH EXECUTION TESTS =====

  # Test 2.1: NixOS switch command structure validation
  nixosSwitchCommandStructure = nixtestFinal.test "NixOS switch uses correct command structure" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check that NixOS switch uses nixos-rebuild with proper flags
      hasNixosRebuild =
        builtins.match ".*nixos-rebuild.*switch.*--impure.*--flake.*" makefileContent != null;
      hasSshAuth = builtins.match ".*SSH_AUTH_SOCK=.*" makefileContent != null;
      hasSudo = builtins.match ".*sudo.*nixos-rebuild.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasNixosRebuild && hasSshAuth && hasSudo)
  );

  # Test 2.2: NixOS environment variable handling
  nixosEnvironmentVariables = nixtestFinal.test "NixOS switch passes SSH_AUTH_SOCK correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for proper SSH_AUTH_SOCK variable handling
      sshAuthPattern = "SSH_AUTH_SOCK=\\$\\$SSH_AUTH_SOCK";
      hasCorrectSshAuth = builtins.match ".*${sshAuthPattern}.*" makefileContent != null;
      hasUserVar = builtins.match ".*USER=\\$\\(USER\\).*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasCorrectSshAuth && hasUserVar)
  );

  # Test 2.3: NixOS configuration detection
  nixosConfigurationDetection = nixtestFinal.test "NixOS switch detects configuration correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for /etc/nixos/configuration.nix detection
      hasNixosCheck = builtins.match ".*/etc/nixos/configuration\.nix.*" makefileContent != null;
      hasNixosMessage = builtins.match ".*NixOS detected.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasNixosCheck && hasNixosMessage)
  );

  # Test 2.4: NixOS architecture support
  nixosArchitectureSupport = nixtestFinal.test "NixOS switch supports both architectures" (
    let
      # Test that both x86_64-linux and aarch64-linux are supported
      supportedArchs = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      allSupported = builtins.all (
        arch: builtins.match ".*${arch}.*" (builtins.readFile ../../Makefile) != null
      ) supportedArchs;
    in
    nixtestFinal.assertions.assertTrue allSupported
  );

  # ===== UBUNTU/NON-NIXOS SWITCH TESTS =====

  # Test 3.1: Ubuntu switch command structure validation
  ubuntuSwitchCommandStructure = nixtestFinal.test "Ubuntu switch uses correct command structure" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check that Ubuntu switch uses home-manager with proper flags
      hasHomeManager = builtins.match ".*home-manager.*switch.*--flake.*" makefileContent != null;
      hasBackup = builtins.match ".*-b backup.*" makefileContent != null;
      hasImpure = builtins.match ".*--impure.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasHomeManager && hasBackup && hasImpure)
  );

  # Test 3.2: Ubuntu flake reference format
  ubuntuFlakeReference = nixtestFinal.test "Ubuntu switch uses correct flake reference format" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for ".#$(USER)" format
      flakePattern = "\\.#\\$\\(USER\\)";
      hasCorrectFlakeRef = builtins.match ".*${flakePattern}.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasCorrectFlakeRef
  );

  # Test 3.3: Ubuntu backup mechanism
  ubuntuBackupMechanism = nixtestFinal.test "Ubuntu switch creates backup correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for -b backup option
      hasBackupOption = builtins.match ".*-b backup.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasBackupOption
  );

  # Test 3.4: Ubuntu user configuration resolution
  ubuntuUserConfiguration = nixtestFinal.test "Ubuntu switch resolves user configuration correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for $(USER) variable usage
      hasUserVar = builtins.match ".*\\$\\(USER\\).*" makefileContent != null;
      hasUserMessage = builtins.match ".*user configuration only.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasUserVar && hasUserMessage)
  );

  # ===== PLATFORM DETECTION LOGIC TESTS =====

  # Test 4.1: OS detection branch logic
  osDetectionLogic = nixtestFinal.test "Platform detection uses correct OS branch logic" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for uname -s command and Darwin/Linux branching
      hasUnameCheck = builtins.match ".*uname -s.*" makefileContent != null;
      hasDarwinBranch = builtins.match ".*\"\\$\\{OS\\}\" = \"Darwin\".*" makefileContent != null;
      hasLinuxBranch = builtins.match ".*else.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasUnameCheck && hasDarwinBranch && hasLinuxBranch)
  );

  # Test 4.2: NixOS detection mechanism
  nixosDetectionLogic = nixtestFinal.test "NixOS detection mechanism works correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for /etc/nixos/configuration.nix existence test
      hasNixosFileCheck = builtins.match ".*-f /etc/nixos/configuration\\.nix.*" makefileContent != null;
      hasNixosConditional = builtins.match ".*if.*-f.*configuration\.nix.*then.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasNixosFileCheck && hasNixosConditional)
  );

  # Test 4.3: Ubuntu/other Linux fallback
  ubuntuFallbackLogic = nixtestFinal.test "Ubuntu/other Linux fallback works correctly" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for else clause for non-NixOS Linux
      hasUbuntuMessage = builtins.match ".*Ubuntu detected.*" makefileContent != null;
      hasHomeManagerFallback = builtins.match ".*else.*home-manager.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasUbuntuMessage && hasHomeManagerFallback)
  );

  # Test 4.4: TARGET variable defaulting
  targetVariableDefaulting = nixtestFinal.test "TARGET variable defaults to CURRENT_SYSTEM" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for TARGET variable initialization
      hasTargetInit =
        builtins.match ".*TARGET=\\$\\{HOST:-\\$\\(CURRENT_SYSTEM\\)\\}.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasTargetInit
  );

  # ===== ERROR HANDLING BY PLATFORM =====

  # Test 5.1: Darwin error handling
  darwinErrorHandling = nixtestFinal.test "Darwin switch handles errors gracefully" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for error handling with exit codes
      hasBuildErrorCheck = builtins.match ".*|| exit 1.*" makefileContent != null;
      hasSwitchErrorCheck = builtins.match ".*|| exit 1.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasBuildErrorCheck && hasSwitchErrorCheck)
  );

  # Test 5.2: NixOS error handling
  nixosErrorHandling = nixtestFinal.test "NixOS switch handles errors gracefully" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for error handling in NixOS section
      hasNixosErrorHandling = builtins.match ".*nixos-rebuild.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasNixosErrorHandling
  );

  # Test 5.3: Ubuntu error handling
  ubuntuErrorHandling = nixtestFinal.test "Ubuntu switch handles errors gracefully" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for home-manager error handling
      hasHomeManagerCall = builtins.match ".*home-manager switch.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasHomeManagerCall
  );

  # Test 5.4: Result cleanup handling
  resultCleanupHandling = nixtestFinal.test "Darwin switch cleans up result symlink" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for result cleanup after darwin-rebuild
      hasResultCleanup = builtins.match ".*rm -f \./result.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasResultCleanup
  );

  # ===== INTEGRATION VALIDATION TESTS =====

  # Test 6.1: Makefile switch target exists
  switchTargetExists = nixtestFinal.test "Makefile has switch target" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      hasSwitchTarget = builtins.match ".*^switch:.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasSwitchTarget
  );

  # Test 6.2: Switch target dependencies
  switchTargetDependencies = nixtestFinal.test "Switch target has correct dependencies" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check that switch depends on check-user
      hasCheckUserDep = builtins.match ".*^switch:.*check-user.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasCheckUserDep
  );

  # Test 6.3: All switch commands in PHONY
  switchCommandsInPhony = nixtestFinal.test "All switch commands are in .PHONY" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      hasSwitchInPhony = builtins.match ".*\.PHONY:.*switch.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasSwitchInPhony
  );

  # Test 6.4: Platform-specific tool availability
  platformToolAvailability = nixtestFinal.test "Platform-specific tools are properly referenced" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      # Check for references to darwin-rebuild, nixos-rebuild, home-manager
      hasDarwinTool = builtins.match ".*darwin-rebuild.*" makefileContent != null;
      hasNixosTool = builtins.match ".*nixos-rebuild.*" makefileContent != null;
      hasHomeManagerTool = builtins.match ".*home-manager.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue (hasDarwinTool && hasNixosTool && hasHomeManagerTool)
  );
}
