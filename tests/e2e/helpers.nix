# E2E Test Helper Functions
#
# 공통 헬퍼 함수 모음으로 중복 코드 제거 및 재사용성 향상

{ lib
, pkgs
, platformSystem
,
}:

{
  # 모듈 import 성공 여부 검증
  # tryEval 패턴을 단순화
  canImport =
    path:
    let
      result = builtins.tryEval (import path);
    in
    result.success;

  # 모듈 import 후 특정 조건 검증
  canImportWith =
    path: args:
    let
      result = builtins.tryEval (import path args);
    in
    result.success;

  # 플랫폼별 경로 검증
  # Darwin/Linux 조건 로직 중복 제거
  checkPlatformPath =
    darwinPath: linuxPath:
    if platformSystem.isDarwin then
      builtins.pathExists darwinPath
    else if platformSystem.isLinux then
      builtins.pathExists linuxPath
    else
      true;

  # 플랫폼별 스크립트 존재 검증
  checkPlatformScript =
    scriptBaseName:
    let
      darwinScript = "../../scripts/${scriptBaseName}-darwin.sh";
      linuxScript = "../../scripts/${scriptBaseName}-linux.sh";
    in
    if platformSystem.isDarwin then
      builtins.pathExists darwinScript
    else if platformSystem.isLinux then
      builtins.pathExists linuxScript
    else
      true;

  # 플랫폼별 모듈 import 검증
  checkPlatformModule =
    darwinModule: linuxModule:
    if platformSystem.isDarwin then
      let
        result = builtins.tryEval (import darwinModule);
      in
      result.success
    else if platformSystem.isLinux then
      let
        result = builtins.tryEval (import linuxModule);
      in
      result.success
    else
      true;

  # 패키지 리스트 검증
  # 모든 패키지가 null이 아닌지 확인
  allPackagesExist = packages: builtins.all (pkg: pkg != null) packages;

  # 여러 경로 존재 여부 동시 검증
  allPathsExist = paths: builtins.all builtins.pathExists paths;

  # 설정 디렉토리 구조 검증
  checkConfigStructure =
    basePath: requiredPaths:
    let
      fullPaths = builtins.map (p: "${basePath}/${p}") requiredPaths;
    in
    builtins.all builtins.pathExists fullPaths;

  # 사용자 설정 검증용 홈 디렉토리 생성
  getUserHomeDir =
    user:
    if platformSystem.isDarwin then "/Users/${user}" else "/home/${user}";

  # 공통 테스트 상수
  constants = {
    # 공통 테스트 사용자
    testUsers = [
      "baleen"
      "jito"
      "user"
      "runner"
      "ubuntu"
    ];

    # 필수 빌드 패키지
    requiredBuildPackages = [
      pkgs.git
      pkgs.nix
      pkgs.gnumake
    ];

    # 필수 개발 도구
    essentialDevTools = [
      pkgs.git
      pkgs.vim
      pkgs.zsh
      pkgs.tmux
      pkgs.gnumake
    ];

    # 필수 포맷팅 도구
    formattingTools = [
      pkgs.nixfmt-rfc-style
      pkgs.pre-commit
    ];

    # Home Manager 상태 버전
    stateVersion = "24.05";
  };
}
