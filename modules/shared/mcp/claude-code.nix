# ABOUTME: Claude Code CLI MCP 설정 반자동화 도구
# ABOUTME: Nix 설정과 Claude Code CLI 간의 브릿지 및 동기화 도구

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mcp.claudeCode;

in {
  options.mcp.claudeCode = {
    enable = mkEnableOption "Claude Code CLI MCP 설정 반자동화";

    autoSync = mkOption {
      type = types.bool;
      default = false;
      description = "devShell 진입 시 자동으로 MCP 설정 동기화";
    };

    claudeCodeConfigPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.claude";
      description = "Claude Code CLI 설정 디렉토리 경로";
    };

    projectMcpEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "프로젝트별 MCP 설정 자동 인식 및 제안";
    };

    backupSettings = mkOption {
      type = types.bool;
      default = true;
      description = "설정 변경 전 자동 백업";
    };
  };

  config = mkIf (config.mcp.enable && cfg.enable) {
    # Claude Code MCP 동기화 도구
    home.file.".local/bin/mcp-claude-code-sync" = {
      text = ''
        #!/bin/bash
        # Claude Code CLI MCP 설정 동기화 도구

        set -e

        CLAUDE_CONFIG_DIR="${cfg.claudeCodeConfigPath}"
        PROJECT_ROOT="''${1:-$(pwd)}"
        MODE="''${2:-auto}"  # auto, force, check

        echo "🔄 Claude Code MCP 설정 동기화"
        echo "================================"
        echo "📁 프로젝트: $PROJECT_ROOT"
        echo "⚙️  Claude Config: $CLAUDE_CONFIG_DIR"
        echo "🎯 모드: $MODE"
        echo ""

        cd "$PROJECT_ROOT"

        # Claude Code CLI 설치 확인
        if ! command -v claude-code >/dev/null 2>&1; then
          echo "⚠️  Claude Code CLI가 설치되지 않았습니다"
          echo "💡 설치 방법: https://docs.anthropic.com/claude-code"

          if [ "$MODE" != "force" ]; then
            exit 1
          fi
        fi

        # 프로젝트별 MCP 설정 확인
        PROJECT_MCP_CONFIG=".mcp.json"
        HAS_PROJECT_CONFIG=false

        if [ -f "$PROJECT_MCP_CONFIG" ]; then
          echo "✅ 프로젝트별 MCP 설정 발견: $PROJECT_MCP_CONFIG"
          HAS_PROJECT_CONFIG=true

          # JSON 유효성 검사
          if command -v jq >/dev/null 2>&1; then
            if ! jq empty "$PROJECT_MCP_CONFIG" 2>/dev/null; then
              echo "❌ .mcp.json 파일이 유효하지 않습니다"
              exit 1
            fi

            SERVER_COUNT=$(jq '.mcpServers | length' "$PROJECT_MCP_CONFIG" 2>/dev/null || echo "0")
            echo "🔧 프로젝트 MCP 서버: $SERVER_COUNT개"
          fi
        else
          echo "📋 프로젝트별 MCP 설정 없음"

          if [ "$MODE" = "auto" ]; then
            read -p "🤔 프로젝트별 MCP 설정을 생성하시겠습니까? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
              mcp-project-init "$PROJECT_ROOT" auto
              HAS_PROJECT_CONFIG=true
            fi
          fi
        fi

        # Claude Code 설정 디렉토리 확인
        if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
          echo "📁 Claude Code 설정 디렉토리 생성: $CLAUDE_CONFIG_DIR"
          mkdir -p "$CLAUDE_CONFIG_DIR"
        fi

        # 현재 Claude Code 설정 백업 (옵션)
        if [ "${toString cfg.backupSettings}" = "1" ] && [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]; then
          BACKUP_FILE="$CLAUDE_CONFIG_DIR/CLAUDE.md.backup.$(date +%s)"
          cp "$CLAUDE_CONFIG_DIR/CLAUDE.md" "$BACKUP_FILE"
          echo "💾 기존 설정 백업: $BACKUP_FILE"
        fi

        # MCP 설정 정보 생성
        MCP_INFO_FILE="$CLAUDE_CONFIG_DIR/MCP_PROJECT_INFO.md"

        cat > "$MCP_INFO_FILE" << EOF
        # 프로젝트 MCP 설정 정보

        > 🤖 이 파일은 Nix dotfiles에 의해 자동 생성되었습니다
        > 📁 프로젝트: $PROJECT_ROOT
        > 🕐 생성시간: $(date)

        ## 현재 프로젝트 MCP 설정

        EOF

        if [ "$HAS_PROJECT_CONFIG" = true ]; then
          echo "✅ 프로젝트별 MCP 설정 활성" >> "$MCP_INFO_FILE"
          echo "" >> "$MCP_INFO_FILE"
          echo "### 설정된 MCP 서버들" >> "$MCP_INFO_FILE"
          echo "" >> "$MCP_INFO_FILE"

          if command -v jq >/dev/null 2>&1; then
            jq -r '.mcpServers | keys[]' "$PROJECT_MCP_CONFIG" | while read -r server; do
              DESCRIPTION=$(jq -r ".mcpServers.$server.description // \"설명 없음\"" "$PROJECT_MCP_CONFIG" 2>/dev/null)
              echo "- **$server**: $DESCRIPTION" >> "$MCP_INFO_FILE"
            done
          fi

          echo "" >> "$MCP_INFO_FILE"
          echo "### 설정 파일 내용" >> "$MCP_INFO_FILE"
          echo "" >> "$MCP_INFO_FILE"
          echo '```json' >> "$MCP_INFO_FILE"
          cat "$PROJECT_MCP_CONFIG" >> "$MCP_INFO_FILE"
          echo '```' >> "$MCP_INFO_FILE"
        else
          echo "❌ 프로젝트별 MCP 설정 없음" >> "$MCP_INFO_FILE"
          echo "" >> "$MCP_INFO_FILE"
          echo "💡 \`mcp-project-init\` 명령어로 초기화할 수 있습니다." >> "$MCP_INFO_FILE"
        fi

        echo "" >> "$MCP_INFO_FILE"
        echo "## Claude Code 사용법" >> "$MCP_INFO_FILE"
        echo "" >> "$MCP_INFO_FILE"
        echo "프로젝트별 MCP 설정을 사용하려면:" >> "$MCP_INFO_FILE"
        echo "" >> "$MCP_INFO_FILE"
        echo '```bash' >> "$MCP_INFO_FILE"
        echo "# 프로젝트 디렉토리에서 Claude Code 실행" >> "$MCP_INFO_FILE"
        echo "cd $PROJECT_ROOT" >> "$MCP_INFO_FILE"
        echo "claude-code" >> "$MCP_INFO_FILE"
        echo '```' >> "$MCP_INFO_FILE"

        echo "📝 MCP 정보 파일 생성: $MCP_INFO_FILE"

        # Claude Code CLI에 프로젝트 MCP 설정 존재 알림
        if [ "$HAS_PROJECT_CONFIG" = true ]; then
          echo ""
          echo "🎉 프로젝트별 MCP 설정 준비 완료!"
          echo ""
          echo "다음 단계:"
          echo "1. 프로젝트 디렉토리에서 'claude-code' 실행"
          echo "2. Claude Code가 .mcp.json 파일을 자동으로 인식합니다"
          echo "3. 설정된 MCP 서버들을 사용할 수 있습니다"
          echo ""
          echo "📋 설정 확인: cat .mcp.json"
          echo "🧪 서버 테스트: mcp-project-test"
        else
          echo ""
          echo "💡 프로젝트별 MCP 설정을 생성하려면:"
          echo "   mcp-project-init"
        fi
      '';
      executable = true;
    };

    # Claude Code 프로젝트 MCP 상태 확인 도구
    home.file.".local/bin/mcp-claude-code-status" = {
      text = ''
        #!/bin/bash
        # Claude Code MCP 연동 상태 확인

        set -e

        PROJECT_ROOT="''${1:-$(pwd)}"
        CLAUDE_CONFIG_DIR="${cfg.claudeCodeConfigPath}"

        echo "📊 Claude Code MCP 연동 상태"
        echo "=========================="
        echo "📁 프로젝트: $PROJECT_ROOT"
        echo "⚙️  Claude Config: $CLAUDE_CONFIG_DIR"
        echo ""

        cd "$PROJECT_ROOT"

        # Claude Code CLI 설치 상태
        if command -v claude-code >/dev/null 2>&1; then
          CLAUDE_VERSION=$(claude-code --version 2>/dev/null || echo "버전 정보 없음")
          echo "✅ Claude Code CLI 설치됨 ($CLAUDE_VERSION)"
        else
          echo "❌ Claude Code CLI 설치되지 않음"
          echo "💡 설치: https://docs.anthropic.com/claude-code"
        fi

        # Claude Code 설정 디렉토리
        if [ -d "$CLAUDE_CONFIG_DIR" ]; then
          echo "✅ Claude Code 설정 디렉토리 존재"

          # 주요 설정 파일들 확인
          if [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]; then
            echo "  📄 CLAUDE.md: 존재"
          else
            echo "  📄 CLAUDE.md: 없음"
          fi

          if [ -f "$CLAUDE_CONFIG_DIR/settings.json" ]; then
            echo "  📄 settings.json: 존재"
          else
            echo "  📄 settings.json: 없음"
          fi

          if [ -f "$CLAUDE_CONFIG_DIR/MCP_PROJECT_INFO.md" ]; then
            echo "  📄 MCP_PROJECT_INFO.md: 존재"
            echo "    💡 마지막 동기화 정보 확인 가능"
          else
            echo "  📄 MCP_PROJECT_INFO.md: 없음"
          fi
        else
          echo "❌ Claude Code 설정 디렉토리 없음"
        fi

        echo ""

        # 프로젝트별 MCP 설정 상태
        if [ -f ".mcp.json" ]; then
          echo "✅ 프로젝트별 MCP 설정 존재"

          if command -v jq >/dev/null 2>&1; then
            if jq empty .mcp.json 2>/dev/null; then
              echo "✅ JSON 형식 유효"

              SERVER_COUNT=$(jq '.mcpServers | length' .mcp.json 2>/dev/null || echo "0")
              echo "🔧 설정된 MCP 서버: $SERVER_COUNT개"

              if [ "$SERVER_COUNT" -gt 0 ]; then
                echo "📋 서버 목록:"
                jq -r '.mcpServers | keys[]' .mcp.json 2>/dev/null | sed 's/^/  - /'
              fi
            else
              echo "❌ JSON 형식 오류"
            fi
          fi
        else
          echo "❌ 프로젝트별 MCP 설정 없음"
          echo "💡 생성: mcp-project-init"
        fi

        echo ""

        # 연동 상태 종합 평가
        if command -v claude-code >/dev/null 2>&1 && [ -f ".mcp.json" ]; then
          echo "🎉 Claude Code + MCP 연동 준비 완료!"
          echo ""
          echo "사용법:"
          echo "1. 이 디렉토리에서 'claude-code' 실행"
          echo "2. Claude Code가 .mcp.json을 자동 인식"
          echo "3. 설정된 MCP 서버들 사용 가능"
        else
          echo "⚠️  Claude Code + MCP 연동 미완료"
          echo ""
          echo "필요한 작업:"
          if ! command -v claude-code >/dev/null 2>&1; then
            echo "- Claude Code CLI 설치"
          fi
          if [ ! -f ".mcp.json" ]; then
            echo "- 프로젝트별 MCP 설정 생성 (mcp-project-init)"
          fi
        fi
      '';
      executable = true;
    };

    # devShell 자동 동기화 훅 (옵션)
    home.file.".local/bin/mcp-auto-sync-hook" = mkIf cfg.autoSync {
      text = ''
        #!/bin/bash
        # devShell 진입 시 자동 MCP 동기화 훅

        # 조용히 실행하여 devShell 진입 시간 최소화
        if [ -f ".mcp.json" ] && command -v claude-code >/dev/null 2>&1; then
          # 백그라운드에서 조용히 동기화
          (mcp-claude-code-sync "$(pwd)" auto >/dev/null 2>&1 &)
          echo "🔄 MCP 설정 자동 동기화됨"
        fi
      '';
      executable = true;
    };

    # Claude Code 설정 템플릿 생성 도구
    home.file.".local/bin/mcp-claude-code-init" = {
      text = ''
        #!/bin/bash
        # Claude Code 설정 초기화 도구 (MCP 최적화)

        set -e

        CLAUDE_CONFIG_DIR="${cfg.claudeCodeConfigPath}"

        echo "🚀 Claude Code 설정 초기화 (MCP 최적화)"
        echo "======================================"
        echo "📁 설정 디렉토리: $CLAUDE_CONFIG_DIR"
        echo ""

        # 설정 디렉토리 생성
        mkdir -p "$CLAUDE_CONFIG_DIR"

        # 기존 설정 백업
        if [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]; then
          BACKUP_FILE="$CLAUDE_CONFIG_DIR/CLAUDE.md.backup.$(date +%s)"
          cp "$CLAUDE_CONFIG_DIR/CLAUDE.md" "$BACKUP_FILE"
          echo "💾 기존 CLAUDE.md 백업: $BACKUP_FILE"
        fi

        # MCP 최적화된 CLAUDE.md 생성
        cat > "$CLAUDE_CONFIG_DIR/CLAUDE.md" << 'EOF'
        # Claude Code MCP 최적화 설정

        이 설정은 Nix dotfiles에 의해 자동 생성되었습니다.
        프로젝트별 MCP 설정을 효율적으로 관리합니다.

        ## MCP 설정 사용법

        ### 프로젝트별 MCP 설정

        1. 프로젝트 디렉토리에서 MCP 설정 초기화:
           ```bash
           mcp-project-init
           ```

        2. 생성된 .mcp.json 파일 확인 및 수정

        3. Claude Code 실행:
           ```bash
           claude-code
           ```

        ### 유용한 명령어

        - `mcp-status`: 전체 MCP 설정 상태 확인
        - `mcp-project-status`: 현재 프로젝트 MCP 상태
        - `mcp-claude-code-status`: Claude Code 연동 상태
        - `mcp-project-test`: 프로젝트 MCP 서버 테스트

        ## 자동화된 기능

        - devShell 진입 시 MCP 설정 자동 인식
        - Claude Desktop과 프로젝트별 설정 동기화
        - MCP 서버 상태 모니터링

        EOF

        echo "✅ MCP 최적화된 CLAUDE.md 생성 완료"

        # settings.json이 없으면 기본 설정 생성
        if [ ! -f "$CLAUDE_CONFIG_DIR/settings.json" ]; then
          cat > "$CLAUDE_CONFIG_DIR/settings.json" << 'EOF'
        {
          "model": "sonnet",
          "permissions": {
            "allow": [
              "Bash(*)",
              "Read(*)",
              "Write(*)",
              "Edit(*)"
            ],
            "deny": []
          }
        }
        EOF
          echo "✅ 기본 settings.json 생성 완료"
        fi

        echo ""
        echo "🎉 Claude Code MCP 최적화 설정 완료!"
        echo ""
        echo "다음 단계:"
        echo "1. 프로젝트에서 'mcp-project-init' 실행"
        echo "2. 'claude-code' 명령어로 Claude Code 시작"
        echo "3. MCP 서버들을 자동으로 사용할 수 있습니다"
      '';
      executable = true;
    };
  };
}
