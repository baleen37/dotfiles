# Packages container test
{ pkgs, lib, ... }:

let
  # Use static test user for environment independence
  userName = "testuser";
  commonPackages = import ../lib/fixtures/common-packages.nix { inherit pkgs; };
  testPackages = commonPackages.devPackages;
in
{
  name = "packages-test";

  nodes.machine = {
    system.stateVersion = "24.11";

    users.users.${userName} = {
      isNormalUser = true;
      home = "/home/${userName}";
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

    print("Packages test passed")
  '';
}
