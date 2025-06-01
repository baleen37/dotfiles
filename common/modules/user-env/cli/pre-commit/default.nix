{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    pre-commit
  ];
}
