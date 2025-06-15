# Module Library System Reference

> **Advanced documentation for the sophisticated module library functions**

This document provides comprehensive coverage of the advanced Nix library functions available in `modules/shared/lib/`, which power the intelligent configuration management and file preservation systems.

## 📁 Library Overview

The module library system consists of three main components:

```
modules/shared/lib/
├── file-change-detector.nix     # 366 lines - File change detection system
├── claude-config-policy.nix     # 309 lines - Configuration preservation policies  
└── conditional-file-copy.nix    # Conditional file operations
```

These libraries implement sophisticated algorithms for:
- **SHA256-based change detection**: Track user modifications with cryptographic precision
- **Policy-driven preservation**: Intelligent decisions about when to preserve vs. update
- **Automated conflict resolution**: Handle configuration conflicts gracefully

## 🔍 file-change-detector.nix

### Purpose
A comprehensive system for detecting file modifications using SHA256 hashes, providing the foundation for intelligent configuration management.

### Core Functions

#### `calculateFileHash`
```nix
calculateFileHash = filePath:
  if builtins.pathExists filePath then
    builtins.hashFile "sha256" filePath
  else
    null;
```

**Usage:**
```nix
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  currentHash = detector.calculateFileHash "/path/to/file";
in
  # Use hash for comparisons
```

#### `compareFiles`
```nix
compareFiles = originalFilePath: currentFilePath: {
  # Returns comprehensive comparison data
  original = { path, exists, hash, size, timestamp };
  current = { path, exists, hash, size, timestamp };
  bothExist = true/false;
  userModified = true/false;
  identical = true/false;
  details = { hashChanged, sizeChanged, originalHash, currentHash, ... };
};
```

**Usage Example:**
```nix
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  comparison = detector.compareFiles
    "/source/settings.json"
    "/target/settings.json";
in
{
  # Check if user modified the file
  needsAttention = comparison.userModified;

  # Get detailed information
  changeDetails = comparison.details;

  # Make decisions based on results
  action = if comparison.userModified then "preserve" else "update";
}
```

#### `detectChangesInDirectory`
```nix
detectChangesInDirectory = sourceDir: targetDir: fileList: {
  fileResults = { /* per-file comparison results */ };
  summary = {
    total = 5;
    modified = 2;
    identical = 3;
    missing = 0;
    modificationRate = 40.0;
  };
  modifiedFiles = [ /* list of modified file results */ ];
  identicalFiles = [ /* list of identical file results */ ];
  missingFiles = [ /* list of missing file results */ ];
};
```

**Usage Example:**
```nix
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  results = detector.detectChangesInDirectory
    "/dotfiles/config/claude"
    "/home/user/.claude"
    ["settings.json" "CLAUDE.md" "commands/setup.md"];
in
{
  # Quick summary
  totalFiles = results.summary.total;
  modifiedCount = results.summary.modified;

  # Detailed analysis
  modifiedFiles = map (result: result.fileName) results.modifiedFiles;

  # For each file, decide what to do
  actions = lib.mapAttrs (fileName: result:
    if result.userModified then "preserve-and-notify"
    else "update-silently"
  ) results.fileResults;
}
```

#### `detectClaudeConfigChanges` (Specialized)
```nix
detectClaudeConfigChanges = claudeDir: sourceConfigDir: {
  # All standard detection results plus:
  claudeSpecific = {
    settingsModified = true/false;
    claudeMdModified = true/false;
    customCommands = [ /* list of user-added commands */ ];
    modifiedCommands = [ /* list of user-modified commands */ ];
  };
};
```

**Usage Example:**
```nix
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  claudeAnalysis = detector.detectClaudeConfigChanges
    "/home/user/.claude"
    "/dotfiles/config/claude";
in
{
  # Claude-specific insights
  settingsNeedMerge = claudeAnalysis.claudeSpecific.settingsModified;
  customCommandCount = lib.length claudeAnalysis.claudeSpecific.customCommands;

  # Standard file analysis
  overallModificationRate = claudeAnalysis.summary.modificationRate;
}
```

