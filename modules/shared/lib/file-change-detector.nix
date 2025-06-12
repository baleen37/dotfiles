# ABOUTME: 파일 변경 감지 및 해시 비교를 위한 순수 함수들
# ABOUTME: 사용자 수정 여부를 판단하고 파일 변경 히스토리를 추적

{ lib, pkgs }:

let
  # 파일 해시 계산 함수
  calculateFileHash = filePath:
    if builtins.pathExists filePath then
      builtins.hashFile "sha256" filePath
    else
      null;

  # 문자열 콘텐츠의 해시 계산
  calculateContentHash = content:
    builtins.hashString "sha256" content;

  # 파일 메타데이터 수집
  getFileMetadata = filePath: {
    path = filePath;
    exists = builtins.pathExists filePath;
    hash = calculateFileHash filePath;
    size = if builtins.pathExists filePath then 
      builtins.toString (builtins.stringLength (builtins.readFile filePath))
    else null;
    timestamp = "$(stat -c %Y \"${filePath}\" 2>/dev/null || echo 0)";
  };

  # 원본 파일과 현재 파일 비교
  compareFiles = originalFilePath: currentFilePath:
    let
      originalMeta = getFileMetadata originalFilePath;
      currentMeta = getFileMetadata currentFilePath;
      
      # 둘 다 존재하는 경우만 비교 가능
      bothExist = originalMeta.exists && currentMeta.exists;
      
      # 해시가 다르면 수정됨
      hashDifferent = bothExist && (originalMeta.hash != currentMeta.hash);
      
      # 크기가 다르면 수정됨 (해시 계산이 실패한 경우 대비)
      sizeDifferent = bothExist && (originalMeta.size != currentMeta.size);
      
      result = {
        original = originalMeta;
        current = currentMeta;
        bothExist = bothExist;
        userModified = hashDifferent || sizeDifferent;
        identical = bothExist && (originalMeta.hash == currentMeta.hash);
        
        # 상세 정보
        details = {
          hashChanged = hashDifferent;
          sizeChanged = sizeDifferent;
          originalHash = originalMeta.hash;
          currentHash = currentMeta.hash;
          originalSize = originalMeta.size;
          currentSize = currentMeta.size;
        };
      };
    in
    result;

  # 여러 파일들의 변경 상태를 일괄 감지
  detectChangesInDirectory = sourceDir: targetDir: fileList:
    let
      # 각 파일에 대해 변경 감지 수행
      fileResults = lib.listToAttrs (map (fileName:
        let
          sourcePath = "${sourceDir}/${fileName}";
          targetPath = "${targetDir}/${fileName}";
          comparison = compareFiles sourcePath targetPath;
        in {
          name = fileName;
          value = comparison // {
            fileName = fileName;
            sourcePath = sourcePath;
            targetPath = targetPath;
          };
        }
      ) fileList);
      
      # 통계 계산
      allFiles = lib.attrValues fileResults;
      modifiedFiles = lib.filter (result: result.userModified) allFiles;
      identicalFiles = lib.filter (result: result.identical) allFiles;
      missingFiles = lib.filter (result: !result.current.exists) allFiles;
      
      summary = {
        total = lib.length allFiles;
        modified = lib.length modifiedFiles;
        identical = lib.length identicalFiles;
        missing = lib.length missingFiles;
        modificationRate = 
          if summary.total > 0 then
            (summary.modified * 100) / summary.total
          else 0;
      };
    in {
      inherit fileResults summary;
      modifiedFiles = modifiedFiles;
      identicalFiles = identicalFiles;
      missingFiles = missingFiles;
    };

  # Claude 설정 디렉토리의 변경 감지 (특화 함수)
  detectClaudeConfigChanges = claudeDir: sourceConfigDir:
    let
      # Claude 설정 파일 목록
      claudeConfigFiles = [
        "settings.json"
        "CLAUDE.md"
      ];
      
      # commands 디렉토리의 파일들도 포함
      commandsDir = "${claudeDir}/commands";
      sourceCommandsDir = "${sourceConfigDir}/commands";
      
      # commands 디렉토리의 파일 목록 (동적으로 탐지)
      commandFiles = 
        if builtins.pathExists commandsDir then
          let
            entries = builtins.readDir commandsDir;
            mdFiles = lib.filter (name: 
              lib.hasSuffix ".md" name && entries.${name} == "regular"
            ) (lib.attrNames entries);
          in map (name: "commands/${name}") mdFiles
        else [];
      
      allFiles = claudeConfigFiles ++ commandFiles;
      
      # 변경 감지 실행
      detection = detectChangesInDirectory sourceConfigDir claudeDir allFiles;
      
      # Claude 특화 분석 추가
      claudeSpecific = {
        settingsModified = 
          if detection.fileResults ? "settings.json" then
            detection.fileResults."settings.json".userModified
          else false;
            
        claudeMdModified = 
          if detection.fileResults ? "CLAUDE.md" then
            detection.fileResults."CLAUDE.md".userModified
          else false;
            
        customCommands = lib.filter (fileName:
          let
            sourcePath = "${sourceCommandsDir}/${lib.removePrefix "commands/" fileName}";
          in
          lib.hasPrefix "commands/" fileName && 
          !builtins.pathExists sourcePath
        ) allFiles;
        
        modifiedCommands = lib.filter (fileName:
          lib.hasPrefix "commands/" fileName &&
          detection.fileResults.${fileName}.userModified or false
        ) allFiles;
      };
    in
    detection // { inherit claudeSpecific; };

  # 변경 감지 결과를 사람이 읽기 쉬운 형태로 포맷
  formatDetectionReport = detection:
    let
      summary = detection.summary;
      files = detection.fileResults;
      
      formatFileStatus = fileName: result:
        let
          status = if result.userModified then "수정됨"
                  else if result.identical then "동일함"
                  else if !result.current.exists then "없음"
                  else "알 수 없음";
          hash = if result.current.hash != null then
            "(${lib.substring 0 8 result.current.hash}...)"
          else "";
        in
        "  ${fileName}: ${status} ${hash}";
        
      fileLines = lib.mapAttrsToList formatFileStatus files;
      
      report = ''
        파일 변경 감지 결과:
        ================
        
        요약:
        - 전체 파일: ${toString summary.total}개
        - 수정된 파일: ${toString summary.modified}개
        - 동일한 파일: ${toString summary.identical}개
        - 없는 파일: ${toString summary.missing}개
        - 수정률: ${toString (lib.round summary.modificationRate)}%
        
        파일별 상태:
        ${lib.concatStringsSep "\n" fileLines}
        
        ${if detection ? claudeSpecific then ''
        Claude 설정 분석:
        - settings.json 수정됨: ${if detection.claudeSpecific.settingsModified then "예" else "아니오"}
        - CLAUDE.md 수정됨: ${if detection.claudeSpecific.claudeMdModified then "예" else "아니오"}
        - 사용자 커스텀 명령어: ${toString (lib.length detection.claudeSpecific.customCommands)}개
        - 수정된 명령어: ${toString (lib.length detection.claudeSpecific.modifiedCommands)}개
        '' else ""}
      '';
    in
    report;

  # 쉘 스크립트용 변경 감지 함수
  generateShellDetectionScript = claudeDir: sourceDir: outputFile: ''
    #!/bin/bash
    # 파일 변경 감지 스크립트
    
    CLAUDE_DIR="${claudeDir}"
    SOURCE_DIR="${sourceDir}"
    OUTPUT_FILE="${outputFile}"
    
    echo "파일 변경 감지 시작..."
    echo "Claude 디렉토리: $CLAUDE_DIR"
    echo "소스 디렉토리: $SOURCE_DIR"
    
    # JSON 형태로 결과 저장
    cat > "$OUTPUT_FILE" << 'EOF'
    {
      "timestamp": "$(date -Iseconds)",
      "claudeDir": "${claudeDir}",
      "sourceDir": "${sourceDir}",
      "files": {
    EOF
    
    # 각 파일에 대해 해시 비교
    FIRST_FILE=true
    for config_file in "settings.json" "CLAUDE.md"; do
      if [ "$FIRST_FILE" = false ]; then
        echo "," >> "$OUTPUT_FILE"
      fi
      FIRST_FILE=false
      
      SOURCE_FILE="$SOURCE_DIR/$config_file"
      TARGET_FILE="$CLAUDE_DIR/$config_file"
      
      if [ -f "$SOURCE_FILE" ] && [ -f "$TARGET_FILE" ]; then
        SOURCE_HASH=$(sha256sum "$SOURCE_FILE" | cut -d' ' -f1)
        TARGET_HASH=$(sha256sum "$TARGET_FILE" | cut -d' ' -f1)
        USER_MODIFIED=$([ "$SOURCE_HASH" != "$TARGET_HASH" ] && echo "true" || echo "false")
      else
        SOURCE_HASH="null"
        TARGET_HASH="null"
        USER_MODIFIED="false"
      fi
      
      cat >> "$OUTPUT_FILE" << EOF
        "$config_file": {
          "sourceHash": "$SOURCE_HASH",
          "targetHash": "$TARGET_HASH",
          "userModified": $USER_MODIFIED,
          "sourceExists": $([ -f "$SOURCE_FILE" ] && echo "true" || echo "false"),
          "targetExists": $([ -f "$TARGET_FILE" ] && echo "true" || echo "false")
        }
    EOF
    done
    
    cat >> "$OUTPUT_FILE" << 'EOF'
      }
    }
    EOF
    
    echo "변경 감지 완료: $OUTPUT_FILE"
  '';

  # 테스트를 위한 목 데이터 생성
  createMockDetection = {
    fileName ? "test.json",
    userModified ? false,
    originalHash ? "abc123",
    currentHash ? if userModified then "def456" else "abc123",
    originalSize ? "100",
    currentSize ? if userModified then "150" else "100"
  }: {
    inherit fileName userModified;
    original = {
      path = "/mock/source/${fileName}";
      exists = true;
      hash = originalHash;
      size = originalSize;
    };
    current = {
      path = "/mock/target/${fileName}";
      exists = true;
      hash = currentHash;
      size = currentSize;
    };
    bothExist = true;
    identical = !userModified;
    details = {
      hashChanged = userModified;
      sizeChanged = userModified;
      inherit originalHash currentHash originalSize currentSize;
    };
  };

