# NixOS inside WSL2 on Windows. Boot, networking, and the login user come from
# NixOS-WSL, so this does not import vm-shared.nix (bootloader and DHCP there
# are VM-only).
{
  inputs,
  currentSystemName,
  currentSystemUser,
  ...
}:
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl.enable = true;
  wsl.defaultUser = currentSystemUser;

  # `make switch` picks the flake output by `hostname -s`.
  networking.hostName = currentSystemName;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
