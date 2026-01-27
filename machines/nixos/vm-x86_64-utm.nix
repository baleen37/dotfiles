{
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-utm.nix
    ./vm-shared.nix
  ];

  networking.interfaces.enp1s0.useDHCP = true;

  services.spice-vdagentd.enable = true;

  nixpkgs.config.allowUnfree = true;
}
