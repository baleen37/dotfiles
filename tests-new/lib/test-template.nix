# 통합 테스트 템플릿
# TDD Red-Green-Refactor 패턴을 위한 표준화된 구조

{ pkgs, lib, ... }:

let
  # 공통 테스트 헬퍼 함수들
  testHelpers = {
    # 테스트 실행 기본 구조
    makeTest = name: testBody: pkgs.runCommand "test-${name}" {
      nativeBuildInputs = with pkgs; [ bash curl jq ];
      passthru = { inherit name; };
    } ''
      set -euo pipefail

      echo "🧪 Starting test: ${name}"

      # 테스트 환경 설정
      export TEST_NAME="${name}"
      export TEST_TMPDIR="$TMPDIR/test-${name}"
      mkdir -p "$TEST_TMPDIR"

      # 테스트 실행
      ${testBody}

      echo "✅ Test completed: ${name}"
      touch $out
    '';

    # 통합 테스트를 위한 다중 단계 테스트
    makeIntegrationTest = name: phases: pkgs.runCommand "integration-test-${name}" {
      nativeBuildInputs = with pkgs; [ bash curl jq git ];
      passthru = { inherit name phases; };
    } ''
      set -euo pipefail

      echo "🔄 Starting integration test: ${name}"

      # 각 페이즈 순차 실행
      ${lib.concatMapStringsSep "\n" (phase: ''
        echo "📋 Phase: ${phase.name}"
        ${phase.script}
        echo "✅ Phase completed: ${phase.name}"
      '') phases}

      echo "🎉 Integration test completed: ${name}"
      touch $out
    '';

    # E2E 테스트를 위한 전체 워크플로우 테스트
    makeE2ETest = name: workflow: pkgs.runCommand "e2e-test-${name}" {
      nativeBuildInputs = with pkgs; [ bash curl jq git nix ];
      passthru = { inherit name workflow; };
    } ''
      set -euo pipefail

      echo "🌐 Starting E2E test: ${name}"

      # 임시 작업 환경 생성
      export E2E_WORKSPACE="$TMPDIR/e2e-${name}"
      mkdir -p "$E2E_WORKSPACE"
      cd "$E2E_WORKSPACE"

      # 워크플로우 실행
      ${workflow}

      echo "🏁 E2E test completed: ${name}"
      touch $out
    '';

    # 성능 테스트를 위한 벤치마크 함수
    makePerformanceTest = name: { target, maxTime ? 300, maxMemory ? "1G" }: pkgs.runCommand "perf-test-${name}" {
      nativeBuildInputs = with pkgs; [ bash time gnused ];
      passthru = { inherit name maxTime maxMemory; };
    } ''
      set -euo pipefail

      echo "⚡ Starting performance test: ${name}"

      # 시간 및 메모리 측정
      start_time=$(date +%s)

      ${target}

      end_time=$(date +%s)
      elapsed=$((end_time - start_time))

      if [ $elapsed -gt ${toString maxTime} ]; then
        echo "❌ Performance test failed: ${name} took ${toString elapsed}s (max: ${toString maxTime}s)"
        exit 1
      fi

      echo "✅ Performance test passed: ${name} completed in ${toString elapsed}s"
      touch $out
    '';
  };

  # 공통 어설션 함수들
  assertions = {
    # 파일 존재 확인
    assertFileExists = path: ''
      if [ ! -f "${path}" ]; then
        echo "❌ Assertion failed: File does not exist: ${path}"
        exit 1
      fi
      echo "✅ File exists: ${path}"
    '';

    # 명령어 성공 확인
    assertCommandSucceeds = cmd: ''
      if ! ${cmd}; then
        echo "❌ Assertion failed: Command failed: ${cmd}"
        exit 1
      fi
      echo "✅ Command succeeded: ${cmd}"
    '';

    # 문자열 포함 확인
    assertStringContains = text: pattern: ''
      if ! echo "${text}" | grep -q "${pattern}"; then
        echo "❌ Assertion failed: String does not contain pattern: ${pattern}"
        echo "Actual text: ${text}"
        exit 1
      fi
      echo "✅ String contains pattern: ${pattern}"
    '';

    # 종료 코드 확인
    assertExitCode = cmd: expectedCode: ''
      set +e
      ${cmd}
      actual_code=$?
      set -e

      if [ $actual_code -ne ${toString expectedCode} ]; then
        echo "❌ Assertion failed: Expected exit code ${toString expectedCode}, got $actual_code"
        exit 1
      fi
      echo "✅ Exit code matches: ${toString expectedCode}"
    '';
  };

in {
  inherit testHelpers assertions;

  # 기본 테스트 세트업
  defaultSetup = ''
    # 기본 환경 변수 설정
    export PATH="${lib.makeBinPath (with pkgs; [ bash curl jq git nix ])}:$PATH"
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    # Git 기본 설정
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"
    git config --global init.defaultBranch main
  '';
}
