# ABOUTME: Claude 명령어 파일 복사 기능에 대한 단위 테스트
# ABOUTME: mkCommandFiles 함수가 올바르게 명령어 파일들을 복사하는지 검증

{ pkgs, lib, ... }:

let
  # 테스트용 임시 명령어 디렉토리 생성
  testCommandsDir = pkgs.runCommand "test-commands" {} ''
    mkdir -p $out
    echo "# Test Command 1" > $out/test1.md
    echo "# Test Command 2" > $out/test2.md
    echo "not a markdown file" > $out/test.txt
  '';

  # 실제 files.nix에서 사용하는 mkCommandFiles 함수 복사
  mkCommandFiles = dir:
    let files = builtins.readDir dir;
    in lib.concatMapAttrs (name: type:
      if type == "regular" && lib.hasSuffix ".md" name
      then { 
        "/tmp/.claude/commands/${name}".text = builtins.readFile (dir + "/${name}");
      }
      else {}
    ) files;

  # 실제 commands 디렉토리 테스트
  actualCommandsResult = mkCommandFiles ../modules/shared/config/claude/commands;
  
  # 테스트 commands 디렉토리 테스트  
  testCommandsResult = mkCommandFiles testCommandsDir;

in
{
  name = "claude-commands-copy-unit-test";
  
  meta = {
    description = "Claude 명령어 파일 복사 기능 단위 테스트";
  };

  script = ''
    echo "🧪 Claude 명령어 파일 복사 테스트 시작..."
    
    # 1. 실제 commands 디렉토리에서 파일 감지 테스트
    echo "📁 실제 commands 디렉토리 파일 감지 테스트"
    expected_files=(build.md do-todo.md fix-github-issue.md plan-tdd.md plan.md tdd.md verify-pr.md)
    
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
      if [[ "${path}" == *"/build.md" ]]; then
        echo "✅ build.md 파일 감지됨: ${path}"
        if [[ "${content.text or ""}" == *"build"* ]]; then
          echo "✅ build.md 내용 확인됨"
        else
          echo "❌ build.md 내용이 비어있거나 잘못됨"
          exit 1
        fi
      fi
    '') actualCommandsResult)}
    
    # 2. 테스트 디렉토리에서 파일 감지 테스트
    echo "📁 테스트 디렉토리 파일 감지 테스트"
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
      echo "✅ 테스트 파일 감지됨: ${path}"
    '') testCommandsResult)}
    
    # 3. .md 파일만 필터링되는지 테스트
    echo "🔍 .md 파일 필터링 테스트"
    total_result_count=$(echo '${builtins.toJSON testCommandsResult}' | jq '. | length')
    if [[ $total_result_count -eq 2 ]]; then
      echo "✅ .md 파일만 올바르게 필터링됨 (2개 파일)"
    else
      echo "❌ 파일 필터링 실패: $total_result_count개 파일 (예상: 2개)"
      exit 1
    fi
    
    # 4. 빈 결과가 아닌지 테스트
    echo "📊 결과 유효성 테스트"
    actual_count=$(echo '${builtins.toJSON actualCommandsResult}' | jq '. | length')
    if [[ $actual_count -gt 0 ]]; then
      echo "✅ 실제 명령어 파일들이 감지됨: $actual_count개"
    else
      echo "❌ 실제 명령어 파일이 감지되지 않음"
      exit 1
    fi
    
    echo "🎉 모든 Claude 명령어 파일 복사 테스트 통과!"
  '';
}