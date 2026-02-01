# Test Builders Library
#
# Builder functions for common E2E test patterns
#
# Provides:
# - mkBasicTest: Create a basic NixOS test with custom config
# - mkUserTest: Create a user config test
# - mkDualMachineTest: Create tests with source/target machines
# - mkDeveloperTest: Create developer workstation test
#
# Usage:
#   import ../lib/test-builders.nix { inherit pkgs lib system nixpkgs; }

{ lib, pkgs, system ? builtins.currentSystem or "x86_64-linux", nixpkgs ? <nixpkgs>, ... }:
let
  # Use nixosTest from pkgs (works in flake context)
  nixosTest =
    pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });
in
rec {
  # Create a basic NixOS test with custom config
  #
  # Parameters:
  #   testName: Name of the test
  #   extraConfig: Additional NixOS configuration to apply
  #   extraPackages: Additional packages to install
  #   testScriptBody: Python test script body (without start_all/shutdown)
  mkBasicTest =
    { testName
    , extraConfig ? { }
    , extraPackages ? [ ]
    , testScriptBody
    , hostname ? "test-vm"
    }:
    nixosTest {
      name = testName;
      nodes.machine =
        { config, pkgs, ... }:
        {
          imports = [
            ../fixtures/basic-system.nix
            ({ ... }: { networking.hostName = hostname; })
          ];

          # Apply extra config
          config = lib.mkIf (extraConfig != { }) extraConfig;

          # Add extra packages
          environment.systemPackages =
            lib.optionals (extraPackages != [ ]) extraPackages;
        };

      testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")
        ${testScriptBody}
        machine.shutdown()
      '';
    };

  # Create a user config test
  #
  # Parameters:
  #   testName: Name of the test
  #   userConfig: User-specific configuration to test
  #   testScriptBody: Python test script body
  mkUserTest =
    { testName
    , userConfig ? { }
    , testScriptBody
    }:
    nixosTest {
      name = testName;
      nodes.machine =
        { config, pkgs, ... }:
        {
          imports = [
            ../fixtures/basic-system.nix
            ../fixtures/test-user.nix
            userConfig
          ];
        };

      testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")
        ${testScriptBody}
        machine.shutdown()
      '';
    };

  # Create a dual machine test (source + target)
  #
  # Parameters:
  #   testName: Name of the test
  #   sourceConfig: Source machine config
  #   targetConfig: Target machine config
  #   testScriptBody: Python test script body
  mkDualMachineTest =
    { testName
    , sourceConfig ? { }
    , targetConfig ? { }
    , testScriptBody
    }:
    nixosTest {
      name = testName;
      nodes = {
        source-machine =
          { config, pkgs, ... }:
          {
            imports = [
              ../fixtures/basic-system.nix
              ../fixtures/test-user.nix
              sourceConfig
            ];
            networking.hostName = "source-machine";
          };
        target-machine =
          { config, pkgs, ... }:
          {
            imports = [
              ../fixtures/basic-system.nix
              ../fixtures/test-user.nix
              targetConfig
            ];
            networking.hostName = "target-machine";
          };
      };

      testScript = ''
        source.start()
        target.start()
        source.wait_for_unit("multi-user.target")
        target.wait_for_unit("multi-user.target")
        ${testScriptBody}
        source.shutdown()
        target.shutdown()
      '';
    };

  # Create a developer workstation test
  #
  # Parameters:
  #   testName: Name of the test
  #   devPackages: Extra development packages
  #   testScriptBody: Python test script body
  mkDeveloperTest =
    { testName
    , devPackages ? [ ]
    , testScriptBody
    }:
    nixosTest {
      name = testName;
      nodes.machine =
        { config, pkgs, ... }:
        {
          imports = [
            ../fixtures/basic-system.nix
            ../fixtures/test-user.nix
          ];

          networking.hostName = "dev-workstation";

          # Enhanced resources for development
          virtualisation.cores = 3;
          virtualisation.memorySize = 4096;
          virtualisation.diskSize = 8192;

          # Development packages
          environment.systemPackages =
            import ../fixtures/common-packages.nix { inherit pkgs; }.comprehensivePackages
            ++ devPackages;

          # Docker support
          virtualisation.docker = {
            enable = lib.mkDefault true;
            enableOnBoot = lib.mkDefault true;
          };
        };

      testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")
        machine.wait_until_succeeds("systemctl is-system-running --wait")
        ${testScriptBody}
        machine.shutdown()
      '';
    };

  # Create a cross-platform test (Darwin + NixOS validation)
  #
  # Parameters:
  #   testName: Name of the test
  #   testScriptBody: Python test script body
  mkCrossPlatformTest =
    { testName
    , testScriptBody
    }:
    nixosTest {
      name = testName;
      nodes.machine =
        { config, pkgs, ... }:
        {
          imports = [
            ../fixtures/basic-system.nix
          ];

          networking.hostName = "cross-platform-test";

          # Import E2E helpers
          environment.systemPackages = import ../fixtures/common-packages.nix { inherit pkgs; }.e2eBasicPackages;
        };

      testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")
        ${testScriptBody}
        machine.shutdown()
      '';
    };
}
