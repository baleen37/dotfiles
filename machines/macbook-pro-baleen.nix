{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./hardware/macbook-pro-baleen.nix ];

  # baleen 맥북 특정 설정
  networking.hostName = "macbook-pro-baleen";
}
