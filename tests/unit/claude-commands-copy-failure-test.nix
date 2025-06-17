# TDD Test: Claude commands 복사 실패 케이스 테스트
# 이 테스트는 activation script의 commands 복사 기능이 실패하는 시나리오를 검증

{ pkgs, src ? ../.., ... }:

let
  # 테스트용 임시 환경 생성
  testEnv = pkgs.runCommand "test-env" { } ''
    mkdir -p $out/claude/commands
    mkdir -p $out/source/commands

    # 소스에는 명령어 파일들이 있음
    echo "# Build Command" > $out/source/commands/build.md
    echo "# Plan Command" > $out/source/commands/plan.md
    echo "# TDD Command" > $out/source/commands/tdd.md

    # 대상 디렉토리에는 아무것도 없음 (복사가 실패할 상황)
  '';

  # activation script의 commands 복사 로직 추출
  copyCommandsScript = pkgs.writeScript "copy-commands" ''
    #!/bin/bash
    set -euo pipefail

    SOURCE_DIR="$1"
    TARGET_DIR="$2"

    echo "SOURCE_DIR: $SOURCE_DIR"
    echo "TARGET_DIR: $TARGET_DIR"

    # 실제 activation script의 로직과 동일
    if [[ -d "$SOURCE_DIR/commands" ]]; then
      for cmd_file in "$SOURCE_DIR/commands"/*.md; do
        if [[ -f "$cmd_file" ]]; then
          local base_name=$(basename "$cmd_file")
          echo "복사 시도: $base_name"
          # 이 부분에서 실패할 것으로 예상
          cp "$cmd_file" "$TARGET_DIR/commands/$base_name" || {
            echo "복사 실패: $base_name"
            exit 1
          }
        fi
      done
    else
      echo "소스 commands 디렉토리가 없음"
      exit 1
    fi
  '';

in
pkgs.runCommand "claude-commands-copy-failure-test"
{
  buildInputs = with pkgs; [ bash ];
} ''
  echo "🧪 Claude commands 복사 실패 테스트 시작..."

  # 1. 소스 디렉토리 확인
  echo "📁 소스 디렉토리 확인"
  ls -la ${testEnv}/source/commands/

  # 2. 대상 디렉토리 상태 확인
  echo "📁 대상 디렉토리 상태 확인"
  ls -la ${testEnv}/claude/commands/

  # 3. 복사 스크립트 실행 (실패할 것으로 예상)
  echo "📋 복사 스크립트 실행"

  # 이 테스트는 실패해야 함 (TDD의 Red 단계)
  if ${copyCommandsScript} ${testEnv}/source ${testEnv}/claude; then
    echo "❌ 테스트 실패: 복사가 성공했지만 실패해야 함"
    exit 1
  else
    echo "✅ 예상대로 복사 실패함"
  fi

  # 4. 복사 후 파일 확인
  echo "📋 복사 후 파일 확인"
  if [[ -f "${testEnv}/claude/commands/build.md" ]]; then
    echo "❌ 파일이 복사됨 (예상하지 않음)"
    exit 1
  else
    echo "✅ 파일이 복사되지 않음 (예상됨)"
  fi

  echo "🎉 Claude commands 복사 실패 테스트 통과!"
  echo "다음 단계: 복사 성공을 위한 구현 수정 필요"

  touch $out
''
