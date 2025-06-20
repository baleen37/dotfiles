{ config, pkgs, lib, self, ... }:

let
  # Resolve user from USER env var
  getUser = import ../../lib/get-user.nix { };
  user = getUser;
  xdg_configHome = "/home/${user}/.config";
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib; };

  polybar-user_modules =
    let
      src = builtins.readFile ./config/polybar/user_modules.ini;
      from = [
        "@packages@"
        "@searchpkgs@"
        "@launcher@"
        "@powermenu@"
        "@calendar@"
      ];
      to = [
        "${xdg_configHome}/polybar/bin/check-nixos-updates.sh"
        "${xdg_configHome}/polybar/bin/search-nixos-updates.sh"
        "${xdg_configHome}/polybar/bin/launcher.sh"
        "${xdg_configHome}/rofi/bin/powermenu.sh"
        "${xdg_configHome}/polybar/bin/popup-calendar.sh"
      ];
    in
    builtins.replaceStrings from to src;

  polybar-config =
    let
      src = builtins.readFile ./config/polybar/config.ini;
      text = builtins.replaceStrings [ "@font0@" "@font1@" ] [ "DejaVu Sans:size=12;3" "feather:size=12;3" ] src;
    in
    builtins.toFile "polybar-config.ini" text;

  polybar-modules = builtins.readFile ./config/polybar/modules.ini;
  polybar-bars = builtins.readFile ./config/polybar/bars.ini;
  polybar-colors = builtins.readFile ./config/polybar/colors.ini;

in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix { };
    file = (import ../shared/files.nix { inherit config pkgs user self lib; }) // import ./files.nix { inherit user; };
    stateVersion = "21.05";
  };

  # Use a dark theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Screen lock
  services = {
    screen-locker = {
      enable = true;
      inactiveInterval = 10;
      lockCmd = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 10 15";
    };

    # Auto mount devices
    udiskie.enable = true;

    polybar = {
      enable = true;
      config = polybar-config;
      extraConfig = polybar-bars + polybar-colors + polybar-modules + polybar-user_modules;
      package = pkgs.polybarFull;
      script = "polybar main &";
    };

    dunst = {
      enable = true;
      package = pkgs.dunst;
      settings = {
        global = {
          monitor = 0;
          follow = "mouse";
          border = 0;
          height = 400;
          width = 320;
          offset = "33x65";
          indicate_hidden = "yes";
          shrink = "no";
          separator_height = 0;
          padding = 32;
          horizontal_padding = 32;
          frame_width = 0;
          sort = "no";
          idle_threshold = 120;
          font = "Noto Sans";
          line_height = 4;
          markup = "full";
          format = "<b>%s</b>\n%b";
          alignment = "left";
          transparency = 10;
          show_age_threshold = 60;
          word_wrap = "yes";
          ignore_newline = "no";
          stack_duplicates = false;
          hide_duplicate_count = "yes";
          show_indicators = "no";
          icon_position = "left";
          icon_theme = "Adwaita-dark";
          sticky_history = "yes";
          history_length = 20;
          history = "ctrl+grave";
          browser = "google-chrome-stable";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          max_icon_size = 64;
        };
      };
    };
  };

  programs = shared-programs // { };

  # Smart Claude config files management with user modification preservation
  # Same as Darwin implementation for platform consistency
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
            # 파일이 심볼릭 링크인 경우에만 실제 파일로 변환
            if [[ -L "$target_file" ]]; then
              echo "  심볼릭 링크를 실제 파일로 변환"
              local link_target=$(readlink "$target_file")
              $DRY_RUN_CMD rm "$target_file"
              $DRY_RUN_CMD cp "$link_target" "$target_file"
              $DRY_RUN_CMD chmod 644 "$target_file"
            else
              echo "  파일 동일, 건너뜀"
            fi
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
        if [[ -d "$SOURCE_DIR/commands" ]]; then
          for cmd_file in "$SOURCE_DIR/commands"/*.md; do
            if [[ -f "$cmd_file" ]]; then
              local base_name=$(basename "$cmd_file")
              smart_copy "$cmd_file" "$CLAUDE_DIR/commands/$base_name"
            fi
          done
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

}