### Utility Functions

#### `formatDetectionReport`
Generates human-readable reports:
```nix
formatDetectionReport = detection: ''
  파일 변경 감지 결과:
  ================

  요약:
  - 전체 파일: 5개
  - 수정된 파일: 2개
  - 동일한 파일: 3개
  - 없는 파일: 0개
  - 수정률: 40%

  파일별 상태:
    settings.json: 수정됨 (ab12cd34...)
    CLAUDE.md: 동일함 (ef56gh78...)
    commands/setup.md: 수정됨 (ij90kl12...)
'';
```

#### `generateShellDetectionScript`
Creates bash scripts for shell-based detection:
```nix
generateShellDetectionScript = claudeDir: sourceDir: outputFile: ''
  #!/bin/bash
  # Generated shell script for file change detection
  # Outputs JSON results to specified file
'';
```

### Mock and Testing Support

#### `createMockDetection`
```nix
createMockDetection = {
  fileName ? "test.json";
  userModified ? false;
  originalHash ? "abc123";
  currentHash ? if userModified then "def456" else "abc123";
  # ... other options
}: { /* mock detection result */ };
```

**Usage in Tests:**
```nix
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  mockResult = detector.createMockDetection {
    fileName = "settings.json";
    userModified = true;
    originalHash = "abc123";
    currentHash = "def456";
  };
in
# Use mockResult for testing policy decisions
```

## 🛡️ claude-config-policy.nix

### Purpose
Implements intelligent policy decisions for configuration file management, determining when to preserve user changes vs. apply updates.

### Configuration Definitions

#### `claudeConfigFiles`
Defines metadata for known configuration files:
```nix
claudeConfigFiles = {
  "settings.json" = {
    path = "settings.json";
    source = "modules/shared/config/claude/settings.json";
    priority = "high";      # Always preserve user changes
    backup = true;
    notifyUser = true;
  };

  "CLAUDE.md" = {
    path = "CLAUDE.md";
    source = "modules/shared/config/claude/CLAUDE.md";
    priority = "high";      # Always preserve user changes
    backup = true;
    notifyUser = true;
  };

  "commands" = {
    path = "commands";
    source = "modules/shared/config/claude/commands";
    priority = "medium";    # Some files may be overwritten
    backup = true;
    notifyUser = true;
    isDirectory = true;
  };
};
```

#### `preservationPolicies`
Defines available preservation strategies:
```nix
preservationPolicies = {
  preserve = {
    action = "preserve";
    description = "사용자 수정 내용을 보존하고 새 버전을 .new 파일로 저장";
    createNewFile = true;
    createNotice = true;
    backup = true;
  };

  overwrite = {
    action = "overwrite";
    description = "새 버전으로 덮어쓰기하고 기존 파일을 백업";
    createNewFile = false;
    createNotice = false;
    backup = true;
  };

  ignore = {
    action = "ignore";
    description = "사용자 파일을 그대로 유지하고 아무것도 하지 않음";
    createNewFile = false;
    createNotice = false;
    backup = false;
  };
};
```

### Core Functions

#### `getPolicyForFile`
```nix
getPolicyForFile = filePath: userModified: options: {
  action = "preserve" | "overwrite" | "ignore";
  description = "Human-readable description";
  createNewFile = true/false;
  createNotice = true/false;
  backup = true/false;
  fileConfig = { /* original file configuration */ };
  isCustomFile = true/false;
  userModified = true/false;
  forceOverwrite = true/false;
};
```

**Decision Logic:**
1. **Custom files** (not in `claudeConfigFiles`): Always `ignore`
2. **Force overwrite mode**: All known files get `overwrite`
3. **User modified + high priority**: `preserve`
4. **User modified + medium/low priority**: `overwrite`
5. **User not modified**: `overwrite` (safe update)

