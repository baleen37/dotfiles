{ inputs, self, ... }:

let
  nixpkgs = inputs.nixpkgs;
  nixos-generators = inputs.nixos-generators;
in
{
  perSystem = { system, pkgs, lib, ... }: {
    packages = lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
      test-vm = nixos-generators.nixosGenerate {
        inherit system;
        format = "vm-nogui";
        modules = [
          ../machines/nixos/vm-aarch64-utm.nix
          {
            virtualisation.memorySize = 2048;
            virtualisation.cores = 2;
            virtualisation.diskSize = 10240;

            virtualisation.forwardPorts = [
              {
                from = "host";
                host.port = 2222;
                guest.port = 22;
              }
            ];

            services.openssh.enable = true;
            services.openssh.settings.PasswordAuthentication = true;
            virtualisation.docker.enable = true;
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
          }
        ];
      };
    };
  };

  # E2E tests (only for Linux platforms where VMs can run)
  flake.e2e-tests =
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
    in
    import ../tests/e2e {
      inherit
        pkgs
        lib
        system
        self
        inputs
        ;
    };
}
