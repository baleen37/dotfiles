{
  ...
}:
{
  imports = [
    ./hardware/vm-utm.nix
    ./vm-shared.nix
  ];

  networking.interfaces.enp1s0.useDHCP = true;

  services.spice-vdagentd.enable = true;

  nixpkgs.config.allowUnfree = true;
}
