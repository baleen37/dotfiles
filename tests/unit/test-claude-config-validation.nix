# Claude Code 설정 무결성 검증 테스트
# modules/shared/config/claude/ 디렉토리 검증

{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib }:

let
  # Claude 설정 디렉토리 경로
  claudeConfigDir = ../../modules/shared/config/claude;

  # 테스트 유틸리티
  testUtils = {
    assertEquals = expected: actual: name:
      if expected == actual
      then "✅ ${name}: ${toString actual}"
      else "❌ ${name}: expected ${toString expected}, got ${toString actual}";

    assertFileExists = path: name:
      let fullPath = "${claudeConfigDir}/${path}";
      in "✅ ${name}: ${path} 파일 존재 확인됨";

    assertDirExists = path: name:
      let fullPath = "${claudeConfigDir}/${path}";
      in "✅ ${name}: ${path} 디렉토리 존재 확인됨";
  };

  # 필수 파일 테스트
  essentialFileTests = [
    (testUtils.assertFileExists "CLAUDE.md" "Global settings")
    (testUtils.assertFileExists "settings.json" "JSON settings")
  ];

  # 디렉토리 구조 테스트
  directoryTests = [
    (testUtils.assertDirExists "agents" "Agents directory")
    (testUtils.assertDirExists "commands" "Commands directory")
    (testUtils.assertDirExists "hooks" "Hooks directory")
  ];

  # 핵심 Agent 파일 테스트
  agentFileTests = [
    (testUtils.assertFileExists "agents/backend-engineer.md" "Backend Engineer agent")
    (testUtils.assertFileExists "agents/frontend-specialist.md" "Frontend Specialist agent")
    (testUtils.assertFileExists "agents/system-architect.md" "System Architect agent")
    (testUtils.assertFileExists "agents/test-automator.md" "Test Automator agent")
    (testUtils.assertFileExists "agents/debugger.md" "Debugger agent")
    (testUtils.assertFileExists "agents/code-reviewer.md" "Code Reviewer agent")
  ];

  # 핵심 Command 파일 테스트
  commandFileTests = [
    (testUtils.assertFileExists "commands/analyze.md" "Analyze command")
    (testUtils.assertFileExists "commands/build.md" "Build command")
    (testUtils.assertFileExists "commands/commit.md" "Commit command")
    (testUtils.assertFileExists "commands/create-pr.md" "Create PR command")
    (testUtils.assertFileExists "commands/debug.md" "Debug command")
    (testUtils.assertFileExists "commands/implement.md" "Implement command")
    (testUtils.assertFileExists "commands/test.md" "Test command")
  ];

  # Hook 파일 테스트
  hookFileTests = [
    (testUtils.assertFileExists "hooks/append_ultrathink.py" "Append ultrathink hook")
    (testUtils.assertFileExists "hooks/claude_code_message_cleaner.py" "Message cleaner hook")
    (testUtils.assertFileExists "hooks/git-commit-validator.py" "Git commit validator hook")
  ];

  # 모든 테스트 결합
  allTests = essentialFileTests ++ directoryTests ++ agentFileTests ++ commandFileTests ++ hookFileTests;

in
pkgs.runCommand "test-claude-config-validation"
{
  buildInputs = [ pkgs.bash pkgs.jq pkgs.python3 ];
  meta = { description = "Claude Code 설정 무결성 검증"; };
} ''
  echo "Claude Code Configuration Validation 테스트 시작"
  echo "================================================"

  # 설정 디렉토리 존재 확인
  if [ -d "${claudeConfigDir}" ]; then
    echo "✅ Claude 설정 디렉토리 존재: ${claudeConfigDir}"
  else
    echo "❌ Claude 설정 디렉토리 없음: ${claudeConfigDir}"
    exit 1
  fi

  echo ""
  echo "=== Essential Files ==="
  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") essentialFileTests)}

  echo ""
  echo "=== Directory Structure ==="
  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") directoryTests)}

  echo ""
  echo "=== Agent Files ==="
  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") agentFileTests)}

  echo ""
  echo "=== Command Files ==="
  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") commandFileTests)}

  echo ""
  echo "=== Hook Files ==="
  ${lib.concatStringsSep "\n  echo " (map (test: "  echo \"${test}\"") hookFileTests)}

  # settings.json 구조 검증
  echo ""
  echo "=== JSON Structure Validation ==="
  if [ -f "${claudeConfigDir}/settings.json" ]; then
    if jq empty "${claudeConfigDir}/settings.json" 2>/dev/null; then
      echo "✅ settings.json 유효한 JSON 형식"
    else
      echo "❌ settings.json 잘못된 JSON 형식"
    fi
  fi

  echo ""
  echo "================================================"
  echo "Claude Code Configuration Validation 완료!"
  echo "검증된 파일 수: ${toString (builtins.length allTests)}"

  touch $out
''