in {
  # 공개 API
  inherit calculateFileHash calculateContentHash getFileMetadata;
  inherit compareFiles detectChangesInDirectory detectClaudeConfigChanges;
  inherit formatDetectionReport generateShellDetectionScript;
  inherit createMockDetection;
  
  # 유틸리티 함수들
  utils = {
    # 빠른 파일 비교 (해시만 확인)
    quickCompare = file1: file2: 
      (calculateFileHash file1) == (calculateFileHash file2);
    
    # 파일 존재 여부 확인
    fileExists = builtins.pathExists;
    
    # 해시 짧은 형태로 변환
    shortHash = hash: 
      if hash != null then
        lib.substring 0 8 hash
      else "null";
    
    # 변경률 계산
    calculateChangeRate = modified: total:
      if total > 0 then (modified * 100.0) / total else 0.0;
  };
  
  # 상수들
  constants = {
    supportedHashAlgorithms = [ "sha256" "sha1" "md5" ];
    defaultHashAlgorithm = "sha256";
    maxFileSize = 1048576; # 1MB
  };
  
  # 디버깅 지원
  debug = {
    inherit createMockDetection;
    
    testDetection = {
      claudeDir = "/mock/claude";
      sourceDir = "/mock/source";
      fileList = [ "settings.json" "CLAUDE.md" "commands/test.md" ];
    };
    
    # 테스트용 가짜 결과 생성
    mockResults = {
      allIdentical = {
        summary = { total = 3; modified = 0; identical = 3; missing = 0; };
        fileResults = {
          "settings.json" = createMockDetection { fileName = "settings.json"; };
          "CLAUDE.md" = createMockDetection { fileName = "CLAUDE.md"; };
          "commands/test.md" = createMockDetection { fileName = "commands/test.md"; };
        };
      };
      
      someModified = {
        summary = { total = 3; modified = 2; identical = 1; missing = 0; };
        fileResults = {
          "settings.json" = createMockDetection { fileName = "settings.json"; userModified = true; };
          "CLAUDE.md" = createMockDetection { fileName = "CLAUDE.md"; userModified = true; };
          "commands/test.md" = createMockDetection { fileName = "commands/test.md"; };
        };
      };
    };
  };
}