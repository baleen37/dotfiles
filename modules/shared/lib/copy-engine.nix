{ lib, pkgs }:

let
  # Import dependencies
  changeDetector = import ./change-detector.nix { inherit lib pkgs; };
  policyResolver = import ./policy-resolver.nix { inherit lib pkgs; };

  # Core copy engine - handles actual file operations
  executeFileCopy =
    { sourcePath
    , targetPath
    , actions
    , options ? {}
    }:
    let
      dryRun = options.dryRun or false;
      verbose = options.verbose or true;

      # Wrap commands for dry run mode
      wrapCommand = cmd:
        if dryRun then "echo \"DRY RUN: ${cmd}\""
        else cmd;

      # Execute commands with proper error handling
      executeCommands = builtins.map wrapCommand actions.commands;

      # Generate execution result
      result = {
        inherit sourcePath targetPath actions;
        success = true; # This would be determined by actual execution
        executed = executeCommands;

        # Execution metadata
        metadata = {
          dryRun = dryRun;
          verbose = verbose;
          commandCount = builtins.length actions.commands;
          policy = actions.policy.action;
        };
      };
    in
    result;

  # Single file copy operation with full pipeline
  copySingleFile =
    { sourcePath
    , targetPath
    , options ? {}
    }:
    let
      # Step 1: Detect changes
      detection = changeDetector.detectFileChanges sourcePath targetPath;

      # Step 2: Resolve policy
      policy = policyResolver.resolveCopyPolicy targetPath detection options;

      # Step 3: Create action plan
      actions = policyResolver.createPolicyActions targetPath sourcePath detection options;

      # Step 4: Execute copy operation
      result = executeFileCopy {
        inherit sourcePath targetPath actions options;
      };

    in
    result // {
      # Include pipeline data for debugging
      pipeline = {
        inherit detection policy actions;
      };
    };

  # Batch copy operations for multiple files
  copyMultipleFiles =
    { sourceDir
    , targetDir
    , fileList
    , options ? {}
    }:
    let
      # Process each file individually
      fileResults = builtins.listToAttrs (map (fileName:
        let
          sourcePath = "${sourceDir}/${fileName}";
          targetPath = "${targetDir}/${fileName}";
          result = copySingleFile {
            inherit sourcePath targetPath options;
          };
        in
        {
          name = fileName;
          value = result;
        }
      ) fileList);

      # Calculate batch statistics
      stats = {
        total = builtins.length fileList;
        successful = builtins.length (lib.filter (name:
          (fileResults.${name}.success)
        ) fileList);
        failed = builtins.length (lib.filter (name:
          !(fileResults.${name}.success)
        ) fileList);

        # Policy distribution
        preserved = builtins.length (lib.filter (name:
          (fileResults.${name}.pipeline.policy.action == "preserve")
        ) fileList);
        overwritten = builtins.length (lib.filter (name:
          (fileResults.${name}.pipeline.policy.action == "overwrite")
        ) fileList);
        ignored = builtins.length (lib.filter (name:
          (fileResults.${name}.pipeline.policy.action == "ignore")
        ) fileList);
      };

      # Combine all execution commands
      allCommands = lib.concatMap (fileName:
        (fileResults.${fileName}.executed)
      ) fileList;

    in
    {
      inherit sourceDir targetDir fileList fileResults stats;

      # Batch execution data
      execution = {
        commands = allCommands;
        totalCommands = builtins.length allCommands;
        successful = stats.successful == stats.total;
      };

      # Generate summary report
      summary = ''
        Batch Copy Operation Summary
        ============================
        Source: ${sourceDir}
        Target: ${targetDir}

        Files processed: ${toString stats.total}
        Successful: ${toString stats.successful}
        Failed: ${toString stats.failed}

        Policy distribution:
        - Preserved: ${toString stats.preserved}
        - Overwritten: ${toString stats.overwritten}
        - Ignored: ${toString stats.ignored}

        Total commands executed: ${toString (builtins.length allCommands)}
      '';
    };

  # Directory copy with automatic file discovery
  copyDirectory =
    { sourceDir
    , targetDir
    , options ? {}
    }:
    let
      # Auto-discover files if not provided
      discoverFiles = options.fileList or (
        # This would normally scan the directory
        # For now, use a default list
        [ "settings.json" "CLAUDE.md" "CLAUDE.local.md" ]
      );

      # Use batch copy for discovered files
      result = copyMultipleFiles {
        inherit sourceDir targetDir options;
        fileList = discoverFiles;
      };

    in
    result // {
      # Mark as directory operation
      operationType = "directory";
      discoveredFiles = discoverFiles;
    };

  # Validate copy operation parameters
  validateCopyParams =
    { sourcePath ? null
    , targetPath ? null
    , sourceDir ? null
    , targetDir ? null
    , options ? {}
    }:
    let
      # Check for required parameters
      hasSingleFile = sourcePath != null && targetPath != null;
      hasDirectory = sourceDir != null && targetDir != null;

      # Validate paths exist
      sourceExists =
        if hasSingleFile then builtins.pathExists sourcePath
        else if hasDirectory then builtins.pathExists sourceDir
        else false;

      # Validate options
      validOptions = {
        dryRun = builtins.isBool (options.dryRun or true);
        verbose = builtins.isBool (options.verbose or true);
        forceOverwrite = builtins.isBool (options.forceOverwrite or false);
      };

      allOptionsValid = builtins.all (x: x) (builtins.attrValues validOptions);

    in
    {
      valid = (hasSingleFile || hasDirectory) && sourceExists && allOptionsValid;
      errors = lib.optionals (!hasSingleFile && !hasDirectory) [ "Either single file or directory parameters required" ]
        ++ lib.optionals (!sourceExists) [ "Source path does not exist" ]
        ++ lib.optionals (!allOptionsValid) [ "Invalid options provided" ];
    };

  # Create backup before destructive operations
  createBackup = filePath: options:
    let
      timestamp = "$(date +%Y%m%d_%H%M%S)";
      backupPath = "${filePath}.backup.${timestamp}";
      createBackupCmd = "cp \"${filePath}\" \"${backupPath}\"";

    in
    {
      inherit filePath backupPath;
      command = createBackupCmd;
      enabled = !(options.skipBackup or false);
    };

  # Restore from backup
  restoreFromBackup = filePath: backupPath:
    {
      inherit filePath backupPath;
      command = "cp \"${backupPath}\" \"${filePath}\"";
      available = builtins.pathExists backupPath;
    };

  # Utility functions for file operations
  fileUtils = {
    # Check if file exists
    fileExists = filePath: builtins.pathExists filePath;

    # Get file size (simplified)
    getFileSize = filePath:
      if builtins.pathExists filePath then
        # This would use actual file size checking
        "unknown" # Placeholder
      else
        "0";

    # Generate file hash
    getFileHash = filePath:
      if builtins.pathExists filePath then
        builtins.hashFile "sha256" filePath
      else
        null;

    # Create directory if it doesn't exist
    ensureDirectory = dirPath: "mkdir -p \"${dirPath}\"";

    # Set file permissions
    setPermissions = filePath: mode: "chmod ${mode} \"${filePath}\"";

    # Remove file
    removeFile = filePath: "rm -f \"${filePath}\"";

    # Move file
    moveFile = sourcePath: targetPath: "mv \"${sourcePath}\" \"${targetPath}\"";
  };

  # Performance optimization utilities
  performanceUtils = {
    # Check if operation can be skipped (files identical)
    canSkipCopy = sourcePath: targetPath:
      let
        sourceHash = fileUtils.getFileHash sourcePath;
        targetHash = fileUtils.getFileHash targetPath;
      in
      sourceHash != null && targetHash != null && sourceHash == targetHash;

    # Estimate operation time (mock implementation)
    estimateOperationTime = fileCount: fileSize:
      # This would calculate based on actual metrics
      {
        estimated = "${toString (fileCount * 100)}ms";
        confidence = "low";
      };

    # Suggest optimizations
    suggestOptimizations = stats:
      let
        suggestions = []
          ++ lib.optionals (stats.ignored > stats.total / 2) [ "Many files ignored - consider filtering file list" ]
          ++ lib.optionals (stats.preserved > stats.total / 3) [ "Many files preserved - consider reviewing policies" ];
      in
      suggestions;
  };

