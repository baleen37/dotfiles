# Services container test
{ pkgs, lib, ... }:

let
  user = builtins.getEnv "USER";
in
{
  name = "services-test";

  nodes.machine = {
    system.stateVersion = "24.11";

    users.users.${user} = {
      isNormalUser = true;
      home = "/home/${user}";
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
  '';
}
