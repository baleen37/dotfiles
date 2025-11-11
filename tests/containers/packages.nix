# Packages container test
{ pkgs, lib, ... }:

let
  user = builtins.getEnv "USER";
  testPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    jq
  ];
in {
  name = "packages-test";

  nodes.machine = {
    system.stateVersion = "24.11";

    users.users.${user} = {
      isNormalUser = true;
      home = "/home/${user}";
    };

    # Test packages
    environment.systemPackages = testPackages;
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")

    # Test each package is available
    ${lib.concatMapStringsSep "\n" (pkg: ''
      machine.succeed("which ${lib.getName pkg}")
    '') testPackages}

    # Test basic functionality
    machine.succeed("git --version")
    machine.succeed("vim --version | head -1")
    machine.succeed("curl --version | head -1")
  '';
}