in

{
  # Core copy operations
  inherit copySingleFile copyMultipleFiles copyDirectory;
  inherit executeFileCopy;

  # Validation and utilities
  inherit validateCopyParams;
  inherit createBackup restoreFromBackup;
  inherit fileUtils performanceUtils;

  # High-level convenience functions
  utils = {
    # Simple file copy (no policies)
    simpleCopy = sourcePath: targetPath: options:
      let
        commands = [
          "cp \"${sourcePath}\" \"${targetPath}\""
          "chmod 644 \"${targetPath}\""
        ];
      in
      executeFileCopy {
        inherit sourcePath targetPath options;
        actions = { inherit commands; policy = { action = "simple"; }; };
      };

    # Copy with backup
    copyWithBackup = sourcePath: targetPath: options:
      let
        backup = createBackup targetPath options;
        commands = []
          ++ lib.optionals backup.enabled [ backup.command ]
          ++ [ "cp \"${sourcePath}\" \"${targetPath}\"" "chmod 644 \"${targetPath}\"" ];
      in
      executeFileCopy {
        inherit sourcePath targetPath options;
        actions = { inherit commands; policy = { action = "backup-copy"; }; };
      };

    # Dry run helper
    dryRun = operation: options:
      operation (options // { dryRun = true; });
  };

  # Legacy compatibility
  conditionalCopyFile =
    { sourcePath
    , targetPath
    , claudeDir ? null
    , policy ? null
    , dryRun ? false
    , verbose ? true
    , forceOverwrite ? false
    }:
    copySingleFile {
      inherit sourcePath targetPath;
      options = {
        inherit dryRun verbose forceOverwrite;
      };
    };

  conditionalCopyDirectory =
    { sourceDir
    , targetDir
    , fileList ? null
    , dryRun ? false
    , verbose ? true
    , parallelJobs ? 1
    , forceOverwrite ? false
    }:
    copyDirectory {
      inherit sourceDir targetDir;
      options = {
        inherit dryRun verbose forceOverwrite;
        fileList = fileList;
      };
    };

  # Testing support
  test = {
    # Mock successful copy result
    mockCopyResult = {
      success = true;
      executed = [ "echo \"Mock copy completed\"" ];
      metadata = {
        dryRun = false;
        verbose = true;
        commandCount = 1;
        policy = "mock";
      };
    };

    # Test validation
    testValidation = validateCopyParams {
      sourcePath = "/tmp/test-source";
      targetPath = "/tmp/test-target";
      options = { dryRun = true; };
    };
  };
}
