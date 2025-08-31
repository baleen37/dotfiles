# 빌드 최적화 라이브러리 테스트
# lib/build-optimization.nix 검증

{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib }:

let
  # 테스트 대상 모듈 import
  buildOptimization = import ../../lib/build-optimization.nix {
    inherit lib pkgs;
    system = pkgs.system;
  };

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
  };

  # 테스트 실행
  runTests = [
    # 기본 최적화 설정 테스트
    (testUtils.assertExists buildOptimization "빌드 최적화 모듈")

    # 빌드 최적화 설정 테스트
    (testUtils.assertExists buildOptimization.buildOptimization "buildOptimization 설정")

    # 병렬 설정 테스트
    (testUtils.assertExists buildOptimization.buildOptimization.parallelSettings "parallelSettings")

    # 캐시 설정 테스트
    (testUtils.assertExists buildOptimization.buildOptimization.cacheSettings "cacheSettings")

    # 빌드 환경 설정 테스트
    (testUtils.assertExists buildOptimization.buildOptimization.buildEnv "buildEnv")

    # 함수 테스트
    (testUtils.assertExists buildOptimization.mkOptimizedDerivation "mkOptimizedDerivation 함수")
    (testUtils.assertExists buildOptimization.rebuildTriggerAnalysis "rebuildTriggerAnalysis")
    (testUtils.assertExists buildOptimization.cacheStrategy "cacheStrategy")
    (testUtils.assertExists buildOptimization.performanceUtils "performanceUtils")
  ];

in
pkgs.runCommand "test-build-optimization" { } ''
  echo "Build Optimization Library 테스트 시작"
  echo "========================================"

  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") runTests)}

  echo ""
  echo "========================================"
  echo "Build Optimization 테스트 완료!"

  touch $out
''
