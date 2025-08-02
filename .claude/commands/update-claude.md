# /update-claude - Claude Code Configuration Update

Update Claude Code configuration simply and safely according to jito's pragmatic philosophy.

## Purpose
- **Simplicity First**: Only essential updates without complex options
- **Safety Guarantee**: Gradual improvements while adhering to Rule #1
- **Pragmatic Approach**: Eliminate unnecessary features following YAGNI

## Usage
```bash
/update-claude                   # Basic update (safe improvements only)
/update-claude --check           # Check what needs updating
/update-claude --safe            # Step-by-step approval mode
/update-claude --links           # Repair @reference links
```

## Automatic Check Scope

### Configuration File Validation
- **CLAUDE.md**: @reference integrity, Rule #1 compliance
- **MCP.md**: Server auto-execution logic verification  
- **SUBAGENT.md**: Task tool collaboration patterns
- **agents/*.md**: Required fields and structure verification
- **commands/*.md**: Usage consistency review

### Basic Validation Steps
1. **Structure Validation**: YAML headers, required sections check
2. **Reference Validation**: @link validity, circular reference prevention  
3. **Consistency Validation**: jito philosophy and convention compliance

## Automation Levels

### 🤖 Auto Execute (No approval needed)
- Typos and grammar fixes
- Broken @reference link repairs
- Duplicate content cleanup

### 🤝 Execute After Approval (jito confirmation required)  
- Configuration structure changes
- Workflow improvements
- New convention applications

### 🛑 Never Automate
- Rule #1 related changes
- Core philosophy modifications
- Security-related settings

## Complexity-Based Processing

### Simple (Direct handling)
```bash
/update-claude
```
Typos, link repairs - 1-2 step tasks

### Medium (TodoWrite utilization)  
```bash
/update-claude --safe
```
Structure changes, consistency reviews - 3-4 step tasks

### Complex (Task tool utilization)
```bash  
/update-claude --think
```
Full configuration ecosystem review, architecture improvements

## Practical Usage

### Daily Maintenance
```bash
/update-claude --check        # Quick status check
/update-claude               # Execute basic updates
```

### Regular Review
```bash
/update-claude --safe        # Comprehensive review in safe mode
/update-claude --links       # @reference system maintenance
```

### Problem Solving
```bash
/update-claude --check       # Diagnose issues
/update-claude --safe        # Fix safely
```

## Implementation

### Basic Validation Script
```bash
# Structure validation
grep -r "^---" .claude/ && echo "✅ YAML header check"
grep -r "## Purpose" .claude/commands/ && echo "✅ Purpose section check"

# @reference validation  
grep -r "@.*\.md" .claude/ | while read line; do
  # Link validity check and repair
done

# jito philosophy compliance check
grep -r "Rule #1\|YAGNI\|simplicity" .claude/ && echo "✅ Philosophy consistency check"
```

### Safe Update Process
1. Backup current state
2. Execute validation steps sequentially  
3. Stop immediately if issues found
4. Apply changes after jito approval

---

*Simple and safe Claude Code configuration management • Rule #1 absolute guarantee • YAGNI principle compliance*
