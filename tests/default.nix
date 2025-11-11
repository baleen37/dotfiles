# tests/default.nix
{
  inputs,
  system,
  self,
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;

  # Import container tests - inline for now to avoid path issues
  containerTests = {
    basic = {
      name = "basic-system-test";

      nodes.machine = {
        # Basic NixOS configuration
        system.stateVersion = "24.11";

        # User setup
        users.users."baleen" = {
          isNormalUser = true;
          home = "/home/baleen";
        };

        # Essential services
        services.openssh.enable = true;

        # Test packages
        environment.systemPackages = with pkgs; [ git vim ];
      };

      testScript = ''
        start_all()

        # Wait for system to be ready
        machine.wait_for_unit("multi-user.target")

        # Verify basic functionality
        machine.succeed("test -f /etc/nixos/configuration.nix")
        machine.succeed("which git")
        machine.succeed("which vim")
        machine.succeed("systemctl is-active sshd")
      '';
    };

    user-config = import ./containers/user-config.nix { inherit pkgs lib inputs self; };
  };

  # Convert to nixosTest checks
  containerChecks = builtins.mapAttrs (name: test:
    pkgs.testers.nixosTest test
  ) containerTests;

  # Automatic test discovery function (nixpkgs pattern)
  # Discovers all *-test.nix files in a directory
  discoverTests =
    dir: prefix:
    lib.pipe (builtins.readDir dir) [
      # Filter for .nix files, excluding helpers
      (lib.filterAttrs (
        name: type:
        type == "regular"
        && lib.hasSuffix "-test.nix" name
        && name != "default.nix"
        && name != "nixtest-template.nix"
      ))
      # Convert filename to test name and import
      (lib.mapAttrs' (
        name: _: {
          name = "${prefix}-${lib.removeSuffix "-test.nix" name}";
          value = import (dir + "/${name}") {
            inherit
              inputs
              system
              pkgs
              lib
              self
              ;
            inherit (nixtest) nixtest;
          };
        }
      ))
    ];

  # Import existing NixTest framework
  nixtest = import ./unit/nixtest-template.nix { inherit pkgs lib; };

  # Import mksystem function for testing
  mkSystem = import ../lib/mksystem.nix { inherit inputs self; };

in
{
  # Smoke test (explicit - it's special)
  smoke = pkgs.runCommand "smoke-test" { } ''
    echo "✅ Test infrastructure ready - automatic discovery enabled"
    touch $out
  '';
}
// containerChecks
// discoverTests ./unit "unit"
// discoverTests ./integration "integration"
