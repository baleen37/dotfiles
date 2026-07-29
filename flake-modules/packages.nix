{ inputs, ... }:

let
  inherit (inputs) nixos-generators;

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
in
{
  perSystem =
    {
      system,
      lib,
      ...
    }:
    {
      packages = lib.optionalAttrs (lib.hasSuffix "-linux" system) {
        test-vm = nixos-generators.nixosGenerate {
          inherit system;
          format = "vm-nogui";
          modules = [
            # Match the guest config to the host arch instead of always
            # building the aarch64 machine.
            ../machines/nixos/vm-${lib.head (lib.splitString "-" system)}-utm.nix
            vmOverrides
          ];
        };
      };
    };
}
