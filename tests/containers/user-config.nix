# User configuration container test (placeholder - implemented in Task 2)
{ pkgs, lib, ... }:

let
  user = builtins.getEnv "USER";
in {
  name = "user-config-test";

  nodes.machine = {
    system.stateVersion = "24.11";

    users.users.${user} = {
      isNormalUser = true;
      home = "/home/${user}";
    };

    services.openssh.enable = true;
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("echo 'Placeholder test - will be implemented in Task 2'")
  '';
}