**Usage Example:**
```nix
let
  policy = import ./modules/shared/lib/claude-config-policy.nix { inherit lib pkgs; };
  filePolicy = policy.getPolicyForFile
    "/home/user/.claude/settings.json"
    true                                # userModified
    { forceOverwrite = false; };        # options
in
{
  shouldPreserve = filePolicy.action == "preserve";
  needsNotification = filePolicy.createNotice;
  isUserCustomization = filePolicy.isCustomFile;
}
```

#### `generateActions`
```nix
generateActions = filePath: sourceFilePath: changeDetection: options: {
  # File paths
  filePath = "/target/file";
  sourceFilePath = "/source/file";
  newFilePath = "/target/file.new";
  noticePath = "/target/file.update-notice";
  backupPath = "/target/file.backup.20240106_143022";

  # Policy decision
  policy = { /* policy object */ };

  # Action flags
  preserve = true/false;
  overwrite = true/false;
  ignore = true/false;

  # Generated content
  noticeContent = "Human-readable notice text";
  commands = [ /* shell commands to execute */ ];
};
```

**Usage Example:**
```nix
let
  policy = import ./modules/shared/lib/claude-config-policy.nix { inherit lib pkgs; };
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };

  # First detect changes
  changes = detector.compareFiles "/source/settings.json" "/target/settings.json";

  # Then generate actions
  actions = policy.generateActions
    "/target/settings.json"
    "/source/settings.json"
    changes
    { forceOverwrite = false; };
in
{
  # Execute the actions
  shellScript = lib.concatStringsSep "\n" actions.commands;

  # Handle notifications
  userNotice = actions.noticeContent;

  # Check what will happen
  willPreserveUserChanges = actions.preserve;
}
```

#### `generateDirectoryPlan`
```nix
generateDirectoryPlan = claudeDir: sourceDir: changeDetections: options: {
  fileActions = [ /* list of action objects for each file */ ];
  preserveActions = [ /* actions that preserve user changes */ ];
  overwriteActions = [ /* actions that overwrite files */ ];
  ignoreActions = [ /* actions that ignore files */ ];

  summary = {
    total = 5;
    preserved = 2;
    overwritten = 2;
    ignored = 1;
  };

  shellScript = "#!/bin/bash\n# Complete script to execute all actions";
};
```

**Complete Workflow Example:**
```nix
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  policy = import ./modules/shared/lib/claude-config-policy.nix { inherit lib pkgs; };

  # Step 1: Detect all changes
  changes = detector.detectClaudeConfigChanges
    "/home/user/.claude"
    "/dotfiles/config/claude";

  # Step 2: Generate action plan
  plan = policy.generateDirectoryPlan
    "/home/user/.claude"
    "/dotfiles/config/claude"
    changes.fileResults
    { forceOverwrite = false; };

  # Step 3: Execute or analyze
  executionScript = plan.shellScript;
  preservedFiles = map (action: action.filePath) plan.preserveActions;
  updatedFiles = map (action: action.filePath) plan.overwriteActions;
in
{
  # Summary for user
  summary = "Will preserve ${toString plan.summary.preserved} files, update ${toString plan.summary.overwritten} files";

  # Files that need user attention
  requiresAttention = plan.preserveActions != [];

  # Ready-to-execute script
  inherit executionScript;
}
```

### Advanced Features

#### Force Overwrite Mode
```nix
# Normal mode - preserves user changes
normalOptions = { forceOverwrite = false; };

# Force mode - overwrites everything (except custom files)
forceOptions = { forceOverwrite = true; };

# Compare behaviors
normalPolicy = getPolicyForFile "settings.json" true normalOptions;
forcePolicy = getPolicyForFile "settings.json" true forceOptions;

# normalPolicy.action == "preserve"
# forcePolicy.action == "overwrite"
```

