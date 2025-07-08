{ lib, pkgs }:

let
  # File hash calculation utility
  calculateFileHash = filePath:
    if builtins.pathExists filePath then
      builtins.hashFile "sha256" filePath
    else
      null;

  # Compare two files by hash
  compareFileHashes = sourcePath: targetPath:
    let
      sourceHash = calculateFileHash sourcePath;
      targetHash = calculateFileHash targetPath;
    in
    {
      sourceHash = sourceHash;
      targetHash = targetHash;
      identical = sourceHash == targetHash;
      sourceExists = sourceHash != null;
      targetExists = targetHash != null;
    };

  # Core detection logic - reusable function to avoid duplication
  detectFileChangesCore = sourcePath: targetPath:
    let
      hashComparison = compareFileHashes sourcePath targetPath;
      userModified =
        if !hashComparison.targetExists then false
        else if !hashComparison.sourceExists then true
        else !hashComparison.identical;
      details = {
        originalHash = hashComparison.sourceHash;
        currentHash = hashComparison.targetHash;
        fileExists = hashComparison.targetExists;
        sourceExists = hashComparison.sourceExists;
        identical = hashComparison.identical;
      };
      changeType =
        if !hashComparison.sourceExists then "source-missing"
        else if !hashComparison.targetExists then "new-file"
        else if hashComparison.identical then "no-change"
        else "modified";
    in
    {
      inherit sourcePath targetPath userModified details changeType;
    };

in

