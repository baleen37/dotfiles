{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    raycast
  ];
  # 기타 Raycast 관련 설정은 필요시 추가
}
