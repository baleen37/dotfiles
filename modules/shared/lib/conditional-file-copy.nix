{ lib, pkgs }:

let
  # 새로운 모듈화된 라이브러리들
  changeDetector = import ./change-detector.nix { inherit lib pkgs; };
  policyResolver = import ./policy-resolver.nix { inherit lib pkgs; };
  copyEngine = import ./copy-engine.nix { inherit lib pkgs; };

  # 레거시 호환성을 위한 기존 라이브러리들
  policyLib = import ./claude-config-policy.nix { inherit lib pkgs; };
  detectorLib = import ./file-change-detector.nix { inherit lib pkgs; };

  # 단일 파일에 대한 조건부 복사 실행 (새로운 모듈화 버전)
  conditionalCopyFile =
    { sourcePath
    , targetPath
    , claudeDir ? null
    , policy ? null
    , dryRun ? false
    , verbose ? true
    , forceOverwrite ? false
    }:
    let
      # 옵션 생성
      options = {
        inherit dryRun verbose forceOverwrite;
      };

      # 새로운 모듈화된 버전 사용
      result = copyEngine.copySingleFile {
        inherit sourcePath targetPath options;
      };

      # 레거시 호환성을 위한 결과 포맷 변환
      legacyResult = {
        inherit sourcePath targetPath;
        inherit dryRun verbose;

        # 기존 인터페이스 호환성
        detection = result.pipeline.detection;
        finalPolicy = result.pipeline.policy;
        actions = result.pipeline.actions;
        commands = result.executed;

        # 기존 로그 메시지 형식 유지
        logMessages = [
          "=== 조건부 파일 복사 (모듈화 버전) ==="
          "소스: ${sourcePath}"
          "타겟: ${targetPath}"
          "정책: ${result.pipeline.policy.action}"
          "사용자 수정됨: ${if result.pipeline.detection.userModified then "예" else "아니오"}"
        ] ++ (if verbose then [
          "원본 해시: ${result.pipeline.detection.details.originalHash or "null"}"
          "현재 해시: ${result.pipeline.detection.details.currentHash or "null"}"
        ] else [ ]);

        success = result.success;

        # 실행 통계 (기존 형식 유지)
        stats = {
          preserved = result.pipeline.actions.metadata.preserve or false;
          overwritten = result.pipeline.actions.metadata.overwrite or false;
          ignored = result.pipeline.actions.metadata.ignore or false;
          backupCreated = result.pipeline.actions.metadata.backup or false;
          noticeCreated = result.pipeline.actions.metadata.notice or false;
        };
      };
    in
    legacyResult;

  # 여러 파일에 대한 일괄 조건부 복사 (새로운 모듈화 버전)
  conditionalCopyDirectory =
    { sourceDir
    , targetDir
    , fileList ? null
    , dryRun ? false
    , verbose ? true
    , parallelJobs ? 1
    , forceOverwrite ? false
    }:
    let
      # 옵션 생성
      options = {
        inherit dryRun verbose forceOverwrite;
        fileList = fileList;
      };

      # 새로운 모듈화된 버전 사용
      result = copyEngine.copyDirectory {
        inherit sourceDir targetDir options;
      };

      # 레거시 호환성을 위한 결과 포맷 변환
      legacyResult = {
        inherit sourceDir targetDir dryRun verbose;
        fileList = result.discoveredFiles;

        # 기존 인터페이스 호환성 - 파일별 결과를 리스트로 변환
        fileResults = map (fileName:
          let
            fileResult = result.fileResults.${fileName};
          in
          {
            sourcePath = "${sourceDir}/${fileName}";
            targetPath = "${targetDir}/${fileName}";
            detection = fileResult.pipeline.detection;
            finalPolicy = fileResult.pipeline.policy;
            actions = fileResult.pipeline.actions;
            commands = fileResult.executed;
            success = fileResult.success;
            stats = {
              preserved = fileResult.pipeline.actions.metadata.preserve or false;
              overwritten = fileResult.pipeline.actions.metadata.overwrite or false;
              ignored = fileResult.pipeline.actions.metadata.ignore or false;
              backupCreated = fileResult.pipeline.actions.metadata.backup or false;
              noticeCreated = fileResult.pipeline.actions.metadata.notice or false;
            };
          }
        ) result.discoveredFiles;

        # 전체 통계 (기존 형식 유지)
        overallStats = {
          total = result.stats.total;
          preserved = result.stats.preserved;
          overwritten = result.stats.overwritten;
          ignored = result.stats.ignored;
          backupsCreated = result.stats.overwritten; # 근사치
          noticesCreated = result.stats.preserved; # 근사치
          errors = result.stats.failed;
        };

        # 전체 실행 명령어들
        commands = result.execution.commands;

        # 요약 리포트 (기존 형식 유지)
        summary = ''
          조건부 디렉토리 복사 완료 (모듈화 버전)
          =======================================

          소스 디렉토리: ${sourceDir}
          타겟 디렉토리: ${targetDir}
          처리된 파일: ${toString result.stats.total}개

          처리 결과:
          - 보존됨: ${toString result.stats.preserved}개
          - 덮어쓰기됨: ${toString result.stats.overwritten}개
          - 무시됨: ${toString result.stats.ignored}개
          - 오류: ${toString result.stats.failed}개

          ${if dryRun then "*** 이것은 DRY RUN입니다. 실제 파일은 변경되지 않았습니다. ***" else ""}
        '';

        # 기존 호환성을 위한 추가 필드들
        detectionResults = {
          fileResults = builtins.listToAttrs (map (fileName: {
            name = fileName;
            value = result.fileResults.${fileName}.pipeline.detection;
          }) result.discoveredFiles);
        };

        directoryPlan = {
          filePolicies = builtins.listToAttrs (map (fileName: {
            name = fileName;
            value = result.fileResults.${fileName}.pipeline.policy;
          }) result.discoveredFiles);
        };
      };
    in
    legacyResult;

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
            echo "  파일 동일하지만 강제 덮어쓰기"
            ${if includeLogging then ''log_action "FORCE_OVERWRITE" "$target_file"'' else ""}
            cp "$source_file" "$target_file"
            chmod 644 "$target_file"
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

  # Claude 설정 전용 고수준 인터페이스 (간소화된 버전)
  updateClaudeConfig =
    { claudeDir ? "$HOME/.claude"
    , sourceConfigPath ? null
    , dryRun ? false
    , verbose ? true
    , createBackups ? true
    , notifyUser ? true
    , forceOverwrite ? false
    }:
    let
      # 기본 소스 경로 설정
      actualSourcePath =
        if sourceConfigPath != null then sourceConfigPath
        else ./../../modules/shared/config/claude;

      # 새로운 모듈화된 시스템 사용
      result = conditionalCopyDirectory {
        sourceDir = actualSourcePath;
        targetDir = claudeDir;
        inherit dryRun verbose forceOverwrite;
      };

      # 후처리 명령어들 (간소화)
      postProcessCommands = []
        ++ lib.optionals createBackups [
          "find \"${claudeDir}\" -name \"*.backup.*\" -mtime +30 -delete 2>/dev/null || true"
        ]
        ++ lib.optionals (notifyUser && !dryRun) [
          "echo \"Claude 설정 업데이트 완료: ${toString result.overallStats.total}개 파일 처리\""
          "echo \"보존: ${toString result.overallStats.preserved}, 덮어쓰기: ${toString result.overallStats.overwritten}\""
        ];

      enhancedResult = result // {
        # 최종 실행 스크립트
        finalScript = result.commands ++ postProcessCommands;

        # 추가 메타데이터
        metadata = {
          claudeConfigUpdate = true;
          postProcessingEnabled = createBackups || notifyUser;
        };
      };
    in
    enhancedResult;

