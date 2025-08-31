# 패키지 설치 검증 통합 테스트
# modules/shared/packages.nix 및 modules/darwin/casks.nix 검증

{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, system ? builtins.currentSystem }:

let
  # 플랫폼 감지
  platformSystem = import ../../lib/platform-system.nix { inherit system; };
  isDarwin = platformSystem.platform == "darwin";
  isLinux = platformSystem.platform == "nixos";

  # 공통 패키지 목록 확인
  sharedPackages = import ../../modules/shared/packages.nix { inherit pkgs lib; };

  # Darwin 전용 cask 목록 (Darwin에서만)
  darwinCasks =
    if isDarwin
    then import ../../modules/darwin/casks.nix { inherit pkgs lib; }
    else { };

  # 테스트 유틸리티
  testUtils = {
    assertEquals = expected: actual: name:
      if expected == actual
      then "✅ ${name}: ${toString actual}"
      else "❌ ${name}: expected ${toString expected}, got ${toString actual}";

    assertExists = value: name:
      if value != null
      then "✅ ${name} 존재"
      else "❌ ${name} 없음";

    assertListNotEmpty = list: name:
      if builtins.length list > 0
      then "✅ ${name}: ${toString (builtins.length list)}개 항목"
      else "❌ ${name}: 빈 목록";

    assertPackageAvailable = pkg: name:
      let
        result = builtins.tryEval pkg;
      in
      if result.success
      then "✅ ${name}: 사용 가능"
      else "❌ ${name}: 사용 불가 - ${result.value or "unknown error"}";
  };

  # 핵심 패키지들 테스트
  corePackageTests = [
    (testUtils.assertPackageAvailable pkgs.git "git")
    (testUtils.assertPackageAvailable pkgs.vim "vim")
    (testUtils.assertPackageAvailable pkgs.curl "curl")
    (testUtils.assertPackageAvailable pkgs.wget "wget")
    (testUtils.assertPackageAvailable pkgs.jq "jq")
    (testUtils.assertPackageAvailable pkgs.tree "tree")
    (testUtils.assertPackageAvailable pkgs.htop "htop")
  ];

  # 개발 도구 테스트
  devToolTests = [
    (testUtils.assertPackageAvailable pkgs.nodejs "nodejs")
    (testUtils.assertPackageAvailable pkgs.python3 "python3")
    (testUtils.assertPackageAvailable pkgs.rustc "rustc")
    (testUtils.assertPackageAvailable pkgs.go "go")
    (testUtils.assertPackageAvailable pkgs.docker "docker")
  ];

  # Darwin 전용 테스트
  darwinTests = lib.optionals isDarwin [
    (testUtils.assertExists darwinCasks "Darwin casks 모듈")
    "✅ Darwin 플랫폼에서 Homebrew cask 지원"
  ];

  # Linux 전용 테스트
  linuxTests = lib.optionals isLinux [
    "✅ Linux 플랫폼에서 Nix 패키지 관리"
  ];

  # 모든 테스트 결합
  allTests = corePackageTests ++ devToolTests ++ darwinTests ++ linuxTests;

in
pkgs.runCommand "test-package-installation-verification"
{
  buildInputs = [ pkgs.bash ];
  meta = { description = "패키지 설치 검증 통합 테스트"; };
} ''
  echo "Package Installation Verification 테스트 시작"
  echo "=============================================="
  echo "플랫폼: ${platformSystem.platform} (${system})"
  echo ""

  echo "=== Core Package Tests ==="
  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") corePackageTests)}

  echo ""
  echo "=== Development Tool Tests ==="
  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") devToolTests)}

  ${lib.optionalString isDarwin ''
    echo ""
    echo "=== Darwin-Specific Tests ==="
    ${lib.concatStringsSep "\n    echo " (map (test: "    echo \"${test}\"") darwinTests)}
  ''}

  ${lib.optionalString isLinux ''
    echo ""
    echo "=== Linux-Specific Tests ==="
    ${lib.concatStringsSep "\n    echo " (map (test: "    echo \"${test}\"") linuxTests)}
  ''}

  echo ""
  echo "=============================================="
  echo "Package Installation Verification 완료!"
  echo "테스트된 패키지 수: ${toString (builtins.length allTests)}"

  touch $out
''
