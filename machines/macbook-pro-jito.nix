{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./hardware/macbook-pro-jito.nix ];

  # jito 맥북 특정 설정
  networking.hostName = "macbook-pro-jito";
}
