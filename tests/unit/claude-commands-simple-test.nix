# TDD Test: Claude commands 복사 로직 간단 검증

{ pkgs, src ? ../.., ... }:

pkgs.runCommand "claude-commands-simple-test"
{
  buildInputs = with pkgs; [ bash ];
} ''
  echo "🧪 Claude commands 간단 테스트 시작..."

  # 1. 소스 디렉토리 존재 확인
  SOURCE_DIR="${src}/modules/shared/config/claude/commands"
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
      md_count=$((md_count + 1))
    fi
  done

  echo "📊 발견된 .md 파일 개수: $md_count"

  if [[ $md_count -gt 0 ]]; then
    echo "✅ 명령어 파일들이 존재함"
  else
    echo "❌ 명령어 파일이 없음"
    exit 1
  fi

  # 3. activation script 구문 확인
  echo "📋 activation script 구문 확인"

  # local 키워드가 제거되었는지 확인
  if grep -q "local base_name" ${src}/modules/darwin/home-manager.nix; then
    echo "❌ local 키워드가 여전히 존재함"
    exit 1
  else
    echo "✅ local 키워드 제거됨"
  fi

  # base_name 변수가 올바르게 할당되는지 확인
  if grep -q "base_name=.*basename" ${src}/modules/darwin/home-manager.nix; then
    echo "✅ base_name 변수 할당 구문 올바름"
  else
    echo "❌ base_name 변수 할당 구문 문제"
    exit 1
  fi

  echo "🎉 모든 테스트 통과!"
  touch $out
''
