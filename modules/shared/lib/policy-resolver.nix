{ lib, pkgs }:

let
  # Import change detector for dependency
  changeDetector = import ./change-detector.nix { inherit lib pkgs; };

  # Policy definitions
  preservationPolicies = {
    # Preserve user version, save new version with .new suffix
    preserve = {
      action = "preserve";
      backup = false;
      createNotice = true;
      description = "Preserve user version, save new version as .new";
    };

    # Overwrite with backup
    overwrite = {
      action = "overwrite";
      backup = true;
      createNotice = false;
      description = "Overwrite with backup";
    };

    # Ignore - no action taken
    ignore = {
      action = "ignore";
      backup = false;
      createNotice = false;
      description = "No action taken";
    };

    # Force overwrite without backup
    forceOverwrite = {
      action = "force-overwrite";
      backup = false;
      createNotice = false;
      description = "Force overwrite without backup";
    };
  };

  # File classification rules
  fileClassification = {
    # High priority files (preserve user changes)
    highPriority = [ "settings.json" "CLAUDE.md" "CLAUDE.local.md" ];

    # Medium priority files (overwrite with backup)
    mediumPriority = [ "commands/*.md" "docs/*.md" ];

    # Low priority files (can be overwritten)
    lowPriority = [ "templates/*" "examples/*" ];

    # System files (usually overwrite)
    systemFiles = [ "*.nix" "*.sh" "*.py" ];
  };

  # Classify a file based on its path
  classifyFile = filePath:
    let
      fileName = builtins.baseNameOf filePath;

      # Check against high priority patterns
      isHighPriority = builtins.any (pattern:
        if lib.hasInfix "*" pattern then
          lib.hasInfix (lib.removeSuffix "*" pattern) filePath
        else
          pattern == fileName
      ) fileClassification.highPriority;

      # Check against medium priority patterns
      isMediumPriority = builtins.any (pattern:
        if lib.hasInfix "*" pattern then
          lib.hasInfix (lib.removeSuffix "*" pattern) filePath
        else
          pattern == fileName
      ) fileClassification.mediumPriority;

      # Check against system files
      isSystemFile = builtins.any (pattern:
        if lib.hasInfix "*" pattern then
          lib.hasSuffix (lib.removePrefix "*" pattern) fileName
        else
          pattern == fileName
      ) fileClassification.systemFiles;

    in
    if isHighPriority then "high"
    else if isMediumPriority then "medium"
    else if isSystemFile then "system"
    else "low";

in

