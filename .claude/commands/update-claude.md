# /update-claude: Claude Configuration Auto-Optimizer

ABOUTME: Automated lint fixes, link validation, and structural optimization for Claude configuration files

## Overview

Automated quality management tool for Claude configuration ecosystem (agents, commands, CLAUDE.md).
Automatically fixes markdown lint errors, broken reference links, missing headers, and maintains consistency across configuration files.

## Usage

```bash
/update-claude
```

Single command performs comprehensive quality checks and automatic fixes for all Claude configurations.

## Automatic Fixes

### Markdown Quality Improvements

- **MD022**: Header spacing errors (e.g., `##Title` → `## Title`)
- **MD025**: Duplicate H1 headers removal
- **Missing ABOUTME**: Add description headers to command files
- **Broken @references**: Fix non-existent file references

### Configuration Optimization

- **Agent Templates**: Consistent structure and required field validation
- **Command Formatting**: Standardized usage patterns and examples
- **Deduplication**: Merge identical content sections
- **Dead Code**: Remove unused settings and references

### Cross-Reference Validation

- **File Existence**: Verify @referenced files actually exist
- **Link Integrity**: Validate agents ↔ commands cross-references
- **Circular References**: Prevent infinite reference loops

## Fix Examples

### Lint Error Correction

```markdown
# Before
##Installation Guide

# After  
## Installation Guide
```

### Reference Link Fixes

```markdown
# Before
See @missing-file.md for details

# After
See @RULES.md for details
```

### ABOUTME Header Addition

```markdown
# Before
# /analyze: Code Analysis Tool

# After
# /analyze: Code Analysis Tool

ABOUTME: Codebase analysis and improvement recommendations
```

### Agent Template Standardization

```markdown
# Before
Role: Backend development

# After
**Role**: Backend system development and API architecture
**Expertise**: Node.js, Python, PostgreSQL, Redis
**Use Cases**: API design, database optimization, microservices
```

## Processing Workflow

1. **Discovery**: Scan .claude/ and modules/shared/config/claude/ directories
2. **Analysis**: Detect lint errors, broken links, structural issues
3. **Fixing**: Direct file modifications using Edit/MultiEdit tools
4. **Verification**: Validate fixes and ensure integrity

## Safety Mechanisms

- **Read-first**: Assess file state before any modifications
- **Step-by-step validation**: Verify results after each fix
- **Git tracking**: All changes recorded in Git history
- **Fallback strategy**: Retry with Edit if MultiEdit fails
- **Incremental processing**: Handle one issue at a time safely

## Limitations

### Will Not Modify

- **Core Philosophy**: Fundamental CLAUDE.md principles and rules
- **Security Settings**: Permissions and access control configurations
- **User Customizations**: Personalized agent settings or commands
- **MCP Server Settings**: External MCP connection configurations

### Requires Approval

- **New Sections**: Adding previously non-existent structural elements
- **Feature Extensions**: Creating new automation rules
- **Major Restructuring**: File moves or comprehensive reorganization

## Tool Integration

**Claude Code Tools**:

- `Glob`: Configuration file pattern discovery
- `Grep`: Problem pattern search and validation
- `Read`: Current state analysis
- `Edit/MultiEdit`: Direct modification execution
- `Task`: Delegate complex optimizations to specialized agents

**Error Handling**:

- Retry with alternative tools on failure
- Delegate complex cases to Task tool with expert agents
- Read-first principle for safe state assessment

---
*Practical • Systematic • Safe*
