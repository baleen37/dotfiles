# mitchellh/nixos-config 스타일
{ nixpkgs, overlays, inputs }:

name:
{
  system,
  user,
  darwin ? false,
  wsl ? false
}:

let
  # WSL 확인
  isWSL = wsl;

  # Linux 확인 (Darwin과 WSL 제외)
  isLinux = !darwin && !isWSL;

  # 설정 파일 경로
  machineConfig = ../machines/${name}.nix;
  userOSConfig = ../users/${user}/${if darwin then "darwin" else "nixos" }.nix;
  userHMConfig = ../users/${user}/home-manager.nix;

  # 시스템 함수 선택
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager = if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

in systemFunc rec {
  inherit system;

  modules = [
    # 오버레이 적용
    { nixpkgs.overlays = overlays; }

    # unfree 패키지 허용
    { nixpkgs.config.allowUnfree = true; }

    # WSL 모듈 (필요시)
    (if isWSL then inputs.nixos-wsl.nixosModules.wsl else {})

    # 설정 파일들
    machineConfig
    userOSConfig
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import userHMConfig {
        isWSL = isWSL;
        inputs = inputs;
      };
    }

    # 모듈에 추가 인자 전달
    {
      config._module.args = {
        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        isWSL = isWSL;
        inputs = inputs;
      };
    }
  ];
}