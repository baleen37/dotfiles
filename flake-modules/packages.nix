{ inputs, ... }:

let
  lib = inputs.nixpkgs.lib;

  # Disposable VM for manual smoke-testing a NixOS config.
  #   nix run .#test-vm   (ssh testuser@localhost -p 2222, password "test")
  vmOverrides = {
    virtualisation = {
      memorySize = 2048;
      cores = 2;
      diskSize = 10240;
      docker.enable = true;
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
    };

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = true;
    };

    networking.firewall.enable = false;

    users.users.testuser = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      initialPassword = "test";
    };
    security.sudo.wheelNeedsPassword = false;
  };

  mkTestVm =
    system:
    let
      qemuVmModule =
        { modulesPath, ... }:
        {
          imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
        };
      machineModule = builtins.toPath (
        (toString ../machines/nixos) + "/vm-" + lib.head (lib.splitString "-" system) + "-utm.nix"
      );
    in
    (inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        qemuVmModule
        machineModule
        vmOverrides
      ];
    }).config.system.build.vm;
in
{
  perSystem =
    {
      system,
      ...
    }:
    {
      packages = lib.optionalAttrs (lib.hasSuffix "-linux" system) {
        test-vm = mkTestVm system;
      };
    };
}
