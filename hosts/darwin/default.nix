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

  # Nix 설정 - Determinate Nix와 호환되도록 최소 설정만 유지
  # /etc/nix/nix.conf 및 /etc/nix/nix.custom.conf는 Determinate가 관리
  # 갈비지 컬렉션은 modules/darwin/nix-gc.nix에서 관리
  nix = {
    # linux-builder를 사용하려면 enable = true 필요
    # Determinate Nix와 충돌하지 않도록 최소 설정만 활성화
    # enable = true;

    # Linux builder for NixOS VM tests on macOS - 주석 처리 (Determinate Nix 충돌 방지)
    # linux-builder = {
    #   enable = true;
    # };

    # System features for NixOS testing - 주석 처리
    # settings = {
    #   system-features = [ "nixos-test" "apple-virt" ];
    # };

    # Determinate Nix가 관리하는 설정:
    # - trusted-users: /etc/nix/nix.custom.conf에서 수동 설정 필요
    # - substituters: FlakeHub와 기본 캐시 자동 제공
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
