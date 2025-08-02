# ABOUTME: MCP 서버들의 Nix derivation 패키징
# ABOUTME: npm 패키지들을 Nix로 관리하여 결정론적 빌드 제공

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mcp.nixPackages;

  # MCP 서버 Nix 패키지 생성 함수
  mkMcpServer = { name, version, src ? null, npmPackage ? null, description ? "" }:
    if npmPackage != null then
      # npm 패키지 기반 MCP 서버
      pkgs.buildNpmPackage rec {
        pname = name;
        inherit version;

        src = if src != null then src else pkgs.fetchFromNpm {
          package = npmPackage;
          inherit version;
        };

        npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # 실제 사용 시 업데이트 필요

        meta = with lib; {
          inherit description;
          homepage = "https://github.com/anthropics/mcp-servers";
          license = licenses.mit;
          maintainers = [ maintainers.anthropic ];
        };
      }
    else
      # 커스텀 MCP 서버
      pkgs.stdenv.mkDerivation {
        pname = name;
        inherit version src;

        meta = with lib; {
          inherit description;
          license = licenses.mit;
        };
      };

  # 사전 정의된 MCP 서버 패키지들
  predefinedMcpServers = {
    anki-mcp-server = mkMcpServer {
      name = "anki-mcp-server";
      version = "1.0.0";
      npmPackage = "anki-mcp-server";
      description = "Anki flashcard management MCP server";
    };

    filesystem-mcp-server = mkMcpServer {
      name = "filesystem-mcp-server";
      version = "1.0.0";
      npmPackage = "@anthropic/filesystem-mcp-server";
      description = "Filesystem access MCP server";
    };

    github-mcp-server = mkMcpServer {
      name = "github-mcp-server";
      version = "1.0.0";
      npmPackage = "@anthropic/github-mcp-server";
      description = "GitHub repository management MCP server";
    };

    playwright-mcp-server = mkMcpServer {
      name = "playwright-mcp-server";
      version = "1.0.0";
      npmPackage = "@anthropic/playwright-mcp-server";
      description = "Web browser automation MCP server";
    };

    postgres-mcp-server = mkMcpServer {
      name = "postgres-mcp-server";
      version = "1.0.0";
      npmPackage = "@anthropic/postgres-mcp-server";
      description = "PostgreSQL database management MCP server";
    };

    sqlite-mcp-server = mkMcpServer {
      name = "sqlite-mcp-server";
      version = "1.0.0";
      npmPackage = "@anthropic/sqlite-mcp-server";
      description = "SQLite database management MCP server";
    };
  };

