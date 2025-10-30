{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./hardware/vm-aarch64-utm.nix ];

  # VM 특정 설정
  networking.hostName = "vm-aarch64-utm";
}
