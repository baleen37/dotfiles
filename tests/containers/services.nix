# Services container test
{ pkgs, lib, ... }:

let
  # Use static test user for environment independence
  userName = "testuser";
in
{
  name = "services-test";

  nodes.machine = {
    system.stateVersion = "24.11";

    users.users.${userName} = {
      isNormalUser = true;
      home = "/home/${userName}";
      extraGroups = [ "docker" ];
    };

    # Enable services to test
    services.openssh.enable = true;
    virtualisation.docker.enable = true;

    networking.firewall.enable = false;
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")

    # Test SSH service
    machine.succeed("systemctl is-active sshd")
    machine.succeed("ss --listen | grep ':22'")

    # Test Docker service (if available)
    machine.wait_for_unit("docker.service", timeout=60)
    machine.succeed("docker --version")

    print("✅ Services test passed")
  '';
}
