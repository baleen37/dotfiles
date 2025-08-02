# ABOUTME: Claude Desktop MCP 서버 설정 자동화
# ABOUTME: JSON 형식 claude_desktop_config.json 파일 생성 및 관리

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mcp.claudeDesktop;

  # 사전 정의된 인기 MCP 서버들
  predefinedServers = {
    anki = {
      command = "npx";
      args = ["--yes" "anki-mcp-server"];
      description = "Anki 플래시카드 관리";
    };

    filesystem = {
      command = "npx";
      args = ["--yes" "@anthropic/filesystem-mcp-server"];
      description = "파일시스템 접근";
      env = {
        # 기본적으로 안전한 디렉토리들만 허용
        ALLOWED_DIRS = "${config.home.homeDirectory}/Documents,${config.home.homeDirectory}/Projects,${config.home.homeDirectory}/Downloads";
      };
    };

    github = {
      command = "npx";
      args = ["--yes" "@anthropic/github-mcp-server"];
      description = "GitHub 저장소 관리";
    };

    playwright = {
      command = "npx";
      args = ["--yes" "@anthropic/playwright-mcp-server"];
      description = "웹 브라우저 자동화";
    };

    postgres = {
      command = "npx";
      args = ["--yes" "@anthropic/postgres-mcp-server"];
      description = "PostgreSQL 데이터베이스 관리";
    };

    sqlite = {
      command = "npx";
      args = ["--yes" "@anthropic/sqlite-mcp-server"];
      description = "SQLite 데이터베이스 관리";
    };
  };

