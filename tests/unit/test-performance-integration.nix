# 성능 통합 라이브러리 테스트
# lib/performance-integration.nix 검증

{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, system ? builtins.currentSystem }:

let
  # 테스트 대상 모듈 import
  performanceIntegration = import ../../lib/performance-integration.nix {
    inherit lib system;
    pkgs = pkgs;
    inputs = { };
    self = ./.;
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

    assertType = expectedType: value: name:
      let actualType = builtins.typeOf value;
      in if actualType == expectedType
      then "✅ ${name}: ${actualType} 타입"
      else "❌ ${name}: expected ${expectedType}, got ${actualType}";
  };

  # 테스트 실행
  runTests = [
    # 성능 최적화 모듈 존재 확인
    (testUtils.assertExists performanceIntegration "성능 통합 모듈")

    # 성능 최적화 기능들 확인
    (testUtils.assertExists performanceIntegration.performanceOptimizations "performanceOptimizations")

    # derivation 최적화 확인
    (testUtils.assertExists performanceIntegration.performanceOptimizations.optimizeDerivation "optimizeDerivation")

    # 패키지 최적화 확인
    (testUtils.assertExists performanceIntegration.performanceOptimizations.optimizePackages "optimizePackages")

    # Dev Shell 최적화 확인
    (testUtils.assertExists performanceIntegration.performanceOptimizations.mkOptimizedDevShell "mkOptimizedDevShell")

    # 성능 모니터링 확인
    (testUtils.assertExists performanceIntegration.performanceMonitoring "performanceMonitoring")
  ];

in
pkgs.runCommand "test-performance-integration" { } ''
  echo "Performance Integration Library 테스트 시작"
  echo "============================================="

  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") runTests)}

  echo ""
  echo "============================================="
  echo "Performance Integration 테스트 완료!"

  touch $out
''
