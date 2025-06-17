{ config, pkgs, lib, home-manager, self, ... }:

let
  # Resolve user from USER env var
  getUser = import ../../lib/get-user.nix { };
  user = getUser;
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
    ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    # onActivation.cleanup = "uninstall";

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)
    masApps = {
      "1password" = 1333542190;
      "wireguard" = 1451685025;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    users.${user} = { pkgs, config, lib, ... }: {
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix { };
        file = lib.mkMerge [
          (import ../shared/files.nix { inherit config pkgs user self lib; })
          additionalFiles
        ];
        stateVersion = "23.11";
      };
      programs = lib.mkMerge [
        (import ../shared/home-manager.nix { inherit config pkgs lib; })
      ];

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;

      # Smart Claude config files management with user modification preservation
      home.activation.copyClaudeFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
                set -euo pipefail  # Enable strict error handling

                # DRY_RUN_CMD 변수 초기화 (DRY_RUN이 정의되지 않은 경우 기본값 설정)
                DRY_RUN_CMD=""
                if [[ "''${DRY_RUN:-}" == "1" ]]; then
                  DRY_RUN_CMD="echo '[DRY RUN]'"
                fi

                $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.claude/commands"

                CLAUDE_DIR="${config.home.homeDirectory}/.claude"
                SOURCE_DIR="${self}/modules/shared/config/claude"
                echo "=== 스마트 Claude 설정 업데이트 시작 ==="
                echo "Claude 디렉토리: $CLAUDE_DIR"
                echo "소스 디렉토리: $SOURCE_DIR"

                # 파일 해시 비교 함수
                files_differ() {
                  local source="$1"
                  local target="$2"

                  if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
                    return 0  # 파일이 없으면 다른 것으로 간주
                  fi

                  # Nix 환경에서는 sha256sum 사용
                  local source_hash=$(sha256sum "$source" | cut -d' ' -f1)
                  local target_hash=$(sha256sum "$target" | cut -d' ' -f1)
                  [[ "$source_hash" != "$target_hash" ]]
                }

                # 백업 생성 함수
                create_backup() {
                  local file="$1"
                  local backup_dir="$CLAUDE_DIR/.backups"
                  local timestamp=$(date +%Y%m%d_%H%M%S)

                  if [[ -f "$file" ]]; then
                    $DRY_RUN_CMD mkdir -p "$backup_dir"
                    $DRY_RUN_CMD cp "$file" "$backup_dir/$(basename "$file").backup.$timestamp"
                    echo "백업 생성: $backup_dir/$(basename "$file").backup.$timestamp"
                  fi
                }

                # 조건부 복사 함수 (사용자 수정 보존)
                smart_copy() {
                  local source_file="$1"
                  local target_file="$2"
                  local file_name=$(basename "$source_file")

                  echo "처리 중: $file_name"

                  if [[ ! -f "$source_file" ]]; then
                    echo "  소스 파일 없음, 건너뜀"
                    return 0
                  fi

                  if [[ ! -f "$target_file" ]]; then
                    echo "  새 파일 복사"
                    $DRY_RUN_CMD cp "$source_file" "$target_file"
                    $DRY_RUN_CMD chmod 644 "$target_file"
                    return 0
                  fi

                  if files_differ "$source_file" "$target_file"; then
                    echo "  사용자 수정 감지됨"

                    # 높은 우선순위 파일들은 보존 (settings.json, CLAUDE.md)
                    case "$file_name" in
                      "settings.json"|"CLAUDE.md")
                        echo "  사용자 버전 보존, 새 버전을 .new로 저장"
                        $DRY_RUN_CMD cp "$source_file" "$target_file.new"
                        $DRY_RUN_CMD chmod 644 "$target_file.new"

                        # 사용자 알림 메시지 생성
                        if [[ "$DRY_RUN_CMD" == "" ]]; then
                          cat > "$target_file.update-notice" << EOF
        파일 업데이트 알림: $file_name

        이 파일이 dotfiles에서 업데이트되었지만, 사용자가 수정한 내용이 감지되어
        기존 파일을 보존했습니다.

        - 현재 파일: $target_file (사용자 수정 버전)
        - 새 버전: $target_file.new (dotfiles 최신 버전)

        변경 사항을 확인하고 수동으로 병합하세요:
          diff "$target_file" "$target_file.new"

        병합 완료 후 다음 파일들을 삭제하세요:
          rm "$target_file.new" "$target_file.update-notice"

        생성 시간: $(date)
        EOF
                          echo "  업데이트 알림 생성: $target_file.update-notice"
                        fi
                        ;;
                      *)
                        echo "  백업 후 덮어쓰기"
                        create_backup "$target_file"
                        $DRY_RUN_CMD cp "$source_file" "$target_file"
                        $DRY_RUN_CMD chmod 644 "$target_file"
                        ;;
                    esac
                  else
                    echo "  파일 동일하지만 강제 덮어쓰기"
                    $DRY_RUN_CMD cp "$source_file" "$target_file"
                    $DRY_RUN_CMD chmod 644 "$target_file"
                  fi
                }

                # symlink를 실제 파일로 변환하는 함수
                convert_symlink() {
                  local file="$1"
                  if [[ -L "$file" ]]; then
                    local target=$(readlink "$file")
                    if [[ -n "$target" && -f "$target" ]]; then
                      echo "심볼릭 링크를 실제 파일로 변환: $(basename "$file")"
                      $DRY_RUN_CMD rm "$file"
                      $DRY_RUN_CMD cp "$target" "$file"
                      $DRY_RUN_CMD chmod 644 "$file"
                    fi
                  fi
                }

                # 기존 home-manager backup 파일 정리 (우리가 직접 관리하므로)
                echo "기존 백업 파일 정리..."
                $DRY_RUN_CMD rm -f "$CLAUDE_DIR"/*.bak
                $DRY_RUN_CMD rm -f "$CLAUDE_DIR/commands"/*.bak

                # 먼저 symlink들을 실제 파일로 변환
                for config_file in "CLAUDE.md" "settings.json"; do
                  target_file="$CLAUDE_DIR/$config_file"
                  if [[ -L "$target_file" ]]; then
                    convert_symlink "$target_file"
                  fi
                done

                for cmd_file in "$CLAUDE_DIR/commands"/*.md; do
                  if [[ -L "$cmd_file" ]]; then
                    convert_symlink "$cmd_file"
                  fi
                done

                # 스마트 복사 실행
                echo ""
                echo "=== Claude 설정 파일 업데이트 ==="

                # 메인 설정 파일들 처리
                for config_file in "settings.json" "CLAUDE.md"; do
                  smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
                done

                # commands 디렉토리 처리
                echo ""
                echo "=== Claude 명령어 파일 복사 ==="
                if [[ -d "$SOURCE_DIR/commands" ]]; then
                  for cmd_file in "$SOURCE_DIR/commands"/*.md; do
                    if [[ -f "$cmd_file" ]]; then
                      base_name=$(basename "$cmd_file")
                      echo "명령어 파일 처리: $base_name"
                      smart_copy "$cmd_file" "$CLAUDE_DIR/commands/$base_name"
                    fi
                  done
                  echo "명령어 파일 복사 완료"
                else
                  echo "경고: $SOURCE_DIR/commands 디렉토리를 찾을 수 없습니다"
                fi

                # 오래된 백업 파일 정리 (30일 이상)
                if [[ -d "$CLAUDE_DIR/.backups" ]]; then
                  echo ""
                  echo "오래된 백업 파일 정리 중..."
                  $DRY_RUN_CMD find "$CLAUDE_DIR/.backups" -name "*.backup.*" -mtime +30 -delete 2>/dev/null || true
                fi

                # 사용자 알림 요약
                NOTICE_COUNT=$(find "$CLAUDE_DIR" -name "*.update-notice" 2>/dev/null | wc -l)
                if [[ $NOTICE_COUNT -gt 0 ]]; then
                  echo ""
                  echo "주의: $NOTICE_COUNT개의 업데이트 알림이 생성되었습니다."
                  echo "다음 명령어로 확인하세요: find $CLAUDE_DIR -name '*.update-notice'"
                  echo ""
                fi

                echo "=== Claude 설정 업데이트 완료 ==="
      '';
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock = {
    enable = true;
    username = user;
    entries = [
      { path = "/Applications/Slack.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Facetime.app/"; }
      { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/News.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/Photo Booth.app/"; }
      { path = "/System/Applications/TV.app/"; }
      { path = "/System/Applications/Home.app/"; }
      { path = "/Applications/Karabiner-Elements.app/"; }
      { path = "/Applications/Raycast.app/"; }
      { path = "/Applications/Obsidian.app/"; }
      {
        path = "${config.users.users.${user}.home}/.local/share/";
        section = "others";
        options = "--sort name --view grid --display folder";
      }
      {
        path = "${config.users.users.${user}.home}/.local/share/downloads";
        section = "others";
        options = "--sort name --view grid --display stack";
      }
    ];
  };

}
