# ABOUTME: 프로젝트별 MCP 설정 devShell 통합 모듈
# ABOUTME: .mcp.json 파일 자동 생성 및 프로젝트별 MCP 서버 관리

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mcp.projectConfig;

  # 프로젝트 타입별 기본 MCP 서버 설정
  projectTypeDefaults = {
    # 웹 개발 프로젝트
    web = {
      playwright = {
        command = "npx";
        args = ["--yes" "@anthropic/playwright-mcp-server"];
        description = "브라우저 자동화 및 E2E 테스트";
      };
      filesystem = {
        command = "npx";
        args = ["--yes" "@anthropic/filesystem-mcp-server"];
        env = {
          ALLOWED_DIRS = "$PROJECT_ROOT/src,$PROJECT_ROOT/tests,$PROJECT_ROOT/docs";
        };
        description = "프로젝트 파일시스템 접근";
      };
    };

    # Node.js 프로젝트
    nodejs = {
      filesystem = {
        command = "npx";
        args = ["--yes" "@anthropic/filesystem-mcp-server"];
        env = {
          ALLOWED_DIRS = "$PROJECT_ROOT/src,$PROJECT_ROOT/lib,$PROJECT_ROOT/tests";
        };
        description = "Node.js 프로젝트 파일 접근";
      };
    };

    # Python 프로젝트
    python = {
      filesystem = {
        command = "python";
        args = ["-m" "mcp_server_filesystem"];
        env = {
          ALLOWED_DIRS = "$PROJECT_ROOT/src,$PROJECT_ROOT/tests,$PROJECT_ROOT/docs";
        };
        description = "Python 프로젝트 파일 접근";
      };
    };

    # 데이터베이스 프로젝트
    database = {
      postgres = {
        command = "npx";
        args = ["--yes" "@anthropic/postgres-mcp-server"];
        env = {
          POSTGRES_CONNECTION_STRING = "$DATABASE_URL";
        };
        description = "PostgreSQL 데이터베이스 관리";
      };
      sqlite = {
        command = "npx";
        args = ["--yes" "@anthropic/sqlite-mcp-server"];
        description = "SQLite 데이터베이스 관리";
      };
    };

    # 전체 스택 개발
    fullstack = {
      filesystem = {
        command = "npx";
        args = ["--yes" "@anthropic/filesystem-mcp-server"];
        env = {
          ALLOWED_DIRS = "$PROJECT_ROOT/frontend,$PROJECT_ROOT/backend,$PROJECT_ROOT/shared";
        };
        description = "풀스택 프로젝트 파일 접근";
      };
      playwright = {
        command = "npx";
        args = ["--yes" "@anthropic/playwright-mcp-server"];
        description = "E2E 테스트 및 브라우저 자동화";
      };
      postgres = {
        command = "npx";
        args = ["--yes" "@anthropic/postgres-mcp-server"];
        description = "데이터베이스 관리";
      };
    };
  };

