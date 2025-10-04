{ config
, pkgs
, lib
, ...
}:

let
  getUser = import ../../lib/user-resolution.nix {
    returnFormat = "string";
  };
  user = getUser;
in

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/app-links.nix
    ../../modules/darwin/nix-gc.nix # macOS 전용 갈비지 컬렉션 설정
    ../../modules/shared
  ];

  # Allow unfree packages (system level for useGlobalPkgs)
  nixpkgs.config.allowUnfree = true;

  # Nix 설정은 완전히 Determinate Nix가 관리
  # /etc/nix/nix.conf 및 /etc/nix/nix.custom.conf에서 설정됨
  # 갈비지 컬렉션만 활성화하고 나머지는 Determinate Nix가 관리
  nix = {
    enable = false; # Determinate Nix와 충돌 방지

    # Determinate Nix와 충돌하지 않는 최소 설정만 유지
    # 갈비지 컬렉션 설정은 modules/darwin/nix-gc.nix에서 관리

    # 모든 nix 설정을 Determinate가 관리하도록 함
    # - trusted-users: /etc/nix/nix.custom.conf에서 수동 설정 필요
    # - substituters: Determinate가 FlakeHub와 기본 캐시 제공
    # - 수동 설정 방법: sudo vi /etc/nix/nix.custom.conf
    #   trusted-users = root @admin baleen
  };

  # zsh 프로그램 활성화 (시스템 레벨은 제거하고 사용자 레벨에서 처리)
  # environment.shells = [ pkgs.zsh ];  # Root 권한 필요 - 제거
  programs.zsh.enable = true;

  # Nix 앱들을 /Applications에 자동으로 심볼릭 링크 생성 - Root 권한 필요하므로 비활성화
  system.nixAppLinks = {
    enable = false; # Root 권한 필요 - 비활성화
    # apps = [
    #   "Karabiner-Elements.app"
    # ];
  };

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;

    # Root 권한이 필요한 activation scripts 제거
    # 대신 Home Manager의 home.activation에서 사용자 레벨로 처리
    # activationScripts는 시스템 레벨 변경이므로 root 권한 필요

    # 시스템 기본값 설정도 root 권한이 필요할 수 있으므로 제거
    # 대신 Home Manager의 targets.darwin.defaults에서 사용자 레벨로 처리
    # defaults = {  # Root 권한이 필요할 수 있음 - Home Manager로 이동
    #   ...
    # };
  };
}
