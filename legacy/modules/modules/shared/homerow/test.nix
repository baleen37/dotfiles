{ nixpkgs ? import <nixpkgs> {} }:
nixpkgs.lib.nixosTest {
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

