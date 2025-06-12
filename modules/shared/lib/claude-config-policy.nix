# ABOUTME: Claude 설정 파일 보존 정책을 정의하는 라이브러리
# ABOUTME: 사용자 수정 감지, 보존/덮어쓰기 규칙, 백업 정책 등을 관리

{ lib, pkgs }:

let
  # Claude 설정 파일들의 기본 정보
  claudeConfigFiles = {
    "settings.json" = {
      path = "settings.json";
      source = "modules/shared/config/claude/settings.json";
      priority = "high";  # 사용자 수정 시 반드시 보존
      backup = true;
      notifyUser = true;
    };

    "CLAUDE.md" = {
      path = "CLAUDE.md";
      source = "modules/shared/config/claude/CLAUDE.md";
      priority = "high";  # 사용자 수정 시 반드시 보존
      backup = true;
      notifyUser = true;
    };

    "commands" = {
      path = "commands";
      source = "modules/shared/config/claude/commands";
      priority = "medium";  # 일부 파일은 덮어쓰기 허용
      backup = true;
      notifyUser = true;
      isDirectory = true;
    };
  };

  # 보존 정책 종류
  preservationPolicies = {
    # 사용자 수정 내용을 항상 보존
    preserve = {
      action = "preserve";
      description = "사용자 수정 내용을 보존하고 새 버전을 .new 파일로 저장";
      createNewFile = true;
      createNotice = true;
      backup = true;
    };

    # 덮어쓰기하되 백업 생성
    overwrite = {
      action = "overwrite";
      description = "새 버전으로 덮어쓰기하고 기존 파일을 백업";
      createNewFile = false;
      createNotice = false;
      backup = true;
    };

    # 아무것도 하지 않음 (사용자 파일 그대로 유지)
    ignore = {
      action = "ignore";
      description = "사용자 파일을 그대로 유지하고 아무것도 하지 않음";
      createNewFile = false;
      createNotice = false;
      backup = false;
    };
  };

  # 파일 우선순위에 따른 정책 결정
  getPolicyForFile = filePath: userModified:
    let
      fileName = baseNameOf filePath;
      fileConfig = claudeConfigFiles.${fileName} or null;

      # 설정에 정의되지 않은 파일은 사용자 커스텀 파일로 간주
      isCustomFile = fileConfig == null;

      # 사용자 커스텀 파일은 항상 보존
      policy = if isCustomFile then
        preservationPolicies.ignore
      else if userModified then
        # 사용자가 수정한 경우
        if fileConfig.priority == "high" then
          preservationPolicies.preserve
        else
          preservationPolicies.overwrite
      else
        # 사용자가 수정하지 않은 경우 - 새 버전으로 업데이트
        preservationPolicies.overwrite;
    in
    policy // {
      fileConfig = fileConfig;
      isCustomFile = isCustomFile;
      userModified = userModified;
    };

  # 알림 메시지 생성
  generateNoticeMessage = filePath: policy: newFilePath: ''
    파일 업데이트 알림: ${baseNameOf filePath}

    ${policy.description}

    파일 위치:
    - 현재 파일: ${filePath} (사용자 수정 버전)
    ${if policy.createNewFile then "- 새 버전: ${newFilePath} (dotfiles 최신 버전)" else ""}

    ${if policy.createNewFile then ''
    변경 사항을 확인하고 수동으로 병합하세요:
      diff "${filePath}" "${newFilePath}"

    또는 수동 병합 도구를 사용하세요:
      nix run .#merge-claude-config
    '' else ""}

    이 알림을 확인한 후 삭제하세요:
      rm "${filePath}.update-notice"

    생성 시간: $(date)
  '';

  # 백업 파일 경로 생성
  generateBackupPath = filePath:
    let
      timestamp = "$(date +%Y%m%d_%H%M%S)";
    in
    "${filePath}.backup.${timestamp}";

  # 파일 변경 감지 결과에 따른 처리 액션 생성
  generateActions = filePath: sourceFilePath: changeDetection:
    let
      policy = getPolicyForFile filePath changeDetection.userModified;
      newFilePath = "${filePath}.new";
      noticePath = "${filePath}.update-notice";
      backupPath = generateBackupPath filePath;

      actions = {
        # 기본 정보
        inherit filePath sourceFilePath policy;

        # 실행할 액션들
        preserve = policy.action == "preserve";
        overwrite = policy.action == "overwrite";
        ignore = policy.action == "ignore";

        # 파일 경로들
        inherit newFilePath noticePath backupPath;

        # 생성할 콘텐츠
        noticeContent = if policy.createNotice then
          generateNoticeMessage filePath policy newFilePath
        else null;

        # 실행할 쉘 명령어들
        commands = generateShellCommands filePath sourceFilePath policy newFilePath noticePath backupPath;
      };
    in
    actions;

  # 쉘 명령어 생성
  generateShellCommands = filePath: sourceFilePath: policy: newFilePath: noticePath: backupPath:
    let
      baseCommands = [
        "echo \"Processing ${filePath} with policy: ${policy.action}\""
      ];

      preserveCommands = if policy.action == "preserve" then [
        # 새 버전을 .new 파일로 저장
        "cp \"${sourceFilePath}\" \"${newFilePath}\""
        "chmod 644 \"${newFilePath}\""
        "echo \"New version saved as ${newFilePath}\""
      ] else [];

      overwriteCommands = if policy.action == "overwrite" then [
        # 백업 생성
        (if policy.backup then "cp \"${filePath}\" \"${backupPath}\"" else "")
        # 새 버전으로 덮어쓰기
        "cp \"${sourceFilePath}\" \"${filePath}\""
        "chmod 644 \"${filePath}\""
        "echo \"File ${filePath} updated\""
      ] else [];

      noticeCommands = if policy.createNotice then [
        "cat > \"${noticePath}\" << 'EOF'"
        (generateNoticeMessage filePath policy newFilePath)
        "EOF"
        "echo \"Notice created: ${noticePath}\""
      ] else [];

      # 빈 문자열 제거
      allCommands = lib.filter (cmd: cmd != "") (
        baseCommands ++ preserveCommands ++ overwriteCommands ++ noticeCommands
      );
    in
    allCommands;

  # 디렉토리 전체에 대한 처리 계획 생성
  generateDirectoryPlan = claudeDir: sourceDir: changeDetections:
    let
      # 각 파일에 대한 액션 생성
      fileActions = lib.mapAttrsToList (fileName: detection:
        let
          filePath = "${claudeDir}/${fileName}";
          sourceFilePath = "${sourceDir}/${fileName}";
        in
        generateActions filePath sourceFilePath detection
      ) changeDetections;

      # 액션들을 타입별로 분류
      preserveActions = lib.filter (action: action.preserve) fileActions;
      overwriteActions = lib.filter (action: action.overwrite) fileActions;
      ignoreActions = lib.filter (action: action.ignore) fileActions;

      # 전체 실행 계획
      plan = {
        inherit fileActions preserveActions overwriteActions ignoreActions;

        # 요약 정보
        summary = {
          total = lib.length fileActions;
          preserved = lib.length preserveActions;
          overwritten = lib.length overwriteActions;
          ignored = lib.length ignoreActions;
        };

        # 전체 쉘 스크립트 생성
        shellScript = lib.concatMapStringsSep "\n" (action:
          lib.concatStringsSep "\n" action.commands
        ) fileActions;
      };
    in
    plan;

  # 설정 검증 함수
  validateConfig = config:
    let
      requiredFields = [ "path" "source" "priority" ];
      hasRequired = lib.all (field: config ? ${field}) requiredFields;
      validPriority = lib.elem config.priority [ "high" "medium" "low" ];
    in
    hasRequired && validPriority;

  # 정책 테스트용 목 데이터 생성
  mockChangeDetection = userModified: originalHash: currentHash: {
    inherit userModified originalHash currentHash;
    changed = userModified;
    timestamp = "2024-01-01T00:00:00Z";
  };

in {
  # 공개 API
  inherit claudeConfigFiles preservationPolicies;
  inherit getPolicyForFile generateActions generateDirectoryPlan;
  inherit generateNoticeMessage generateBackupPath validateConfig;
  inherit mockChangeDetection;

  # 유틸리티 함수들
  utils = {
    inherit generateShellCommands;

    # 파일 이름에서 설정 정보 조회
    getFileConfig = fileName: claudeConfigFiles.${fileName} or null;

    # 모든 설정 파일 목록 반환
    getAllConfigFiles = lib.attrNames claudeConfigFiles;

    # 우선순위별 파일 목록
    getFilesByPriority = priority:
      lib.filter (name:
        (claudeConfigFiles.${name}).priority == priority
      ) (lib.attrNames claudeConfigFiles);
  };

  # 디버깅 및 테스트 지원
  debug = {
    inherit claudeConfigFiles preservationPolicies;
    showPolicy = filePath: userModified:
      getPolicyForFile filePath userModified;
    testPlan = claudeDir: sourceDir: mockDetections:
      generateDirectoryPlan claudeDir sourceDir mockDetections;
  };
}