{
  # Resolve copy policy for a single file
  resolveCopyPolicy = filePath: detection: options:
    let
      classification = classifyFile filePath;
      forceOverwrite = options.forceOverwrite or false;

      # Policy selection logic
      selectedPolicy =
        if forceOverwrite then
          preservationPolicies.forceOverwrite
        else if detection.changeType == "new-file" then
          preservationPolicies.overwrite
        else if detection.changeType == "no-change" then
          preservationPolicies.ignore
        else if detection.userModified then
          # User has modified the file
          if classification == "high" then
            preservationPolicies.preserve
          else if classification == "medium" then
            preservationPolicies.overwrite
          else
            preservationPolicies.overwrite
        else
          # No user modifications detected
          preservationPolicies.overwrite;

    in
    selectedPolicy // {
      classification = classification;
      reasoning = "File classified as ${classification} priority, user modified: ${builtins.toString detection.userModified}";
    };

  # Generate a comprehensive copy plan for multiple files
  generateCopyPlan = targetDir: sourceDir: detectionResults: options:
    let
      # Generate policy for each file
      filePolicies = builtins.mapAttrs (fileName: detection:
        resolveCopyPolicy "${targetDir}/${fileName}" detection options
      ) detectionResults.fileResults;

      # Calculate plan statistics
      stats = {
        total = builtins.length (builtins.attrNames filePolicies);
        preserve = builtins.length (lib.filter (policy: policy.action == "preserve") (builtins.attrValues filePolicies));
        overwrite = builtins.length (lib.filter (policy: policy.action == "overwrite") (builtins.attrValues filePolicies));
        ignore = builtins.length (lib.filter (policy: policy.action == "ignore") (builtins.attrValues filePolicies));
        forceOverwrite = builtins.length (lib.filter (policy: policy.action == "force-overwrite") (builtins.attrValues filePolicies));
      };

    in
    {
      inherit targetDir sourceDir filePolicies stats;

      # Generate summary report
      summary = ''
        Copy Plan Summary
        =================
        Source: ${sourceDir}
        Target: ${targetDir}

        Actions planned:
        - Preserve: ${toString stats.preserve} files
        - Overwrite: ${toString stats.overwrite} files
        - Ignore: ${toString stats.ignore} files
        - Force overwrite: ${toString stats.forceOverwrite} files

        Total files: ${toString stats.total}
      '';
    };

  # Evaluate user modifications and determine appropriate response
  evaluateUserModifications = filePath: detection:
    let
      hasUserChanges = detection.userModified;
      changeType = detection.changeType;

      # Determine modification severity
      severity =
        if changeType == "new-file" then "none"
        else if changeType == "no-change" then "none"
        else if hasUserChanges then "significant"
        else "minor";

      # Generate recommendations
      recommendations =
        if severity == "none" then
          [ "No user modifications detected - safe to overwrite" ]
        else if severity == "minor" then
          [ "Minor changes detected - consider overwriting with backup" ]
        else if severity == "significant" then
          [ "Significant user modifications detected"
            "Consider preserving user version"
            "Review changes before overwriting"
          ]
        else
          [ "Unable to determine modification severity" ];

    in
    {
      inherit filePath detection hasUserChanges changeType severity recommendations;

      # Decision matrix
      suggestedAction =
        if severity == "none" then "overwrite"
        else if severity == "minor" then "overwrite-with-backup"
        else if severity == "significant" then "preserve"
        else "manual-review";
    };

  # Create specific actions based on policy decisions
  createPolicyActions = targetPath: sourcePath: detection: options:
    let
      policy = resolveCopyPolicy targetPath detection options;
      timestamp = "$(date +%Y%m%d_%H%M%S)";

      # Generate shell commands based on policy
      commands =
        if policy.action == "preserve" then
          [
            "cp \"${sourcePath}\" \"${targetPath}.new\""
            "chmod 644 \"${targetPath}.new\""
          ] ++ (if policy.createNotice then [
            "cat > \"${targetPath}.update-notice\" << 'EOF'"
            "파일 업데이트 알림: ${builtins.baseNameOf targetPath}"
            ""
            "이 파일이 업데이트되었지만 사용자 수정이 감지되어 기존 파일을 보존했습니다."
            ""
            "- 현재 파일: ${targetPath} (사용자 수정 버전)"
            "- 새 버전: ${targetPath}.new (dotfiles 최신 버전)"
            ""
            "변경사항을 확인하세요: diff \"${targetPath}\" \"${targetPath}.new\""
            ""
            "확인 후 이 알림을 삭제하세요: rm \"${targetPath}.update-notice\""
            "EOF"
          ] else [])
        else if policy.action == "overwrite" then
          (if policy.backup then [
            "cp \"${targetPath}\" \"${targetPath}.backup.${timestamp}\""
          ] else []) ++ [
            "cp \"${sourcePath}\" \"${targetPath}\""
            "chmod 644 \"${targetPath}\""
          ]
        else if policy.action == "force-overwrite" then
          [
            "cp \"${sourcePath}\" \"${targetPath}\""
            "chmod 644 \"${targetPath}\""
          ]
        else if policy.action == "ignore" then
          [
            "echo \"Ignoring ${targetPath} (no changes needed)\""
          ]
        else
          [
            "echo \"Unknown action: ${policy.action} for ${targetPath}\""
            "exit 1"
          ];

    in
    {
      inherit targetPath sourcePath policy commands;

      # Action metadata
      metadata = {
        preserve = policy.action == "preserve";
        overwrite = builtins.elem policy.action [ "overwrite" "force-overwrite" ];
        ignore = policy.action == "ignore";
        backup = policy.backup;
        notice = policy.createNotice;
      };
    };

  # Utility functions for policy management
  utils = {
    # Get all available policies
    getAllPolicies = builtins.attrNames preservationPolicies;

    # Get policy by name
    getPolicyByName = name: preservationPolicies.${name} or null;

    # Get all config files (default file list)
    getAllConfigFiles = [
      "settings.json"
      "CLAUDE.md"
      "CLAUDE.local.md"
      "commands/custom.md"
      "docs/usage.md"
    ];

    # Validate policy configuration
    validatePolicy = policy:
      let
        requiredFields = [ "action" "backup" "createNotice" "description" ];
        hasAllFields = builtins.all (field:
          builtins.hasAttr field policy
        ) requiredFields;
      in
      hasAllFields && builtins.elem policy.action [ "preserve" "overwrite" "ignore" "force-overwrite" ];
  };

  # Legacy compatibility functions
  inherit preservationPolicies;

  # Map old function names to new ones
  getPolicyForFile = filePath: detection: options: resolveCopyPolicy filePath detection options;
  generateActions = targetPath: sourcePath: detection: options: createPolicyActions targetPath sourcePath detection options;
  generateDirectoryPlan = targetDir: sourceDir: detectionResults: options: generateCopyPlan targetDir sourceDir detectionResults options;
}