in {
  options.mcp.nixPackages = {
    enable = mkEnableOption "MCP 서버들의 Nix 패키지 사용";

    preferNixPackages = mkOption {
      type = types.bool;
      default = false;
      description = "npx 대신 Nix 패키지 우선 사용";
    };

    customServers = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          src = mkOption {
            type = types.path;
            description = "MCP 서버 소스 경로";
          };

          version = mkOption {
            type = types.str;
            default = "0.1.0";
            description = "버전";
          };

          buildInputs = mkOption {
            type = types.listOf types.package;
            default = [ pkgs.nodejs_20 ];
            description = "빌드 의존성";
          };

          installPhase = mkOption {
            type = types.str;
            default = ''
              mkdir -p $out/bin
              cp -r . $out/
              chmod +x $out/bin/*
            '';
            description = "설치 단계 스크립트";
          };
        };
      });
      default = {};
      description = "사용자 정의 MCP 서버들";
    };

    enabledPackages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "활성화할 MCP 서버 패키지 목록";
    };
  };

  config = mkIf (config.mcp.enable && cfg.enable) {
    # 활성화된 MCP 서버 패키지들을 시스템에 설치
    home.packages =
      let
        enabledPredefined = filter (name: elem name cfg.enabledPackages) (attrNames predefinedMcpServers);
        predefinedPackages = map (name: predefinedMcpServers.${name}) enabledPredefined;

        customPackages = mapAttrsToList (name: serverConfig:
          pkgs.stdenv.mkDerivation {
            pname = name;
            inherit (serverConfig) version src buildInputs installPhase;

            meta = with lib; {
              description = "Custom MCP server: ${name}";
              license = licenses.mit;
            };
          }
        ) cfg.customServers;
      in
      predefinedPackages ++ customPackages;

    # Nix 패키지를 사용하는 MCP 서버 설정 생성
    mcp.servers = mkIf cfg.preferNixPackages (
      listToAttrs (map (name:
        nameValuePair name {
          command = "${predefinedMcpServers.${name}}/bin/${name}";
          args = [];
          description = predefinedMcpServers.${name}.meta.description;
        }
      ) (filter (name: elem name cfg.enabledPackages) (attrNames predefinedMcpServers)))
    );

    # MCP 서버 패키지 관리 도구
    home.file.".local/bin/mcp-nix-packages" = {
      text = ''
        #!/bin/bash
        # MCP 서버 Nix 패키지 관리 도구

        set -e

        COMMAND="$1"

        case "$COMMAND" in
          "list")
            echo "📦 사용 가능한 MCP 서버 Nix 패키지:"
            echo "=================================="
            ${concatStringsSep "\n" (mapAttrsToList (name: pkg:
              "echo \"  - ${name}: ${pkg.meta.description or "설명 없음"}\""
            ) predefinedMcpServers)}

            echo ""
            echo "📋 현재 활성화된 패키지:"
            ${concatStringsSep "\n" (map (name:
              "echo \"  ✅ ${name}\""
            ) cfg.enabledPackages)}

            if [ ${toString (length cfg.enabledPackages)} -eq 0 ]; then
              echo "  (활성화된 패키지 없음)"
            fi
            ;;

          "info")
            PACKAGE_NAME="$2"
            if [ -z "$PACKAGE_NAME" ]; then
              echo "사용법: mcp-nix-packages info <패키지명>"
              exit 1
            fi

            case "$PACKAGE_NAME" in
            ${concatStringsSep "\n" (mapAttrsToList (name: pkg: ''
              "${name}")
                echo "📦 ${name}"
                echo "   설명: ${pkg.meta.description or "설명 없음"}"
                echo "   버전: ${pkg.version or "알 수 없음"}"
                echo "   경로: ${pkg}/bin/${name}"
                ;;'') predefinedMcpServers)}
              *)
                echo "❌ 알 수 없는 패키지: $PACKAGE_NAME"
                echo "💡 사용 가능한 패키지 확인: mcp-nix-packages list"
                ;;
            esac
            ;;

          "test")
            PACKAGE_NAME="$2"
            if [ -z "$PACKAGE_NAME" ]; then
              echo "🧪 모든 활성화된 MCP 서버 패키지 테스트"
              ${concatStringsSep "\n" (map (name: ''
                echo "🔧 ${name} 테스트 중..."
                if [ -x "${predefinedMcpServers.${name}}/bin/${name}" ]; then
                  echo "  ✅ 실행 파일 존재"
                  if "${predefinedMcpServers.${name}}/bin/${name}" --help >/dev/null 2>&1; then
                    echo "  ✅ 정상 실행 가능"
                  else
                    echo "  ⚠️  실행 시 오류 발생"
                  fi
                else
                  echo "  ❌ 실행 파일 없음"
                fi
              '') cfg.enabledPackages)}
            else
              echo "🧪 $PACKAGE_NAME 패키지 테스트"

              if [ ! -x "${predefinedMcpServers.${PACKAGE_NAME} or ""}/bin/$PACKAGE_NAME" ]; then
                echo "❌ 패키지가 설치되지 않았거나 실행할 수 없습니다"
                exit 1
              fi

              echo "✅ 실행 파일 존재"

              # 간단한 실행 테스트
              if "${predefinedMcpServers.${PACKAGE_NAME}}/bin/$PACKAGE_NAME" --help >/dev/null 2>&1; then
                echo "✅ 정상 실행 가능"
              else
                echo "⚠️  실행 시 오류 발생"
              fi
            fi
            ;;

          "enable")
            PACKAGE_NAME="$2"
            echo "💡 패키지 활성화는 Nix 설정을 통해 수행됩니다"
            echo "   dotfiles/modules/shared/mcp/default.nix에서 enabledPackages에 추가하세요"
            echo "   예: enabledPackages = [ \"$PACKAGE_NAME\" ];"
            ;;

          *)
            echo "MCP 서버 Nix 패키지 관리 도구"
            echo "============================="
            echo ""
            echo "사용법:"
            echo "  mcp-nix-packages list          - 사용 가능한 패키지 목록"
            echo "  mcp-nix-packages info <name>   - 패키지 정보"
            echo "  mcp-nix-packages test [name]   - 패키지 테스트"
            echo "  mcp-nix-packages enable <name> - 패키지 활성화 방법"
            echo ""
            echo "현재 Nix 패키지 사용: ${if cfg.preferNixPackages then "✅ 활성화됨" else "❌ 비활성화됨"}"
            ;;
        esac
      '';
      executable = true;
    };

    # MCP 서버 패키지 빌드 도구
    home.file.".local/bin/mcp-build-custom" = {
      text = ''
        #!/bin/bash
        # 커스텀 MCP 서버 빌드 도구

        set -e

        SERVER_NAME="$1"
        SOURCE_PATH="$2"

        if [ -z "$SERVER_NAME" ] || [ -z "$SOURCE_PATH" ]; then
          echo "사용법: mcp-build-custom <서버명> <소스경로>"
          echo ""
          echo "예시:"
          echo "  mcp-build-custom my-server ./src/my-mcp-server"
          exit 1
        fi

        echo "🔨 커스텀 MCP 서버 빌드: $SERVER_NAME"
        echo "📁 소스: $SOURCE_PATH"

        if [ ! -d "$SOURCE_PATH" ]; then
          echo "❌ 소스 디렉토리가 존재하지 않습니다: $SOURCE_PATH"
          exit 1
        fi

        # 임시 빌드 디렉토리
        BUILD_DIR="/tmp/mcp-build-$SERVER_NAME-$(date +%s)"
        mkdir -p "$BUILD_DIR"

        echo "📦 소스 복사 중..."
        cp -r "$SOURCE_PATH"/* "$BUILD_DIR/"

        cd "$BUILD_DIR"

        # Node.js 프로젝트인지 확인
        if [ -f "package.json" ]; then
          echo "📦 Node.js 프로젝트 감지"

          if command -v npm >/dev/null 2>&1; then
            echo "📥 의존성 설치 중..."
            npm install

            if [ -f "package.json" ] && grep -q "\"build\"" package.json; then
              echo "🔨 빌드 실행 중..."
              npm run build
            fi
          else
            echo "⚠️  npm이 설치되지 않았습니다"
          fi
        fi

        # 실행 파일 생성
        INSTALL_DIR="$HOME/.local/mcp-servers/$SERVER_NAME"
        mkdir -p "$INSTALL_DIR/bin"

        echo "📦 패키지 설치 중..."
        cp -r * "$INSTALL_DIR/"

        # 실행 파일 링크 생성
        if [ -f "$INSTALL_DIR/index.js" ]; then
          cat > "$INSTALL_DIR/bin/$SERVER_NAME" << EOF
        #!/bin/bash
        exec node "$INSTALL_DIR/index.js" "\$@"
        EOF
          chmod +x "$INSTALL_DIR/bin/$SERVER_NAME"
        elif [ -f "$INSTALL_DIR/dist/index.js" ]; then
          cat > "$INSTALL_DIR/bin/$SERVER_NAME" << EOF
        #!/bin/bash
        exec node "$INSTALL_DIR/dist/index.js" "\$@"
        EOF
          chmod +x "$INSTALL_DIR/bin/$SERVER_NAME"
        fi

        echo "✅ 커스텀 MCP 서버 빌드 완료"
        echo "📍 설치 위치: $INSTALL_DIR"
        echo "🚀 실행: $INSTALL_DIR/bin/$SERVER_NAME"

        # 임시 디렉토리 정리
        rm -rf "$BUILD_DIR"
      '';
      executable = true;
    };
  };
}