in {
  options.mcp.claudeDesktop = {
    predefinedServers = mkOption {
      type = types.attrsOf types.bool;
      default = {
        anki = true;  # 기본적으로 anki는 활성화
      };
      description = "사전 정의된 MCP 서버들의 활성화 상태";
      example = {
        anki = true;
        filesystem = true;
        github = false;
      };
    };

    customServers = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          command = mkOption {
            type = types.str;
            description = "MCP 서버 실행 명령어";
          };

          args = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "MCP 서버 실행 인자";
          };

          env = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "MCP 서버 환경 변수";
          };

          description = mkOption {
            type = types.str;
            default = "";
            description = "MCP 서버 설명";
          };
        };
      });
      default = {};
      description = "사용자 정의 MCP 서버들";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "claude_desktop_config.json에 추가할 기타 설정";
    };

    backupEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "설정 변경 시 자동 백업 활성화";
    };
  };

  config = mkIf config.mcp.enable {
    # 활성화된 사전 정의 서버들
    mcp.servers =
      let
        enabledPredefined = filterAttrs (name: enabled: enabled) cfg.predefinedServers;
        selectedServers = mapAttrs (name: _: predefinedServers.${name}) enabledPredefined;
      in
      selectedServers // cfg.customServers;

    # Claude Desktop 설정 파일 생성
    home.file."Library/Application Support/Claude/claude_desktop_config.json" = mkIf config.mcp.claudeDesktop.enable {
      text = builtins.toJSON ({
        mcpServers = mapAttrs (name: server:
          {
            command = server.command;
            args = server.args;
          } // optionalAttrs (server.env != {}) {
            env = server.env;
          }
        ) config.mcp.servers;
      } // cfg.extraConfig);
    };

    # MCP 서버 디버깅 도구
    home.file.".local/bin/mcp-debug" = {
      text = ''
        #!/bin/bash
        # MCP 서버 디버깅 도구

        set -e

        SERVER_NAME="$1"

        if [ -z "$SERVER_NAME" ]; then
          echo "사용법: mcp-debug <서버명>"
          echo ""
          echo "사용 가능한 서버들:"
          ${concatStringsSep "\n" (mapAttrsToList (name: server: "echo \"  - ${name}: ${server.description or ""}\"") config.mcp.servers)}
          exit 1
        fi

        # 서버 설정 확인
        case "$SERVER_NAME" in
        ${concatStringsSep "\n" (mapAttrsToList (name: server: ''
          "${name}")
            echo "🔧 ${name} 서버 설정:"
            echo "  명령어: ${server.command}"
            echo "  인자: ${concatStringsSep " " server.args}"
            ${optionalString (server.env != {}) ''
            echo "  환경변수:"
            ${concatStringsSep "\n" (mapAttrsToList (key: value: "echo \"    ${key}=${value}\"") server.env)}
            ''}
            echo ""
            echo "🧪 수동 테스트:"
            echo "  ${server.command} ${concatStringsSep " " server.args}"
            ;;'') config.mcp.servers)}
          *)
            echo "❌ 알 수 없는 서버: $SERVER_NAME"
            exit 1
            ;;
        esac
      '';
      executable = true;
    };

    # MCP 서버 설치 도구
    home.file.".local/bin/mcp-install" = {
      text = ''
        #!/bin/bash
        # MCP 서버 설치 도구

        set -e

        echo "🚀 MCP 서버 의존성 설치 시작..."

        # Node.js 버전 확인
        if ! command -v node >/dev/null 2>&1; then
          echo "❌ Node.js가 설치되지 않았습니다"
          exit 1
        fi

        NODE_VERSION=$(node --version | sed 's/v//')
        echo "✅ Node.js 버전: $NODE_VERSION"

        # 필요한 MCP 서버 패키지들 설치
        echo "📦 MCP 서버 패키지 설치 중..."

        ${concatStringsSep "\n" (mapAttrsToList (name: server:
          optionalString (hasPrefix "npx" server.command && any (arg: hasPrefix "@" arg || hasPrefix "anki-" arg) server.args) ''
          echo "  - ${name} 서버 준비 중..."
          ${server.command} ${concatStringsSep " " server.args} --help >/dev/null 2>&1 || echo "    ⚠️  ${name} 서버 패키지 다운로드 필요"
          ''
        ) config.mcp.servers)}

        echo "✅ MCP 서버 설치 완료"
        echo "💡 이제 Claude Desktop을 재시작하여 MCP 서버를 사용할 수 있습니다"
      '';
      executable = true;
    };

    # 설정 검증 도구
    home.file.".local/bin/mcp-validate" = {
      text = ''
        #!/bin/bash
        # MCP 설정 검증 도구

        set -e

        CLAUDE_CONFIG="${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json"

        echo "🔍 MCP 설정 검증 시작..."

        # 설정 파일 존재 확인
        if [ ! -f "$CLAUDE_CONFIG" ]; then
          echo "❌ Claude Desktop 설정 파일이 없습니다: $CLAUDE_CONFIG"
          exit 1
        fi

        # JSON 유효성 검사
        if ! command -v jq >/dev/null 2>&1; then
          echo "⚠️  jq가 설치되지 않아 상세 검증을 수행할 수 없습니다"
          echo "✅ 기본 파일 존재 확인 완료"
          exit 0
        fi

        if ! jq empty "$CLAUDE_CONFIG" 2>/dev/null; then
          echo "❌ 설정 파일이 유효한 JSON 형식이 아닙니다"
          exit 1
        fi

        echo "✅ JSON 형식 유효"

        # MCP 서버 설정 검증
        if ! jq -e '.mcpServers' "$CLAUDE_CONFIG" >/dev/null 2>&1; then
          echo "❌ mcpServers 섹션이 없습니다"
          exit 1
        fi

        SERVER_COUNT=$(jq '.mcpServers | length' "$CLAUDE_CONFIG")
        echo "✅ $SERVER_COUNT개의 MCP 서버 설정됨"

        # 각 서버 설정 검증
        jq -r '.mcpServers | keys[]' "$CLAUDE_CONFIG" | while read -r server; do
          echo "  🔧 $server 서버 검증 중..."

          if ! jq -e ".mcpServers.$server.command" "$CLAUDE_CONFIG" >/dev/null 2>&1; then
            echo "    ❌ command 필드 누락"
            continue
          fi

          COMMAND=$(jq -r ".mcpServers.$server.command" "$CLAUDE_CONFIG")
          echo "    ✅ 명령어: $COMMAND"

          # 명령어 실행 가능성 확인
          if ! command -v "$COMMAND" >/dev/null 2>&1; then
            echo "    ⚠️  명령어 '$COMMAND'를 찾을 수 없습니다"
          fi
        done

        echo "✅ MCP 설정 검증 완료"
      '';
      executable = true;
    };
  };
}