in {
  options.mcp.projectConfig = {
    projectType = mkOption {
      type = types.enum ["web" "nodejs" "python" "database" "fullstack" "custom"];
      default = "custom";
      description = "프로젝트 타입 (자동으로 적절한 MCP 서버들이 선택됨)";
    };

    projectServers = mkOption {
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

          projectOnly = mkOption {
            type = types.bool;
            default = true;
            description = "프로젝트별 전용 서버 여부";
          };
        };
      });
      default = {};
      description = "프로젝트별 MCP 서버 설정";
    };

    autoDetectProjectType = mkOption {
      type = types.bool;
      default = true;
      description = "프로젝트 파일을 분석하여 자동으로 타입 감지";
    };

    generateMcpJson = mkOption {
      type = types.bool;
      default = true;
      description = ".mcp.json 파일 자동 생성";
    };

    mcpJsonPath = mkOption {
      type = types.str;
      default = ".mcp.json";
      description = "MCP 설정 파일 경로";
    };
  };

  config = mkIf config.mcp.enable {
    # devShell에서 사용할 MCP 설정 스크립트들
    home.file.".local/bin/mcp-project-init" = {
      text = ''
        #!/bin/bash
        # 프로젝트별 MCP 설정 초기화 도구

        set -e

        PROJECT_ROOT="''${1:-$(pwd)}"
        PROJECT_TYPE="''${2:-auto}"

        echo "🚀 프로젝트 MCP 설정 초기화"
        echo "📁 프로젝트: $PROJECT_ROOT"

        cd "$PROJECT_ROOT"

        # 프로젝트 타입 자동 감지
        if [ "$PROJECT_TYPE" = "auto" ]; then
          echo "🔍 프로젝트 타입 자동 감지 중..."

          if [ -f "package.json" ]; then
            if grep -q "react\|vue\|angular" package.json 2>/dev/null; then
              PROJECT_TYPE="web"
            else
              PROJECT_TYPE="nodejs"
            fi
          elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
            PROJECT_TYPE="python"
          elif [ -f "docker-compose.yml" ] && grep -q "postgres\|mysql" docker-compose.yml 2>/dev/null; then
            PROJECT_TYPE="database"
          elif [ -d "frontend" ] && [ -d "backend" ]; then
            PROJECT_TYPE="fullstack"
          else
            PROJECT_TYPE="custom"
          fi

          echo "✅ 감지된 프로젝트 타입: $PROJECT_TYPE"
        fi

        # MCP 설정 생성
        MCP_CONFIG=".mcp.json"

        case "$PROJECT_TYPE" in
          "web")
            cat > "$MCP_CONFIG" << 'EOF'
        {
          "mcpServers": {
            "filesystem": {
              "command": "npx",
              "args": ["--yes", "@anthropic/filesystem-mcp-server"],
              "env": {
                "ALLOWED_DIRS": "./src,./tests,./docs,./public"
              }
            },
            "playwright": {
              "command": "npx",
              "args": ["--yes", "@anthropic/playwright-mcp-server"]
            }
          }
        }
        EOF
            ;;
          "nodejs")
            cat > "$MCP_CONFIG" << 'EOF'
        {
          "mcpServers": {
            "filesystem": {
              "command": "npx",
              "args": ["--yes", "@anthropic/filesystem-mcp-server"],
              "env": {
                "ALLOWED_DIRS": "./src,./lib,./tests,./docs"
              }
            }
          }
        }
        EOF
            ;;
          "python")
            cat > "$MCP_CONFIG" << 'EOF'
        {
          "mcpServers": {
            "filesystem": {
              "command": "python",
              "args": ["-m", "mcp_server_filesystem"],
              "env": {
                "ALLOWED_DIRS": "./src,./tests,./docs"
              }
            }
          }
        }
        EOF
            ;;
          "fullstack")
            cat > "$MCP_CONFIG" << 'EOF'
        {
          "mcpServers": {
            "filesystem": {
              "command": "npx",
              "args": ["--yes", "@anthropic/filesystem-mcp-server"],
              "env": {
                "ALLOWED_DIRS": "./frontend,./backend,./shared,./docs"
              }
            },
            "playwright": {
              "command": "npx",
              "args": ["--yes", "@anthropic/playwright-mcp-server"]
            }
          }
        }
        EOF
            ;;
          *)
            cat > "$MCP_CONFIG" << 'EOF'
        {
          "mcpServers": {
            "filesystem": {
              "command": "npx",
              "args": ["--yes", "@anthropic/filesystem-mcp-server"],
              "env": {
                "ALLOWED_DIRS": "./src,./docs"
              }
            }
          }
        }
        EOF
            ;;
        esac

        echo "✅ $MCP_CONFIG 파일 생성 완료"

        # .gitignore에 추가할지 확인
        if [ -f ".gitignore" ] && ! grep -q "\.mcp\.json" .gitignore; then
          read -p "🤔 .mcp.json을 .gitignore에 추가하시겠습니까? (Y/n): " -r
          if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "# MCP 설정 파일 (선택사항)" >> .gitignore
            echo ".mcp.json" >> .gitignore
            echo "✅ .gitignore에 .mcp.json 추가됨"
          fi
        fi

        # Claude Code가 설치되어 있으면 즉시 사용 가능
        if command -v claude-code >/dev/null 2>&1; then
          echo "💡 이제 'claude-code' 명령어로 프로젝트별 MCP 설정을 사용할 수 있습니다"
        else
          echo "💡 Claude Code CLI를 설치하면 프로젝트별 MCP 설정을 자동으로 사용할 수 있습니다"
        fi
      '';
      executable = true;
    };

    # MCP 프로젝트 설정 상태 확인 도구
    home.file.".local/bin/mcp-project-status" = {
      text = ''
        #!/bin/bash
        # 프로젝트별 MCP 설정 상태 확인

        set -e

        PROJECT_ROOT="''${1:-$(pwd)}"

        echo "📊 프로젝트 MCP 설정 상태"
        echo "=========================="
        echo "📁 프로젝트: $PROJECT_ROOT"

        cd "$PROJECT_ROOT"

        # .mcp.json 파일 확인
        if [ -f ".mcp.json" ]; then
          echo "✅ .mcp.json 파일 존재"

          if command -v jq >/dev/null 2>&1; then
            if jq empty .mcp.json 2>/dev/null; then
              echo "✅ JSON 형식 유효"

              SERVER_COUNT=$(jq '.mcpServers | length' .mcp.json 2>/dev/null || echo "0")
              echo "🔧 설정된 MCP 서버 수: $SERVER_COUNT"

              if [ "$SERVER_COUNT" -gt 0 ]; then
                echo "📋 설정된 서버들:"
                jq -r '.mcpServers | keys[]' .mcp.json 2>/dev/null | sed 's/^/  - /'
              fi
            else
              echo "❌ JSON 형식 오류"
            fi
          else
            echo "⚠️  jq가 설치되지 않아 상세 분석 불가"
          fi
        else
          echo "❌ .mcp.json 파일 없음"
          echo "💡 'mcp-project-init' 명령어로 초기화할 수 있습니다"
        fi

        # 프로젝트 타입 추측
        echo ""
        echo "🔍 프로젝트 타입 분석:"

        if [ -f "package.json" ]; then
          echo "  📦 Node.js 프로젝트 감지"
          if grep -q "react\|vue\|angular" package.json 2>/dev/null; then
            echo "  🌐 웹 프레임워크 감지"
          fi
        fi

        if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
          echo "  🐍 Python 프로젝트 감지"
        fi

        if [ -f "docker-compose.yml" ]; then
          echo "  🐳 Docker Compose 설정 감지"
        fi

        if [ -d "frontend" ] && [ -d "backend" ]; then
          echo "  🔧 풀스택 구조 감지"
        fi
      '';
      executable = true;
    };

    # devShell 훅 스크립트 (flake.nix에서 사용)
    home.file.".local/bin/mcp-devshell-hook" = {
      text = ''
        #!/bin/bash
        # devShell 진입 시 자동으로 MCP 설정 확인

        # 조용히 실행 (에러 출력 억제)
        if [ -f ".mcp.json" ] && command -v jq >/dev/null 2>&1; then
          if jq empty .mcp.json 2>/dev/null; then
            SERVER_COUNT=$(jq '.mcpServers | length' .mcp.json 2>/dev/null || echo "0")
            if [ "$SERVER_COUNT" -gt 0 ]; then
              echo "🔧 프로젝트별 MCP 설정 활성 ($SERVER_COUNT개 서버)"
            fi
          fi
        fi
      '';
      executable = true;
    };

    # 프로젝트 MCP 서버 테스트 도구
    home.file.".local/bin/mcp-project-test" = {
      text = ''
        #!/bin/bash
        # 프로젝트별 MCP 서버 연결 테스트

        set -e

        PROJECT_ROOT="''${1:-$(pwd)}"

        echo "🧪 프로젝트 MCP 서버 테스트"
        echo "=========================="

        cd "$PROJECT_ROOT"

        if [ ! -f ".mcp.json" ]; then
          echo "❌ .mcp.json 파일이 없습니다"
          echo "💡 'mcp-project-init' 명령어로 초기화하세요"
          exit 1
        fi

        if ! command -v jq >/dev/null 2>&1; then
          echo "❌ jq가 설치되지 않았습니다"
          exit 1
        fi

        # 각 서버 테스트
        jq -r '.mcpServers | keys[]' .mcp.json | while read -r server; do
          echo "🔧 $server 서버 테스트 중..."

          COMMAND=$(jq -r ".mcpServers.$server.command" .mcp.json)

          if command -v "$COMMAND" >/dev/null 2>&1; then
            echo "  ✅ 명령어 '$COMMAND' 사용 가능"
          else
            echo "  ❌ 명령어 '$COMMAND'를 찾을 수 없습니다"

            # npx 명령어인 경우 설치 제안
            if [ "$COMMAND" = "npx" ]; then
              PACKAGE=$(jq -r ".mcpServers.$server.args[-1]" .mcp.json)
              echo "  💡 다음 명령어로 설치 가능: npm install -g $PACKAGE"
            fi
          fi

          # 환경 변수 확인
          if jq -e ".mcpServers.$server.env" .mcp.json >/dev/null 2>&1; then
            echo "  📋 환경 변수 설정됨"
            jq -r ".mcpServers.$server.env | keys[]" .mcp.json | while read -r envvar; do
              VALUE=$(jq -r ".mcpServers.$server.env.$envvar" .mcp.json)
              echo "    $envvar=$VALUE"
            done
          fi
        done

        echo "✅ MCP 서버 테스트 완료"
      '';
      executable = true;
    };
  };
}
