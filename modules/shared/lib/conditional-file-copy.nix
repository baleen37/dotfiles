# ABOUTME: 파일 변경 감지 결과에 따른 조건부 복사 로직
# ABOUTME: 정책 기반으로 파일을 보존하거나 덮어쓰는 스마트 복사 시스템

{ lib, pkgs }:

let
  # 의존성 라이브러리들
  policyLib = import ./claude-config-policy.nix { inherit lib pkgs; };
  detectorLib = import ./file-change-detector.nix { inherit lib pkgs; };

  # 단일 파일에 대한 조건부 복사 실행
  conditionalCopyFile =
    { sourcePath
    , targetPath
    , claudeDir ? null
    , policy ? null
    , dryRun ? false
    , verbose ? true
    }:
    let
      # 기본값 설정

      # 변경 감지 실행
      detection = detectorLib.compareFiles sourcePath targetPath;

      # 정책 결정 (전달된 정책이 없으면 자동 결정)
      finalPolicy =
        if policy != null then policy
        else policyLib.getPolicyForFile targetPath detection.userModified;

      # 액션 생성
      actions = policyLib.generateActions targetPath sourcePath detection;

      # 실제 실행할 쉘 명령어들
      commands =
        if dryRun then
          map (cmd: "echo \"DRY RUN: ${cmd}\"") actions.commands
        else
          actions.commands;

      # 로그 메시지들
      logMessages = [
        "=== 조건부 파일 복사 ==="
        "소스: ${sourcePath}"
        "타겟: ${targetPath}"
        "정책: ${finalPolicy.action}"
        "사용자 수정됨: ${if detection.userModified then "예" else "아니오"}"
      ] ++ (if verbose then [
        "원본 해시: ${detection.details.originalHash or "null"}"
        "현재 해시: ${detection.details.currentHash or "null"}"
      ] else [ ]);

      result = {
        inherit sourcePath targetPath detection finalPolicy actions;
        inherit dryRun verbose commands logMessages;

        success = true; # 실제로는 실행 결과에 따라 결정

        # 실행 통계
        stats = {
          preserved = actions.preserve;
          overwritten = actions.overwrite;
          ignored = actions.ignore;
          backupCreated = finalPolicy.backup and actions.overwrite;
          noticeCreated = actions.policy.createNotice;
        };
      };
    in
    result;

  # 여러 파일에 대한 일괄 조건부 복사
  conditionalCopyDirectory =
    { sourceDir
    , targetDir
    , fileList ? null
    , dryRun ? false
    , verbose ? true
    , parallelJobs ? 1
    }:
    let
      # 파일 목록 자동 생성 (제공되지 않은 경우)
      actualFileList =
        if fileList != null then fileList
        else policyLib.utils.getAllConfigFiles;

      # 전체 디렉토리 변경 감지
      detectionResults = detectorLib.detectClaudeConfigChanges targetDir sourceDir;

      # 전체 처리 계획 생성
      directoryPlan = policyLib.generateDirectoryPlan targetDir sourceDir detectionResults.fileResults;

      # 각 파일에 대해 개별 처리
      fileResults = map
        (fileName:
          let
            sourcePath = "${sourceDir}/${fileName}";
            targetPath = "${targetDir}/${fileName}";
            fileDetection = detectionResults.fileResults.${fileName} or null;
          in
          if fileDetection != null then
            conditionalCopyFile
              {
                inherit sourcePath targetPath dryRun verbose;
                claudeDir = targetDir;
              }
          else {
            # 감지 결과가 없는 파일 (새 파일 등)
            sourcePath = sourcePath;
            targetPath = targetPath;
            detection = null;
            finalPolicy = policyLib.preservationPolicies.ignore;
            actions = { commands = [ "echo \"Skipping ${fileName} (not detected)\"" ]; };
            success = true;
            stats = { preserved = false; overwritten = false; ignored = true; };
          }
        )
        actualFileList;

      # 전체 통계 계산
      overallStats = {
        total = lib.length fileResults;
        preserved = lib.length (lib.filter (r: r.stats.preserved or false) fileResults);
        overwritten = lib.length (lib.filter (r: r.stats.overwritten or false) fileResults);
        ignored = lib.length (lib.filter (r: r.stats.ignored or false) fileResults);
        backupsCreated = lib.length (lib.filter (r: r.stats.backupCreated or false) fileResults);
        noticesCreated = lib.length (lib.filter (r: r.stats.noticeCreated or false) fileResults);
        errors = lib.length (lib.filter (r: !(r.success or true)) fileResults);
      };

      # 전체 실행 스크립트 생성
      allCommands = lib.concatMap (result: result.commands) fileResults;

      result = {
        inherit sourceDir targetDir fileList dryRun verbose;
        inherit detectionResults directoryPlan fileResults overallStats;

        commands = allCommands;

        # 요약 리포트
        summary = ''
          조건부 디렉토리 복사 완료
          =========================

          소스 디렉토리: ${sourceDir}
          타겟 디렉토리: ${targetDir}
          처리된 파일: ${toString overallStats.total}개

          처리 결과:
          - 보존됨: ${toString overallStats.preserved}개
          - 덮어쓰기됨: ${toString overallStats.overwritten}개
          - 무시됨: ${toString overallStats.ignored}개
          - 백업 생성됨: ${toString overallStats.backupsCreated}개
          - 알림 생성됨: ${toString overallStats.noticesCreated}개
          - 오류: ${toString overallStats.errors}개

          ${if dryRun then "*** 이것은 DRY RUN입니다. 실제 파일은 변경되지 않았습니다. ***" else ""}
        '';
      };
    in
    result;

  # 쉘 스크립트 형태의 조건부 복사 함수 생성
  generateConditionalCopyScript =
    { sourceDir
    , targetDir
    , scriptName ? "conditional-copy"
    , includeValidation ? true
    , includeBackup ? true
    , includeLogging ? true
    }:
    let
      validationSection =
        if includeValidation then ''
          # 입력 검증
          validate_inputs() {
            if [[ ! -d "${sourceDir}" ]]; then
              echo "오류: 소스 디렉토리가 존재하지 않음: ${sourceDir}" >&2
              exit 1
            fi

            if [[ ! -d "${targetDir}" ]]; then
              echo "타겟 디렉토리 생성: ${targetDir}"
              mkdir -p "${targetDir}"
            fi

            if [[ ! -w "${targetDir}" ]]; then
              echo "오류: 타겟 디렉토리에 쓰기 권한이 없음: ${targetDir}" >&2
              exit 1
            fi
          }
        '' else "";

      backupSection =
        if includeBackup then ''
          # 백업 함수
          create_backup() {
            local file="$1"
            local backup_dir="${targetDir}/.backups"
            local timestamp=$(date +%Y%m%d_%H%M%S)

            if [[ -f "$file" ]]; then
              mkdir -p "$backup_dir"
              cp "$file" "$backup_dir/$(basename "$file").backup.$timestamp"
              echo "백업 생성: $backup_dir/$(basename "$file").backup.$timestamp"
            fi
          }
        '' else "";

      loggingSection =
        if includeLogging then ''
          # 로깅 함수
          log_action() {
            local action="$1"
            local file="$2"
            local timestamp=$(date -Iseconds)
            echo "[$timestamp] $action: $file" >> "${targetDir}/.copy-log"
          }
        '' else "";

      scriptContent = ''
        #!/bin/bash
        # 조건부 파일 복사 스크립트: ${scriptName}
        # 생성됨: $(date)

        set -euo pipefail

        SOURCE_DIR="${sourceDir}"
        TARGET_DIR="${targetDir}"

        ${validationSection}

        ${backupSection}

        ${loggingSection}

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

        # 조건부 복사 함수
        conditional_copy() {
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
            cp "$source_file" "$target_file"
            chmod 644 "$target_file"
            ${if includeLogging then ''log_action "NEW" "$target_file"'' else ""}
            return 0
          fi

          if files_differ "$source_file" "$target_file"; then
            echo "  사용자 수정 감지됨"

            # 높은 우선순위 파일들은 보존
            case "$file_name" in
              "settings.json"|"CLAUDE.md")
                echo "  사용자 버전 보존, 새 버전을 .new로 저장"
                cp "$source_file" "$target_file.new"
                chmod 644 "$target_file.new"

                # 알림 메시지 생성
                cat > "$target_file.update-notice" << EOF
        파일 업데이트 알림: $file_name

        이 파일이 업데이트되었지만 사용자 수정이 감지되어 기존 파일을 보존했습니다.

        - 현재 파일: $target_file (사용자 수정 버전)
        - 새 버전: $target_file.new (dotfiles 최신 버전)

        변경사항을 확인하세요: diff "$target_file" "$target_file.new"

        확인 후 이 알림을 삭제하세요: rm "$target_file.update-notice"
        EOF

                ${if includeLogging then ''log_action "PRESERVED" "$target_file"'' else ""}
                ;;
              *)
                echo "  백업 후 덮어쓰기"
                ${if includeBackup then ''create_backup "$target_file"'' else ""}
                cp "$source_file" "$target_file"
                chmod 644 "$target_file"
                ${if includeLogging then ''log_action "OVERWRITTEN" "$target_file"'' else ""}
                ;;
            esac
          else
            echo "  파일 동일함, 건너뜀"
            ${if includeLogging then ''log_action "SKIPPED" "$target_file"'' else ""}
          fi
        }

        # 메인 실행 부분
        main() {
          echo "조건부 파일 복사 시작"
          echo "소스: $SOURCE_DIR"
          echo "타겟: $TARGET_DIR"
          echo ""

          ${if includeValidation then "validate_inputs" else ""}

          # Claude 설정 파일들 처리
          for config_file in "settings.json" "CLAUDE.md"; do
            conditional_copy "$SOURCE_DIR/$config_file" "$TARGET_DIR/$config_file"
          done

          # commands 디렉토리 처리
          if [[ -d "$SOURCE_DIR/commands" ]]; then
            mkdir -p "$TARGET_DIR/commands"
            for cmd_file in "$SOURCE_DIR/commands"/*.md; do
              if [[ -f "$cmd_file" ]]; then
                local base_name=$(basename "$cmd_file")
                conditional_copy "$cmd_file" "$TARGET_DIR/commands/$base_name"
              fi
            done
          fi

          echo ""
          echo "조건부 파일 복사 완료"
        }

        # 스크립트가 직접 실행될 때만 main 함수 호출
        if [[ "''${BASH_SOURCE[0]}" == "''${0}" ]]; then
          main "$@"
        fi
      '';
    in
    pkgs.writeShellScript scriptName scriptContent;

  # Claude 설정 전용 고수준 인터페이스
  updateClaudeConfig =
    { claudeDir ? "$HOME/.claude"
    , sourceConfigPath ? null
    , dryRun ? false
    , verbose ? true
    , createBackups ? true
    , notifyUser ? true
    }:
    let
      # 기본 소스 경로 설정
      actualSourcePath =
        if sourceConfigPath != null then sourceConfigPath
        else ./../../modules/shared/config/claude;

      # Claude 설정 업데이트 실행
      result = conditionalCopyDirectory {
        sourceDir = actualSourcePath;
        targetDir = claudeDir;
        inherit dryRun verbose;
      };

      # 추가 처리 (알림, 백업 정리 등)
      postProcessing = {
        # 오래된 백업 파일 정리
        cleanupOldBackups =
          if createBackups then ''
            find "${claudeDir}" -name "*.backup.*" -mtime +30 -delete 2>/dev/null || true
          '' else "";

        # 사용자 알림 요약
        userNotification =
          if notifyUser && !dryRun then ''
            if [[ ${toString result.overallStats.noticesCreated} -gt 0 ]]; then
              echo ""
              echo "주의: ${toString result.overallStats.noticesCreated}개의 업데이트 알림이 생성되었습니다."
              echo "다음 명령어로 확인하세요: find ${claudeDir} -name '*.update-notice'"
              echo ""
            fi
          '' else "";
      };

      enhancedResult = result // {
        inherit postProcessing;

        # 최종 실행 스크립트
        finalScript = result.commands ++ [
          postProcessing.cleanupOldBackups
          postProcessing.userNotification
        ];
      };
    in
    enhancedResult;

in
{
  # 공개 API
  inherit conditionalCopyFile conditionalCopyDirectory;
  inherit generateConditionalCopyScript updateClaudeConfig;

  # 유틸리티 함수들
  utils = {
    # 간단한 파일 복사 (정책 없이)
    simpleCopy = sourcePath: targetPath: {
      commands = [ "cp \"${sourcePath}\" \"${targetPath}\"" ];
      stats = { overwritten = true; preserved = false; ignored = false; };
    };

    # 백업 생성
    createBackup = filePath: timestamp:
      "cp \"${filePath}\" \"${filePath}.backup.${timestamp}\"";

    # 알림 파일 생성
    createNotice = filePath: message:
      "echo '${message}' > \"${filePath}.update-notice\"";
  };

  # 상수들
  constants = {
    defaultFilePermissions = "644";
    backupSuffix = "backup";
    newFileSuffix = "new";
    noticeSuffix = "update-notice";
    maxBackupAge = 30; # days
  };

  # 테스트 지원
  test = {
    # 테스트용 목 결과 생성
    mockCopyResult =
      { preserved ? 1
      , overwritten ? 1
      , ignored ? 1
      }: {
        overallStats = {
          total = preserved + overwritten + ignored;
          inherit preserved overwritten ignored;
          backupsCreated = overwritten;
          noticesCreated = preserved;
          errors = 0;
        };

        summary = "Mock copy result with ${toString (preserved + overwritten + ignored)} files";
      };

    # 테스트용 간단한 스크립트
    simpleTestScript = generateConditionalCopyScript {
      sourceDir = "/tmp/test-source";
      targetDir = "/tmp/test-target";
      scriptName = "test-conditional-copy";
      includeValidation = false;
      includeBackup = false;
      includeLogging = false;
    };
  };
}
