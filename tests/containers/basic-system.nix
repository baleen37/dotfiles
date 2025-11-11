# Basic NixOS system container test
{ pkgs, lib, ... }:

let
  user = builtins.getEnv "USER";
in {
  name = "basic-system-test";

  nodes.machine = {
    # Basic NixOS configuration
    system.stateVersion = "24.11";

    # User setup
    users.users.${user} = {
      isNormalUser = true;
      home = "/home/${user}";
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
}