#### Notice Generation
```nix
generateNoticeMessage = filePath: policy: newFilePath: ''
  파일 업데이트 알림: settings.json

  사용자 수정 내용을 보존하고 새 버전을 .new 파일로 저장

  파일 위치:
  - 현재 파일: /home/user/.claude/settings.json (사용자 수정 버전)
  - 새 버전: /home/user/.claude/settings.json.new (dotfiles 최신 버전)

  변경 사항을 확인하고 수동으로 병합하세요:
    diff "/home/user/.claude/settings.json" "/home/user/.claude/settings.json.new"

  또는 수동 병합 도구를 사용하세요:
    nix run .#merge-claude-config

  이 알림을 확인한 후 삭제하세요:
    rm "/home/user/.claude/settings.json.update-notice"

  생성 시간: $(date)
'';
```

## 🔧 conditional-file-copy.nix

### Purpose
Provides conditional file operations based on detection and policy results.

### Key Features
- **Conditional copying**: Only copy when conditions are met
- **Permission preservation**: Maintain file permissions and ownership
- **Atomic operations**: Ensure file operations complete successfully or not at all
- **Integration hooks**: Work seamlessly with detection and policy systems

## 🛠️ Practical Integration Examples

### Example 1: Custom Module Using Libraries
```nix
# modules/shared/my-config-manager.nix
{ config, pkgs, lib, ... }:

let
  detector = import ../lib/file-change-detector.nix { inherit lib pkgs; };
  policy = import ../lib/claude-config-policy.nix { inherit lib pkgs; };

  cfg = config.programs.my-config-manager;
in
{
  options.programs.my-config-manager = {
    enable = lib.mkEnableOption "my-config-manager";
    sourceDir = lib.mkOption {
      type = lib.types.path;
      description = "Source directory for config files";
    };
    targetDir = lib.mkOption {
      type = lib.types.str;
      description = "Target directory for config files";
    };
    forceOverwrite = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force overwrite user modifications";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.my-config-sync = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Syncing configuration files..."

      # Detection phase
      echo "Detecting changes..."

      # Policy phase  
      echo "Applying policies..."

      # Execution phase
      echo "Executing file operations..."

      # This would use the library functions to generate
      # the actual shell commands for execution
    '';
  };
}
```

### Example 2: Testing with Mock Data
```nix
# tests/unit/my-policy-test.nix
{ pkgs }:

let
  detector = import ../../modules/shared/lib/file-change-detector.nix { inherit (pkgs) lib; inherit pkgs; };
  policy = import ../../modules/shared/lib/claude-config-policy.nix { inherit (pkgs) lib; inherit pkgs; };

  # Create mock scenarios
  mockModifiedFile = detector.createMockDetection {
    fileName = "settings.json";
    userModified = true;
  };

  mockIdenticalFile = detector.createMockDetection {
    fileName = "CLAUDE.md";
    userModified = false;
  };

  # Test policy decisions
  modifiedPolicy = policy.getPolicyForFile "settings.json" true { forceOverwrite = false; };
  identicalPolicy = policy.getPolicyForFile "CLAUDE.md" false { forceOverwrite = false; };

in
pkgs.runCommand "policy-test" {} ''
  echo "Testing policy decisions..."

  # Test that user modifications are preserved
  ${if modifiedPolicy.action == "preserve" then ''
    echo "✓ Modified files are preserved"
  '' else ''
    echo "✗ Modified files should be preserved"
    exit 1
  ''}

  # Test that identical files are updated
  ${if identicalPolicy.action == "overwrite" then ''
    echo "✓ Identical files are updated"
  '' else ''
    echo "✗ Identical files should be updated"
    exit 1
  ''}

  echo "All policy tests passed!"
  touch $out
''
```

### Example 3: Integration with Home Manager
```nix
# modules/shared/home-manager.nix - excerpt showing integration
{ config, pkgs, lib, ... }:

let
  detector = import ../lib/file-change-detector.nix { inherit lib pkgs; };
  policy = import ../lib/claude-config-policy.nix { inherit lib pkgs; };

  claudeDir = "${config.home.homeDirectory}/.claude";
  sourceDir = "modules/shared/config/claude";
in
{
  # Use the libraries in home-manager activation
  home.activation.claude-config-preservation = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # This is where the magic happens
    # The activation script uses the library functions
    # to intelligently manage configuration files

    echo "Managing Claude configuration with preservation..."

    # Detection and policy application would happen here
    # using the sophisticated library functions
  '';
}
```