in
{
  # 주요 공개 API (레거시 호환성 유지)
  inherit conditionalCopyFile conditionalCopyDirectory;
  inherit generateConditionalCopyScript updateClaudeConfig;

  # 새로운 모듈화된 API
  modules = {
    # 개별 모듈 직접 접근
    inherit changeDetector policyResolver copyEngine;
  };

  # 레거시 호환성 모듈들 (별도 분리)
  legacy = {
    # 기존 라이브러리들 (하위 호환성 유지)
    inherit policyLib detectorLib;

    # 레거시 API 지원
    version = "1.x-compat";
    deprecated = true;
    migrationGuide = "Use modules.changeDetector and modules.policyResolver instead";
  };

  # 편의 함수들 (새로운 모듈 기반)
  advanced = {
    # 정책 기반 단일 파일 복사
    copyWithPolicy = sourcePath: targetPath: policy: options:
      copyEngine.copySingleFile {
        inherit sourcePath targetPath options;
      };

    # 변경 감지만 수행
    detectOnly = sourcePath: targetPath:
      changeDetector.detectFileChanges sourcePath targetPath;

    # 정책 결정만 수행
    policyOnly = filePath: userModified: options:
      policyResolver.resolveCopyPolicy filePath { inherit userModified; } options;
  };

  # 유틸리티 함수들 (간소화)
  utils = {
    # 간단한 파일 복사 (새로운 엔진 사용)
    simpleCopy = sourcePath: targetPath: options:
      copyEngine.utils.simpleCopy sourcePath targetPath options;

    # 백업 생성 (새로운 엔진 사용)
    createBackup = filePath: options:
      copyEngine.createBackup filePath options;

    # 파일 변경 감지 (새로운 감지기 사용)
    detectChanges = sourcePath: targetPath:
      changeDetector.detectFileChanges sourcePath targetPath;

    # 정책 유틸리티
    policyUtils = policyResolver.policyUtils;
  };

  # 상수들
  constants = {
    defaultFilePermissions = "644";
    backupSuffix = "backup";
    newFileSuffix = "new";
    noticeSuffix = "update-notice";
    maxBackupAge = 30; # days

    # 새로운 모듈 관련 상수
    moduleVersion = "2.0-modular";
    supportedPolicies = [ "preserve" "overwrite" "ignore" "merge" ];
  };

  # 테스트 지원 (향상된 버전)
  test = {
    # 레거시 테스트 지원
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

    # 새로운 모듈 테스트 지원
    testModules = {
      changeDetector = changeDetector.test or {};
      policyResolver = policyResolver.test or {};
      copyEngine = copyEngine.test or {};
    };

    # 통합 테스트 시나리오
    fullPipelineTest = {
      sourcePath = "/tmp/test-source/test.json";
      targetPath = "/tmp/test-target/test.json";
      options = { dryRun = true; verbose = true; };
      expected = "모든 모듈이 정상적으로 통합되어 작동";
    };
  };

  # 메타 정보
  meta = {
    version = "2.0-modular";
    description = "Modularized conditional file copy system";
    modules = [ "change-detector" "policy-resolver" "copy-engine" ];
    compatibility = "Full backward compatibility with v1.x API";
    performance = "Improved modularity and maintainability";
  };
}
