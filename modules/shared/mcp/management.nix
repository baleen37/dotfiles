# ABOUTME: 통합 MCP 관리 도구 및 모니터링 시스템
# ABOUTME: 모든 MCP 설정, 서버, 프로젝트를 통합적으로 관리하는 도구

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mcp.management;

in {
  options.mcp.management = {
    enable = mkEnableOption "통합 MCP 관리 시스템";

    dashboardEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "MCP 대시보드 활성화";
    };

    monitoringEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "MCP 서버 모니터링 활성화";
    };

    autoCleanup = mkOption {
      type = types.bool;
      default = true;
      description = "자동 정리 기능 활성화";
    };

    healthCheckInterval = mkOption {
      type = types.int;
      default = 300; # 5분
      description = "헬스 체크 간격 (초)";
    };
  };

  config = mkIf (config.mcp.enable && cfg.enable) {
    # 통합 MCP 관리 대시보드
    home.file.".local/bin/mcp-dashboard" = mkIf cfg.dashboardEnabled {
      text = ''
        #!/bin/bash
        # MCP 통합 관리 대시보드

        set -e

        # 색상 정의
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        NC='\033[0m' # No Color

        clear

        echo -e "''${PURPLE}======================================''${NC}"
        echo -e "''${PURPLE}    🤖 MCP 통합 관리 대시보드        ''${NC}"
        echo -e "''${PURPLE}======================================''${NC}"
        echo ""

        # 시스템 상태 개요
        echo -e "''${CYAN}📊 시스템 상태 개요''${NC}"
        echo "===================="

        # Claude Desktop 상태
        if pgrep "Claude" >/dev/null 2>&1; then
          echo -e "🖥️  Claude Desktop: ''${GREEN}✅ 실행 중''${NC}"
        else
          echo -e "🖥️  Claude Desktop: ''${YELLOW}⭕ 중지됨''${NC}"
        fi

        # Claude Code CLI 상태
        if command -v claude-code >/dev/null 2>&1; then
          echo -e "💻 Claude Code CLI: ''${GREEN}✅ 설치됨''${NC}"
        else
          echo -e "💻 Claude Code CLI: ''${RED}❌ 미설치''${NC}"
        fi

        # Claude Desktop MCP 설정
        CLAUDE_CONFIG="${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json"
        if [ -f "$CLAUDE_CONFIG" ]; then
          if command -v jq >/dev/null 2>&1 && jq empty "$CLAUDE_CONFIG" 2>/dev/null; then
            SERVER_COUNT=$(jq '.mcpServers | length' "$CLAUDE_CONFIG" 2>/dev/null || echo "0")
            echo -e "🔧 Claude Desktop MCP: ''${GREEN}✅ $SERVER_COUNT개 서버 설정''${NC}"
          else
            echo -e "🔧 Claude Desktop MCP: ''${YELLOW}⚠️  설정 오류''${NC}"
          fi
        else
          echo -e "🔧 Claude Desktop MCP: ''${RED}❌ 설정 없음''${NC}"
        fi

        echo ""

        # 프로젝트별 MCP 설정
        echo -e "''${CYAN}📁 프로젝트별 MCP 설정''${NC}"
        echo "======================"

        if [ -f ".mcp.json" ]; then
          if command -v jq >/dev/null 2>&1 && jq empty .mcp.json 2>/dev/null; then
            PROJECT_SERVER_COUNT=$(jq '.mcpServers | length' .mcp.json 2>/dev/null || echo "0")
            echo -e "📂 현재 프로젝트: ''${GREEN}✅ $PROJECT_SERVER_COUNT개 서버 설정''${NC}"

            if [ "$PROJECT_SERVER_COUNT" -gt 0 ]; then
              echo "   📋 서버 목록:"
              jq -r '.mcpServers | keys[]' .mcp.json 2>/dev/null | sed 's/^/      - /'
            fi
          else
            echo -e "📂 현재 프로젝트: ''${YELLOW}⚠️  .mcp.json 형식 오류''${NC}"
          fi
        else
          echo -e "📂 현재 프로젝트: ''${YELLOW}❌ .mcp.json 없음''${NC}"
        fi

        echo ""

        # Nix 패키지 상태
        echo -e "''${CYAN}📦 Nix 패키지 상태''${NC}"
        echo "=================="

        if [ "${toString config.mcp.nixPackages.enable}" = "1" ]; then
          echo -e "🎁 Nix 패키지: ''${GREEN}✅ 활성화됨''${NC}"
          ENABLED_COUNT=${toString (length config.mcp.nixPackages.enabledPackages)}
          echo -e "   📊 활성화된 패키지: $ENABLED_COUNT개"

          ${concatStringsSep "\n" (map (name:
            "echo \"      - ${name}\""
          ) config.mcp.nixPackages.enabledPackages)}
        else
          echo -e "🎁 Nix 패키지: ''${YELLOW}❌ 비활성화됨''${NC}"
        fi

        echo ""

        # 사용 가능한 명령어
        echo -e "''${CYAN}🛠️  사용 가능한 명령어''${NC}"
        echo "===================="
        echo ""
        echo "''${BLUE}기본 관리:''${NC}"
        echo "  mcp-status                  - 전체 MCP 상태 확인"
        echo "  mcp-sync                    - MCP 설정 동기화"
        echo "  mcp-validate                - MCP 설정 검증"
        echo ""
        echo "''${BLUE}Claude Desktop:''${NC}"
        echo "  mcp-debug <서버명>          - 서버별 디버깅"
        echo "  mcp-install                 - MCP 서버 의존성 설치"
        echo ""
        echo "''${BLUE}프로젝트별:''${NC}"
        echo "  mcp-project-init            - 프로젝트 MCP 설정 초기화"
        echo "  mcp-project-status          - 프로젝트 MCP 상태"
        echo "  mcp-project-test            - 프로젝트 MCP 서버 테스트"
        echo ""
        echo "''${BLUE}Claude Code 연동:''${NC}"
        echo "  mcp-claude-code-sync        - Claude Code 설정 동기화"
        echo "  mcp-claude-code-status      - Claude Code 연동 상태"
        echo "  mcp-claude-code-init        - Claude Code MCP 최적화 설정"
        echo ""
        echo "''${BLUE}Nix 패키지:''${NC}"
        echo "  mcp-nix-packages list       - 사용 가능한 Nix 패키지 목록"
        echo "  mcp-nix-packages info <name> - 패키지 정보"
        echo "  mcp-nix-packages test       - 패키지 테스트"
        echo ""
        echo "''${BLUE}고급 기능:''${NC}"
        echo "  mcp-monitor                 - MCP 서버 모니터링"
        echo "  mcp-cleanup                 - 자동 정리"
        echo "  mcp-health-check            - 종합 헬스 체크"
        echo ""

        echo -e "''${PURPLE}💡 Tip: 'mcp-dashboard'를 즐겨찾기에 추가하여 언제든 확인하세요!''${NC}"
      '';
      executable = true;
    };

    # MCP 시스템 헬스 체크
    home.file.".local/bin/mcp-health-check" = {
      text = ''
        #!/bin/bash
        # MCP 시스템 종합 헬스 체크

        set -e

        echo "🏥 MCP 시스템 헬스 체크"
        echo "====================="
        echo ""

        ISSUES_FOUND=0

        # Claude Desktop 헬스 체크
        echo "🖥️  Claude Desktop 헬스 체크"
        echo "=========================="

        CLAUDE_CONFIG="${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json"

        if [ -f "$CLAUDE_CONFIG" ]; then
          echo "✅ 설정 파일 존재"

          if command -v jq >/dev/null 2>&1; then
            if jq empty "$CLAUDE_CONFIG" 2>/dev/null; then
              echo "✅ JSON 형식 유효"

              # 서버별 헬스 체크
              jq -r '.mcpServers | keys[]' "$CLAUDE_CONFIG" | while read -r server; do
                echo "  🔧 $server 서버 검사 중..."

                COMMAND=$(jq -r ".mcpServers.$server.command" "$CLAUDE_CONFIG")

                if command -v "$COMMAND" >/dev/null 2>&1; then
                  echo "    ✅ 명령어 사용 가능"
                else
                  echo "    ❌ 명령어 '$COMMAND' 없음"
                  ISSUES_FOUND=$((ISSUES_FOUND + 1))
                fi

                # 환경 변수 확인
                if jq -e ".mcpServers.$server.env" "$CLAUDE_CONFIG" >/dev/null 2>&1; then
                  jq -r ".mcpServers.$server.env | keys[]" "$CLAUDE_CONFIG" | while read -r envvar; do
                    VALUE=$(jq -r ".mcpServers.$server.env.$envvar" "$CLAUDE_CONFIG")
                    if [[ "$VALUE" == *"$"* ]]; then
                      # 환경 변수 치환이 필요한 경우
                      echo "    ⚠️  환경 변수 확인 필요: $envvar"
                    fi
                  done
                fi
              done
            else
              echo "❌ JSON 형식 오류"
              ISSUES_FOUND=$((ISSUES_FOUND + 1))
            fi
          else
            echo "⚠️  jq 없음 - 상세 검사 불가"
          fi
        else
          echo "❌ Claude Desktop 설정 파일 없음"
          ISSUES_FOUND=$((ISSUES_FOUND + 1))
        fi

        echo ""

        # 프로젝트별 MCP 헬스 체크
        echo "📁 프로젝트별 MCP 헬스 체크"
        echo "========================"

        if [ -f ".mcp.json" ]; then
          echo "✅ .mcp.json 존재"

          if command -v jq >/dev/null 2>&1; then
            if jq empty .mcp.json 2>/dev/null; then
              echo "✅ JSON 형식 유효"

              # 프로젝트 서버별 헬스 체크
              jq -r '.mcpServers | keys[]' .mcp.json | while read -r server; do
                echo "  🔧 $server 프로젝트 서버 검사 중..."

                COMMAND=$(jq -r ".mcpServers.$server.command" .mcp.json)

                if command -v "$COMMAND" >/dev/null 2>&1; then
                  echo "    ✅ 명령어 사용 가능"
                else
                  echo "    ❌ 명령어 '$COMMAND' 없음"
                  ISSUES_FOUND=$((ISSUES_FOUND + 1))
                fi
              done
            else
              echo "❌ .mcp.json 형식 오류"
              ISSUES_FOUND=$((ISSUES_FOUND + 1))
            fi
          fi
        else
          echo "ℹ️  프로젝트별 MCP 설정 없음 (선택사항)"
        fi

        echo ""

        # Node.js 환경 헬스 체크
        echo "📦 Node.js 환경 헬스 체크"
        echo "======================="

        if command -v node >/dev/null 2>&1; then
          NODE_VERSION=$(node --version)
          echo "✅ Node.js 설치됨 ($NODE_VERSION)"

          if command -v npm >/dev/null 2>&1; then
            NPM_VERSION=$(npm --version)
            echo "✅ npm 설치됨 ($NPM_VERSION)"
          else
            echo "❌ npm 없음"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
          fi

          if command -v npx >/dev/null 2>&1; then
            echo "✅ npx 사용 가능"
          else
            echo "❌ npx 없음"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
          fi
        else
          echo "❌ Node.js 없음"
          ISSUES_FOUND=$((ISSUES_FOUND + 1))
        fi

        echo ""

        # 최종 헬스 체크 결과
        echo "📊 헬스 체크 결과"
        echo "================"

        if [ $ISSUES_FOUND -eq 0 ]; then
          echo "🎉 모든 검사 통과! MCP 시스템이 정상 작동합니다."
        else
          echo "⚠️  $ISSUES_FOUND개의 문제가 발견되었습니다."
          echo ""
          echo "💡 문제 해결 방법:"
          echo "  - mcp-install: MCP 서버 의존성 설치"
          echo "  - mcp-project-init: 프로젝트 MCP 설정 초기화"
          echo "  - mcp-validate: 설정 파일 검증 및 수정"
        fi
      '';
      executable = true;
    };

    # MCP 시스템 모니터링
    home.file.".local/bin/mcp-monitor" = mkIf cfg.monitoringEnabled {
      text = ''
        #!/bin/bash
        # MCP 시스템 실시간 모니터링

        set -e

        INTERVAL="''${1:-${toString cfg.healthCheckInterval}}"

        echo "📡 MCP 시스템 모니터링 시작 (간격: ''${INTERVAL}초)"
        echo "Ctrl+C로 종료"
        echo ""

        while true; do
          clear
          echo "🕐 $(date '+%Y-%m-%d %H:%M:%S') - MCP 시스템 모니터링"
          echo "=================================================="
          echo ""

          # Claude Desktop 프로세스 모니터링
          if pgrep "Claude" >/dev/null 2>&1; then
            CLAUDE_PID=$(pgrep "Claude" | head -1)
            CLAUDE_CPU=$(ps -p $CLAUDE_PID -o %cpu= | tr -d ' ' 2>/dev/null || echo "N/A")
            CLAUDE_MEM=$(ps -p $CLAUDE_PID -o %mem= | tr -d ' ' 2>/dev/null || echo "N/A")
            echo "🖥️  Claude Desktop: ✅ 실행 중 (PID: $CLAUDE_PID, CPU: $CLAUDE_CPU%, MEM: $CLAUDE_MEM%)"
          else
            echo "🖥️  Claude Desktop: ❌ 중지됨"
          fi

          # MCP 설정 파일 모니터링
          CLAUDE_CONFIG="${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json"
          if [ -f "$CLAUDE_CONFIG" ]; then
            MTIME=$(stat -f "%Sm" -t "%H:%M:%S" "$CLAUDE_CONFIG" 2>/dev/null || echo "N/A")
            SIZE=$(du -h "$CLAUDE_CONFIG" | cut -f1 2>/dev/null || echo "N/A")
            echo "⚙️  Claude 설정: ✅ 최종 수정 $MTIME (크기: $SIZE)"
          else
            echo "⚙️  Claude 설정: ❌ 파일 없음"
          fi

          # 프로젝트 MCP 설정 모니터링
          if [ -f ".mcp.json" ]; then
            PROJECT_MTIME=$(stat -f "%Sm" -t "%H:%M:%S" .mcp.json 2>/dev/null || echo "N/A")
            PROJECT_SIZE=$(du -h .mcp.json | cut -f1 2>/dev/null || echo "N/A")
            echo "📁 프로젝트 설정: ✅ 최종 수정 $PROJECT_MTIME (크기: $PROJECT_SIZE)"
          else
            echo "📁 프로젝트 설정: ❌ 없음"
          fi

          # 시스템 리소스 모니터링
          echo ""
          echo "💻 시스템 리소스:"

          if command -v top >/dev/null 2>&1; then
            LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' || echo "N/A")
            echo "   📊 Load Average: $LOAD_AVG"
          fi

          if command -v df >/dev/null 2>&1; then
            DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' || echo "N/A")
            echo "   💾 디스크 사용률: $DISK_USAGE"
          fi

          echo ""
          echo "다음 업데이트: ''${INTERVAL}초 후..."

          sleep $INTERVAL
        done
      '';
      executable = true;
    };

    # MCP 시스템 자동 정리
    home.file.".local/bin/mcp-cleanup" = mkIf cfg.autoCleanup {
      text = ''
        #!/bin/bash
        # MCP 시스템 자동 정리 도구

        set -e

        MODE="''${1:-interactive}"  # interactive, auto, dry-run

        echo "🧹 MCP 시스템 자동 정리"
        echo "===================="
        echo "모드: $MODE"
        echo ""

        CLEANUP_COUNT=0

        # Claude Desktop 설정 백업 정리
        echo "🗂️  Claude Desktop 설정 백업 정리"
        CLAUDE_CONFIG_DIR="${config.home.homeDirectory}/Library/Application Support/Claude"

        if [ -d "$CLAUDE_CONFIG_DIR" ]; then
          BACKUP_FILES=$(find "$CLAUDE_CONFIG_DIR" -name "*.backup.*" -type f 2>/dev/null || echo "")

          if [ -n "$BACKUP_FILES" ]; then
            BACKUP_COUNT=$(echo "$BACKUP_FILES" | wc -l | tr -d ' ')
            echo "   📋 $BACKUP_COUNT개의 백업 파일 발견"

            # 7일 이상 된 백업 파일 정리
            OLD_BACKUPS=$(find "$CLAUDE_CONFIG_DIR" -name "*.backup.*" -type f -mtime +7 2>/dev/null || echo "")

            if [ -n "$OLD_BACKUPS" ]; then
              OLD_COUNT=$(echo "$OLD_BACKUPS" | wc -l | tr -d ' ')
              echo "   📅 $OLD_COUNT개의 오래된 백업 파일 (7일+)"

              if [ "$MODE" = "interactive" ]; then
                read -p "   🤔 오래된 백업 파일을 삭제하시겠습니까? (y/N): " -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                  if [ "$MODE" != "dry-run" ]; then
                    echo "$OLD_BACKUPS" | xargs rm -f
                    echo "   ✅ $OLD_COUNT개 파일 삭제됨"
                    CLEANUP_COUNT=$((CLEANUP_COUNT + OLD_COUNT))
                  else
                    echo "   🔍 [DRY-RUN] $OLD_COUNT개 파일 삭제 예정"
                  fi
                fi
              elif [ "$MODE" = "auto" ]; then
                if [ "$MODE" != "dry-run" ]; then
                  echo "$OLD_BACKUPS" | xargs rm -f
                  echo "   ✅ $OLD_COUNT개 파일 자동 삭제됨"
                  CLEANUP_COUNT=$((CLEANUP_COUNT + OLD_COUNT))
                else
                  echo "   🔍 [DRY-RUN] $OLD_COUNT개 파일 삭제 예정"
                fi
              fi
            else
              echo "   ✅ 정리할 오래된 백업 없음"
            fi
          else
            echo "   ✅ 백업 파일 없음"
          fi
        fi

        echo ""

        # 임시 MCP 파일 정리
        echo "🗂️  임시 MCP 파일 정리"
        TEMP_MCP_FILES=$(find /tmp -name "*mcp*" -type f -mtime +1 2>/dev/null || echo "")

        if [ -n "$TEMP_MCP_FILES" ]; then
          TEMP_COUNT=$(echo "$TEMP_MCP_FILES" | wc -l | tr -d ' ')
          echo "   📋 $TEMP_COUNT개의 임시 MCP 파일 발견"

          if [ "$MODE" = "interactive" ]; then
            read -p "   🤔 임시 MCP 파일을 삭제하시겠습니까? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
              if [ "$MODE" != "dry-run" ]; then
                echo "$TEMP_MCP_FILES" | xargs rm -f
                echo "   ✅ $TEMP_COUNT개 파일 삭제됨"
                CLEANUP_COUNT=$((CLEANUP_COUNT + TEMP_COUNT))
              else
                echo "   🔍 [DRY-RUN] $TEMP_COUNT개 파일 삭제 예정"
              fi
            fi
          elif [ "$MODE" = "auto" ]; then
            if [ "$MODE" != "dry-run" ]; then
              echo "$TEMP_MCP_FILES" | xargs rm -f
              echo "   ✅ $TEMP_COUNT개 파일 자동 삭제됨"
              CLEANUP_COUNT=$((CLEANUP_COUNT + TEMP_COUNT))
            else
              echo "   🔍 [DRY-RUN] $TEMP_COUNT개 파일 삭제 예정"
            fi
          fi
        else
          echo "   ✅ 임시 파일 없음"
        fi

        echo ""

        # npm 캐시 정리 (MCP 관련)
        echo "📦 npm 캐시 정리 (MCP 관련)"
        if command -v npm >/dev/null 2>&1; then
          NPM_CACHE_SIZE=$(npm cache verify 2>/dev/null | grep "Content verified" | awk '{print $3}' || echo "N/A")
          echo "   📊 현재 npm 캐시 크기: $NPM_CACHE_SIZE"

          if [ "$MODE" = "interactive" ]; then
            read -p "   🤔 npm 캐시를 정리하시겠습니까? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
              if [ "$MODE" != "dry-run" ]; then
                npm cache clean --force >/dev/null 2>&1
                echo "   ✅ npm 캐시 정리 완료"
              else
                echo "   🔍 [DRY-RUN] npm 캐시 정리 예정"
              fi
            fi
          elif [ "$MODE" = "auto" ]; then
            if [ "$MODE" != "dry-run" ]; then
              npm cache clean --force >/dev/null 2>&1
              echo "   ✅ npm 캐시 자동 정리 완료"
            else
              echo "   🔍 [DRY-RUN] npm 캐시 정리 예정"
            fi
          fi
        else
          echo "   ⚠️  npm 없음"
        fi

        echo ""

        # 정리 결과 요약
        echo "📊 정리 결과 요약"
        echo "================"

        if [ "$MODE" = "dry-run" ]; then
          echo "🔍 DRY-RUN 모드: 실제 삭제는 수행되지 않았습니다"
        else
          echo "✅ 정리 완료: $CLEANUP_COUNT개 항목 정리됨"
        fi

        echo ""
        echo "💡 정기적인 정리를 위해 cron job 설정을 고려하세요:"
        echo "   0 2 * * 0 mcp-cleanup auto  # 매주 일요일 새벽 2시"
      '';
      executable = true;
    };

    # 통합 MCP 상태 명령어 (기존 mcp-status 개선)
    home.file.".local/bin/mcp-status" = {
      text = ''
        #!/bin/bash
        # 통합 MCP 상태 확인 도구 (개선된 버전)

        set -e

        DETAIL_LEVEL="''${1:-summary}"  # summary, detailed, full

        case "$DETAIL_LEVEL" in
          "summary")
            echo "📊 MCP 시스템 상태 요약"
            echo "===================="

            # 핵심 상태만 표시
            if pgrep "Claude" >/dev/null 2>&1; then
              echo "✅ Claude Desktop 실행 중"
            else
              echo "❌ Claude Desktop 중지됨"
            fi

            if command -v claude-code >/dev/null 2>&1; then
              echo "✅ Claude Code CLI 설치됨"
            else
              echo "❌ Claude Code CLI 미설치"
            fi

            CLAUDE_CONFIG="${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json"
            if [ -f "$CLAUDE_CONFIG" ] && command -v jq >/dev/null 2>&1 && jq empty "$CLAUDE_CONFIG" 2>/dev/null; then
              SERVER_COUNT=$(jq '.mcpServers | length' "$CLAUDE_CONFIG" 2>/dev/null || echo "0")
              echo "✅ Claude Desktop MCP: $SERVER_COUNT개 서버"
            else
              echo "❌ Claude Desktop MCP 설정 문제"
            fi

            if [ -f ".mcp.json" ]; then
              echo "✅ 프로젝트별 MCP 설정 존재"
            else
              echo "ℹ️  프로젝트별 MCP 설정 없음"
            fi
            ;;

          "detailed")
            # 기존의 상세 상태 표시 (mcp-dashboard와 유사)
            mcp-dashboard
            ;;

          "full")
            # 가장 상세한 상태 (헬스 체크 포함)
            echo "🔍 MCP 시스템 전체 상태 분석"
            echo "=========================="
            echo ""

            mcp-dashboard
            echo ""
            echo "🏥 헬스 체크 실행 중..."
            echo "===================="
            mcp-health-check
            ;;

          *)
            echo "사용법: mcp-status [summary|detailed|full]"
            echo ""
            echo "  summary  - 간단한 상태 요약 (기본값)"
            echo "  detailed - 상세한 대시보드 표시"
            echo "  full     - 헬스 체크 포함 전체 분석"
            ;;
        esac
      '';
      executable = true;
    };
  };
}
