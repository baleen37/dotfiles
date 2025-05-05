{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Raycast 관련 설정
  home.packages = with pkgs; [
    raycast
  ];

  # 기타 설정...
}
