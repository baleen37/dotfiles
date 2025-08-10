{ config, pkgs, lib, ... }:

let
  getUser = import ../../lib/user-resolution.nix {
    returnFormat = "string";
  };
  user = getUser;
in

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
  ];

  # Nix 설정은 완전히 Determinate Nix가 관리
  # /etc/nix/nix.conf 및 /etc/nix/nix.custom.conf에서 설정됨
  nix = {
    enable = false; # Determinate Nix와 충돌 방지를 위해 완전 비활성화
  };

  # 시스템 설정을 최소화하여 root 권한 요구사항 제거
  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;

    # 시스템 기본값 설정 완전 제거 (root 권한 필요)
    # defaults = {}; # 주석 처리

    # activation script를 사용자 레벨로 이동 또는 제거
    # activationScripts = {}; # 주석 처리
  };

  # 사용자 레벨에서만 zsh 사용 (시스템 레벨 shells 제거)
  # environment.shells = [ pkgs.zsh ]; # 주석 처리
  # programs.zsh.enable = true; # 주석 처리

  # 앱 링크도 사용자 레벨로 이동
  # system.nixAppLinks = {}; # 주석 처리
}
