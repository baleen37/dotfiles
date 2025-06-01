{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    syncthing
  ];

  services.syncthing = {
    enable = true;
  };
}
