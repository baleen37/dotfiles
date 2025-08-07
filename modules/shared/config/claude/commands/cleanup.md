# /cleanup - Code and System Cleanup Automation

Universal codebase and project environment cleanup to improve maintainability

## Core Features

### 📁 Universal Project Cleanup
- **Temp Files**: .tmp, .bak, .swp, .DS_Store and other project temporary files
- **Log Files**: Development/debugging logs, build logs cleanup
- **Cache Files**: node_modules/.cache, .pytest_cache, __pycache__ etc.
- **Build Artifacts**: dist/, build/, target/ and other build outputs

### 🔧 Config File Cleanup  
- **Backup Files**: .backup, .orig, .old extension files
- **Duplicate Configs**: Detect and cleanup identical configuration duplicates
- **Unused Configs**: Identify unreferenced configuration files

### 💻 Code Cleanup
- **Unused Imports**: Remove unnecessary imports through AST analysis
- **Dead Code**: Detect uncalled functions, classes, variables
- **Duplicate Code**: Identify identical logic blocks and suggest refactoring
- **Comment Cleanup**: Clean up outdated TODOs and meaningless comments

### 🛡️ Safety Guarantees
- **Risk Assessment**: Analyze file/code importance before deletion
- **Backup Creation**: Auto-generate backups before cleanup
- **Staged Execution**: Sequential cleanup from low-risk to high-risk
- **Recovery Feature**: Instant rollback if issues occur

## Usage

### Basic Usage
```bash
/cleanup                    # Full project cleanup
/cleanup cache              # Cache files only
/cleanup config             # Config files only  
/cleanup code src/          # Specific directory code cleanup
```

### Advanced Options
```bash
/cleanup --dry-run          # Preview cleanup targets without execution
/cleanup --safe             # Safe files only (default)
/cleanup --aggressive       # More aggressive cleanup (use carefully)
/cleanup --backup           # Create backup before cleanup
```

### Language-Specific
```bash
/cleanup --js               # JavaScript/TypeScript project specialized
/cleanup --python           # Python project specialized  
/cleanup --rust             # Rust project specialized
/cleanup --go               # Go project specialized
```

## Execution Process

1. **Project Analysis**: Auto-detect language, framework, build system
2. **Cleanup Target Identification**: Scan temp files, cache, unused code
3. **Risk Assessment**: Evaluate deletion safety for each file/code
4. **Backup Creation**: Auto-backup high-importance files
5. **Staged Cleanup**: Sequential execution from safe to risky
6. **Result Reporting**: Report cleaned content and space saved

## Safety Mechanisms

- **Git Tracking**: Clean only files not tracked by Git
- **Whitelist**: Protection list for important config files
- **Confirmation Requests**: User confirmation for high-risk operations
- **Rollback Support**: Instant recovery if issues occur after cleanup