## 🧪 Testing and Debugging

### Debug Mode
Both libraries include comprehensive debugging support:

```nix
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  policy = import ./modules/shared/lib/claude-config-policy.nix { inherit lib pkgs; };
in
{
  # Access debug utilities
  detectorDebug = detector.debug;
  policyDebug = policy.debug;

  # Test with mock data
  mockResults = detector.debug.mockResults.someModified;

  # Test policy decisions
  policyTest = policy.debug.showPolicy "/path/to/file" true { forceOverwrite = false; };
}
```

### Testing Force Overwrite
```nix
let
  policy = import ./modules/shared/lib/claude-config-policy.nix { inherit lib pkgs; };

  forceTest = policy.debug.testForceOverwrite "settings.json" true;
in
{
  # Compare normal vs force behavior
  normalAction = forceTest.normal.action;      # "preserve"
  forceAction = forceTest.force.action;        # "overwrite"
  behaviorDiffers = forceTest.differentBehavior; # true
}
```

## 📚 Advanced Usage Patterns

### Pattern 1: Custom File Types
```nix
# Extend the policy system for new file types
let
  policy = import ./modules/shared/lib/claude-config-policy.nix { inherit lib pkgs; };

  customFileConfig = {
    "my-custom.conf" = {
      path = "my-custom.conf";
      source = "config/my-custom.conf";
      priority = "high";
      backup = true;
      notifyUser = true;
    };
  };

  extendedClaudeConfigFiles = policy.claudeConfigFiles // customFileConfig;
in
# Use extended configuration
```

### Pattern 2: Batch Operations
```nix
# Process multiple directories with different policies
let
  detector = import ./modules/shared/lib/file-change-detector.nix { inherit lib pkgs; };
  policy = import ./modules/shared/lib/claude-config-policy.nix { inherit lib pkgs; };

  processDirectory = sourceDir: targetDir: options:
    let
      changes = detector.detectChangesInDirectory sourceDir targetDir ["config.json" "settings.yml"];
      plan = policy.generateDirectoryPlan targetDir sourceDir changes.fileResults options;
    in plan;

  claudePlan = processDirectory "/dotfiles/claude" "/home/user/.claude" { forceOverwrite = false; };
  appPlan = processDirectory "/dotfiles/app" "/home/user/.config/app" { forceOverwrite = true; };
in
{
  totalActions = claudePlan.summary.total + appPlan.summary.total;
  combinedScript = claudePlan.shellScript + "\n" + appPlan.shellScript;
}
```

### Pattern 3: Conditional Activation
```nix
# Only activate when changes are detected
{ config, pkgs, lib, ... }:

let
  detector = import ../lib/file-change-detector.nix { inherit lib pkgs; };

  hasChanges = let
    changes = detector.detectClaudeConfigChanges
      "${config.home.homeDirectory}/.claude"
      "modules/shared/config/claude";
  in changes.summary.modified > 0;
in
{
  home.activation.conditional-sync = lib.mkIf hasChanges (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Changes detected, processing..."
      # Only run when there are actual changes
    ''
  );
}
```

---

## 💡 Best Practices

1. **Always use detection before policy**: Never apply policies without first detecting actual changes
2. **Respect user customizations**: Use appropriate priority levels and preserve user-added files
3. **Test with mock data**: Use the built-in mock functions for comprehensive testing
4. **Handle edge cases**: Check for file existence, permissions, and error conditions
5. **Provide clear feedback**: Use the notice generation system to inform users about actions taken

## 🔗 Integration Points

These libraries integrate with:
- **Home Manager activation**: For applying configurations
- **merge-claude-config script**: For interactive conflict resolution  
- **auto-update-dotfiles script**: For automated system updates
- **Testing framework**: For validation and quality assurance

---

> **Note**: These libraries represent some of the most sophisticated Nix code in the repository. Take time to understand the patterns before extending them, and always test thoroughly with the provided mock data systems.
