# ABOUTME: MCP (Model Context Protocol) 설정 자동화 모듈
# ABOUTME: Claude Desktop과 프로젝트별 MCP 서버 설정을 Nix로 관리

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mcp;

  # MCP 서버 타입 정의
  mcpServerType = types.submodule {
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

      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "MCP 서버 활성화 여부";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "MCP 서버 설명";
      };
    };
  };

  # 활성화된 서버만 필터링
  enabledServers = filterAttrs (name: server: server.enabled) cfg.servers;

in {
  options.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) 설정 자동화";

    claudeDesktop = {
      enable = mkEnableOption "Claude Desktop MCP 설정 자동화";

      configPath = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";
        description = "Claude Desktop 설정 파일 경로";
      };
    };

    projectConfig = {
      enable = mkEnableOption "프로젝트별 MCP 설정 활성화";

      template = mkOption {
        type = types.attrs;
        default = {};
        description = "프로젝트별 MCP 설정 템플릿";
      };
    };

    servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = "MCP 서버 설정들";
      example = {
        anki = {
          command = "npx";
          args = ["--yes" "anki-mcp-server"];
        };
        filesystem = {
          command = "npx";
          args = ["--yes" "@anthropic/filesystem-mcp-server"];
          env = {
            ALLOWED_DIRS = "/Users/username/Documents,/Users/username/Projects";
          };
        };
      };
    };

    userServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = "사용자별 전용 MCP 서버 설정";
    };
  };

  config = mkIf cfg.enable {
    # Claude Desktop MCP 설정 자동화
    home.file."Library/Application Support/Claude/claude_desktop_config.json" = mkIf cfg.claudeDesktop.enable {
      text = builtins.toJSON {
        mcpServers = mapAttrs (name: server: {
          command = server.command;
          args = server.args;
        } // optionalAttrs (server.env != {}) {
          env = server.env;
        }) (enabledServers // cfg.userServers);
      };
    };

    # 개발 도구에 MCP 관련 패키지 추가
    home.packages = with pkgs; [
      nodejs_20  # MCP 서버들이 주로 Node.js 기반
      # 추후 MCP 서버 Nix 패키지들 추가 예정
    ];

    # MCP 서버 관리 스크립트
    home.file.".local/bin/mcp-sync" = {
      text = ''
        #!/bin/bash
        # MCP 설정 동기화 도구

        set -e

        CLAUDE_CONFIG_PATH="${cfg.claudeDesktop.configPath}"
        CLAUDE_DESKTOP_RUNNING=$(pgrep "Claude" || true)

        echo "🔄 MCP 설정 동기화 시작..."

        # Claude Desktop이 실행 중인 경우 경고
        if [ -n "$CLAUDE_DESKTOP_RUNNING" ]; then
          echo "⚠️  Claude Desktop이 실행 중입니다. 설정 변경을 위해 종료하는 것을 권장합니다."
          read -p "계속하시겠습니까? (y/N): " -r
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
          fi
        fi

        # 설정 파일 백업
        if [ -f "$CLAUDE_CONFIG_PATH" ]; then
          cp "$CLAUDE_CONFIG_PATH" "$CLAUDE_CONFIG_PATH.backup.$(date +%s)"
          echo "✅ 기존 설정 백업 완료"
        fi

        echo "✅ MCP 설정 동기화 완료"
        echo "💡 Claude Desktop을 재시작하여 변경사항을 적용하세요."
      '';
      executable = true;
    };

    # MCP 서버 상태 확인 스크립트
    home.file.".local/bin/mcp-status" = {
      text = ''
        #!/bin/bash
        # MCP 서버 상태 확인 도구

        set -e

        CLAUDE_CONFIG_PATH="${cfg.claudeDesktop.configPath}"

        echo "📊 MCP 설정 상태"
        echo "=================="

        if [ -f "$CLAUDE_CONFIG_PATH" ]; then
          echo "✅ Claude Desktop 설정 파일 존재"
          echo "📍 위치: $CLAUDE_CONFIG_PATH"

          # JSON 유효성 검사
          if command -v jq >/dev/null 2>&1; then
            if jq empty "$CLAUDE_CONFIG_PATH" 2>/dev/null; then
              echo "✅ 설정 파일 형식 유효"

              # 설정된 서버 수 표시
              SERVER_COUNT=$(jq '.mcpServers | length' "$CLAUDE_CONFIG_PATH" 2>/dev/null || echo "0")
              echo "🔧 설정된 MCP 서버 수: $SERVER_COUNT"

              # 서버 목록 표시
              if [ "$SERVER_COUNT" -gt 0 ]; then
                echo "📋 설정된 서버들:"
                jq -r '.mcpServers | keys[]' "$CLAUDE_CONFIG_PATH" 2>/dev/null | sed 's/^/  - /'
              fi
            else
              echo "❌ 설정 파일 형식 오류"
            fi
          else
            echo "⚠️  jq가 설치되지 않아 상세 분석을 수행할 수 없습니다"
          fi
        else
          echo "❌ Claude Desktop 설정 파일 없음"
        fi

        # Claude Desktop 실행 상태
        if pgrep "Claude" >/dev/null 2>&1; then
          echo "✅ Claude Desktop 실행 중"
        else
          echo "⭕ Claude Desktop 중지됨"
        fi
      '';
      executable = true;
    };
  };
}
