let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    system = "x86_64-linux";
  };
  makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");
in
makeTest {
  name = "homerow-basic";
  nodes.machine = { pkgs, ... }: {
    services.homerow.enable = true;
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("pgrep Homerow")
  '';
}