{
  # Detect changes in a single file
  detectFileChanges = sourcePath: targetPath:
    detectFileChangesCore sourcePath targetPath;

  # Compare files using external tools for more detailed analysis
  compareFiles = sourcePath: targetPath:
    let
      baseComparison = compareFileHashes sourcePath targetPath;
    in
    baseComparison // {
      # Extended comparison using file utilities
      detailedComparison = pkgs.runCommand "file-comparison" { } ''
        mkdir -p $out

        # Basic file info
        if [ -f "${sourcePath}" ]; then
          stat "${sourcePath}" > $out/source-stat.txt 2>/dev/null || echo "source file not accessible" > $out/source-stat.txt
          wc -l "${sourcePath}" > $out/source-lines.txt 2>/dev/null || echo "0" > $out/source-lines.txt
        fi

        if [ -f "${targetPath}" ]; then
          stat "${targetPath}" > $out/target-stat.txt 2>/dev/null || echo "target file not accessible" > $out/target-stat.txt
          wc -l "${targetPath}" > $out/target-lines.txt 2>/dev/null || echo "0" > $out/target-lines.txt
        fi

        # Generate diff if both files exist
        if [ -f "${sourcePath}" ] && [ -f "${targetPath}" ]; then
          ${pkgs.diffutils}/bin/diff -u "${sourcePath}" "${targetPath}" > $out/diff.txt 2>/dev/null || true
        fi
      '';
    };

  # Analyze changes across multiple files in a directory
  analyzeBatchChanges = sourceDir: targetDir: fileList:
    let
      # Process each file in the list
      fileResults = builtins.listToAttrs (map (fileName:
        let
          sourcePath = "${sourceDir}/${fileName}";
          targetPath = "${targetDir}/${fileName}";
          detection = detectFileChangesCore sourcePath targetPath;
        in
        {
          name = fileName;
          value = detection;
        }
      ) fileList);

      # Calculate summary statistics
      totalFiles = builtins.length fileList;
      modifiedFiles = builtins.length (builtins.filter (fileName:
        (fileResults.${fileName}).userModified
      ) fileList);
      newFiles = builtins.length (builtins.filter (fileName:
        (fileResults.${fileName}).changeType == "new-file"
      ) fileList);
      unchangedFiles = builtins.length (builtins.filter (fileName:
        (fileResults.${fileName}).changeType == "no-change"
      ) fileList);

    in
    {
      inherit sourceDir targetDir fileList fileResults;

      # Summary statistics
      summary = {
        total = totalFiles;
        modified = modifiedFiles;
        new = newFiles;
        unchanged = unchangedFiles;
        missing = totalFiles - modifiedFiles - newFiles - unchangedFiles;
      };
    };

  # Generate a comprehensive change report
  generateChangeReport = analysisResult:
    let
      reportLines = [
        "=== File Change Analysis Report ==="
        "Source Directory: ${analysisResult.sourceDir}"
        "Target Directory: ${analysisResult.targetDir}"
        ""
        "Summary:"
        "  Total files: ${toString analysisResult.summary.total}"
        "  Modified files: ${toString analysisResult.summary.modified}"
        "  New files: ${toString analysisResult.summary.new}"
        "  Unchanged files: ${toString analysisResult.summary.unchanged}"
        "  Missing files: ${toString analysisResult.summary.missing}"
        ""
        "Detailed Results:"
      ] ++ (builtins.concatMap (fileName:
        let
          result = analysisResult.fileResults.${fileName};
        in
        [
          "  ${fileName}: ${result.changeType}"
          (if result.userModified then "    User modified: YES" else "    User modified: NO")
        ]
      ) analysisResult.fileList);

    in
    builtins.concatStringsSep "\n" reportLines;

  # Utility functions
  utils = {
    # Check if a file has been modified since a reference timestamp
    isModifiedSince = filePath: timestamp:
      if !builtins.pathExists filePath then false
      else
        let
          # Use stat to get modification time (simplified approach)
          statResult = pkgs.runCommand "check-mtime" { } ''
            if [ -f "${filePath}" ]; then
              stat -c %Y "${filePath}" > $out 2>/dev/null || echo "0" > $out
            else
              echo "0" > $out
            fi
          '';
        in
        # This is a simplified check - in practice, you'd compare with the timestamp
        true;

    # Generate a quick hash for a string (for testing purposes)
    quickHash = content:
      builtins.hashString "sha256" content;

    # Get file extension
    getFileExtension = filePath:
      let
        baseName = builtins.baseNameOf filePath;
        parts = lib.splitString "." baseName;
      in
      if builtins.length parts > 1 then
        builtins.elemAt parts (builtins.length parts - 1)
      else
        "";

    # Check if file is a configuration file based on extension
    isConfigFile = filePath:
      let
        baseName = builtins.baseNameOf filePath;
        parts = lib.splitString "." baseName;
        ext = if builtins.length parts > 1 then
          builtins.elemAt parts (builtins.length parts - 1)
        else
          "";
        configExts = [ "json" "yaml" "yml" "toml" "ini" "conf" "cfg" "md" ];
      in
      builtins.elem ext configExts;
  };

  # Legacy compatibility (maps to the old interface)
  legacyCompareFiles = sourcePath: targetPath:
    detectFileChangesCore sourcePath targetPath;
  detectClaudeConfigChanges = targetDir: sourceDir:
    let
      # Default Claude config files
      defaultFiles = [ "settings.json" "CLAUDE.md" ];

      # Use shared core detection logic
      fileResults = builtins.listToAttrs (map (fileName:
        let
          sourcePath = "${sourceDir}/${fileName}";
          targetPath = "${targetDir}/${fileName}";
          detection = detectFileChangesCore sourcePath targetPath;
        in
        {
          name = fileName;
          value = detection;
        }
      ) defaultFiles);

      totalFiles = builtins.length defaultFiles;
      modifiedFiles = builtins.length (builtins.filter (fileName:
        (fileResults.${fileName}).userModified
      ) defaultFiles);
      newFiles = builtins.length (builtins.filter (fileName:
        (fileResults.${fileName}).changeType == "new-file"
      ) defaultFiles);
      unchangedFiles = builtins.length (builtins.filter (fileName:
        (fileResults.${fileName}).changeType == "no-change"
      ) defaultFiles);
    in
    {
      inherit sourceDir targetDir;
      fileList = defaultFiles;
      inherit fileResults;

      summary = {
        total = totalFiles;
        modified = modifiedFiles;
        new = newFiles;
        unchanged = unchangedFiles;
        missing = totalFiles - modifiedFiles - newFiles - unchangedFiles;
      };
    };
}
