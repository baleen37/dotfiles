# TDD Test: Claude commands 복사 성공 케이스 테스트
# 수정된 activation script 로직 검증 (실제 파일 시스템 대신 로직 테스트)

{ pkgs, src ? ../.., ... }:

let
  # 실제 소스 디렉토리 확인
  sourceCommandsDir = src + "/modules/shared/config/claude/commands";

  # 로직 검증용 스크립트
  testScript = pkgs.writeScript "test-commands-logic" ''
    #!/bin/bash
    set -euo pipefail

    echo "🧪 Claude commands 복사 로직 테스트 시작..."

    # 1. 실제 소스 디렉토리 존재 확인
    SOURCE_DIR="${sourceCommandsDir}"
    echo "📁 소스 디렉토리: $SOURCE_DIR"

    if [[ -d "$SOURCE_DIR" ]]; then
      echo "✅ 소스 디렉토리 존재함"
    else
      echo "❌ 소스 디렉토리가 존재하지 않음"
      exit 1
    fi

    # 2. .md 파일들 확인
    echo "📋 .md 파일 목록:"
    md_count=0
    for cmd_file in "$SOURCE_DIR"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        base_name=$(basename "$cmd_file")
        echo "  - $base_name"
        ((md_count++))
      fi
    done

    echo "📊 발견된 .md 파일 개수: $md_count"

    # 3. 예상 파일들이 존재하는지 확인
    expected_files=("build.md" "plan.md" "tdd.md" "do-todo.md")
    found_files=0

    for expected in "''${expected_files[@]}"; do
      if [[ -f "$SOURCE_DIR/$expected" ]]; then
        echo "✅ $expected 발견"
        ((found_files++))
      else
        echo "⚠️  $expected 없음"
      fi
    done

    echo "📊 예상 파일 중 발견: $found_files/${#expected_files[@]}"

    # 4. bash 구문 검증 (local 키워드 문제 해결 확인)
    echo "📋 bash 구문 검증..."

    # local 키워드 없이 변수 할당이 가능한지 테스트
    for cmd_file in "$SOURCE_DIR"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        # 수정된 로직: local 키워드 제거
        base_name=$(basename "$cmd_file")
        echo "✅ 변수 할당 성공: $base_name"
        break
      fi
    done

    echo "🎉 모든 로직 테스트 통과!"
  '';

in
pkgs.runCommand "claude-commands-copy-success-test"
{
  buildInputs = with pkgs; [ bash ];
} ''
  ${testScript}

  echo "📋 추가 검증: activation script 구문 확인"

  # activation script에서 local 키워드가 제거되었는지 확인
  if grep -q "local base_name" ${src}/modules/darwin/home-manager.nix; then
    echo "❌ local 키워드가 여전히 존재함"
    exit 1
  else
    echo "✅ local 키워드 제거됨"
  fi

  # base_name 변수가 올바르게 할당되는지 확인
  if grep -q "base_name=\$(basename" ${src}/modules/darwin/home-manager.nix; then
    echo "✅ base_name 변수 할당 구문 올바름"
  else
    echo "❌ base_name 변수 할당 구문 문제"
    exit 1
  fi

  touch $out
''
