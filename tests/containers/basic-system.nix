# Basic NixOS system container test
{ pkgs, lib, ... }:

let
  # Use static test user for environment independence
  userName = "testuser";
in
{
  name = "basic-system-test";

  nodes.machine = {
    # Basic NixOS configuration
    system.stateVersion = "24.11";

    # User setup - use static test user
    users.users.${userName} = {
      isNormalUser = true;
      home = "/home/${userName}";
    };

    # Essential services
    services.openssh.enable = true;

    # Test packages
    environment.systemPackages = with pkgs; [
      git
      vim
    ];
  };

  testScript = ''
    start_all()

    # Wait for system to be ready
    machine.wait_for_unit("multi-user.target")

    # Verify basic functionality
    machine.succeed("which git")
    machine.succeed("which vim")
    machine.succeed("systemctl is-active sshd")

    print("✅ Basic system test passed")
  '';
}
