# Configuring Claude Code - Reference Guide

Detailed examples, templates, and advanced patterns for Claude Code configuration.

## Table of Contents

1. [Commands - Detailed Examples](#commands-detailed-examples)
2. [Agents - Configuration Patterns](#agents-configuration-patterns)
3. [Hooks - Advanced Use Cases](#hooks-advanced-use-cases)
4. [Skills - Complete Templates](#skills-complete-templates)
5. [Settings - Advanced Configuration](#settings-advanced-configuration)
6. [Real-World Examples](#real-world-examples)
7. [Troubleshooting Guide](#troubleshooting-guide)

---

## Commands - Detailed Examples

### Simple Command Template

```markdown
---
name: Run Quality Checks
tags: [quality, validation]
---

Run comprehensive quality checks on the codebase:

1. Run linter and fix auto-fixable issues
2. Run type checker
3. Run test suite
4. Generate coverage report

Report results in structured format.
```

### Command with Context Loading

```markdown
---
name: Review PR
tags: [git, review]
---

Review the current pull request:

1. Read PR description and linked issues
2. Analyze changed files for:
   - Code quality issues
   - Security vulnerabilities
   - Performance concerns
   - Test coverage
3. Check CI/CD status
4. Generate review comments

Use code-reviewer agent for detailed analysis.
```

### Multi-Step Workflow Command

```markdown
---
name: Deploy Feature
tags: [deployment, workflow]
---

Execute deployment workflow:

1. Verify current branch is deployment-ready
   - All tests passing
   - No uncommitted changes
   - Branch up to date with main
2. Create deployment tag
3. Build production artifacts
4. Run deployment validation
5. Create deployment PR with checklist

Stop at each step if validation fails.
```

### Integration Command

```markdown
---
name: Setup Dev Environment
tags: [setup, development]
---

Setup development environment for this project:

1. Check system prerequisites (Node.js, Docker, etc.)
2. Install dependencies (npm install / cargo build / etc.)
3. Setup environment variables (.env from .env.example)
4. Initialize database (run migrations)
5. Run smoke tests
6. Display "Ready to develop" status

Provide clear error messages for each failed step.
```

---

## Agents - Configuration Patterns

### Code Review Agent

```markdown
---
name: Security Auditor
description: Performs comprehensive security analysis of code changes. Use proactively when reviewing code for security vulnerabilities, authentication issues, or data exposure risks.
---

# Security Auditor Agent

Perform security-focused code review following OWASP guidelines.

## Core Workflow

1. **Input Validation Analysis**
   - Check for SQL injection vulnerabilities
   - Verify input sanitization
   - Review regex patterns for ReDoS

2. **Authentication & Authorization**
   - Verify authentication checks
   - Review authorization logic
   - Check session management

3. **Data Protection**
   - Identify exposed secrets
   - Review encryption usage
   - Check for sensitive data logging

4. **Dependencies**
   - Scan for known vulnerabilities
   - Review dependency updates
   - Check for deprecated packages

## Output Format

Provide findings in this structure:
- **Critical**: Immediate security risks
- **High**: Significant vulnerabilities
- **Medium**: Potential security improvements
- **Low**: Security best practice suggestions

Include code snippets and remediation steps for each finding.
```

### Feature Implementation Agent

```markdown
---
name: TDD Feature Builder
description: Implements features using test-driven development methodology. Use when building new features that require comprehensive testing and incremental development.
---

# TDD Feature Builder Agent

Implement features following strict TDD methodology.

## Workflow

1. **Requirements Analysis**
   - Clarify feature requirements
   - Identify acceptance criteria
   - Plan test scenarios

2. **Test Creation**
   - Write failing unit tests
   - Write failing integration tests
   - Document expected behavior

3. **Minimal Implementation**
   - Write minimal code to pass tests
   - Avoid over-engineering
   - Focus on requirement fulfillment

4. **Refactoring**
   - Improve code quality while keeping tests green
   - Extract reusable components
   - Optimize performance

5. **Validation**
   - Verify all tests pass
   - Check code coverage
   - Review against acceptance criteria

## Constraints

- Never write implementation before tests
- Keep changes minimal and focused
- Maintain test coverage above 80%
- Follow project coding standards
```

---

## Hooks - Advanced Use Cases

### Pre-Tool Use Validation Hook

```bash
#!/bin/bash
# .claude/hooks/validate-file-write.sh
# Validates file write operations before execution

set -euo pipefail

# Read JSON input from stdin
input=$(cat)

# Extract tool name and arguments
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.arguments.file_path // empty')

# Validation rules
if [[ -z "$file_path" ]]; then
  echo '{"error": "No file path provided"}' >&2
  exit 2
fi

# Block writes to protected directories
protected_dirs=("production" "secrets" ".git")
for dir in "${protected_dirs[@]}"; do
  if [[ "$file_path" == *"$dir"* ]]; then
    echo "{\"error\": \"Writing to protected directory: $dir\"}" >&2
    exit 2
  fi
done

# Block writes to sensitive files
if [[ "$file_path" =~ \.(env|key|pem|crt)$ ]]; then
  echo '{"error": "Cannot write to sensitive file type"}' >&2
  exit 2
fi

# Validation passed
exit 0
```

### Post-Tool Use Logging Hook

```bash
#!/bin/bash
# .claude/hooks/log-git-operations.sh
# Logs all git operations for audit trail

set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
command=$(echo "$input" | jq -r '.arguments.command // empty')

# Only log git operations
if [[ ! "$command" =~ ^git ]]; then
  exit 0
fi

# Log to file with timestamp
log_file="$CLAUDE_PROJECT_DIR/.claude/logs/git-operations.log"
mkdir -p "$(dirname "$log_file")"

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "$timestamp | $command" >> "$log_file"

exit 0
```

### Context Injection Hook

```bash
#!/bin/bash
# .claude/hooks/inject-project-context.sh
# Adds project-specific context to user prompts

set -euo pipefail

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.prompt')

# Load project context
project_context=$(cat "$CLAUDE_PROJECT_DIR/.claude/project-context.md")

# Inject context into prompt
enhanced_prompt="$user_prompt

## Project Context
$project_context"

# Return modified prompt
echo "{\"prompt\": $(echo "$enhanced_prompt" | jq -Rs .)}"
exit 0
```

### Notification Hook for CI/CD

```bash
#!/bin/bash
# .claude/hooks/notify-ci-status.sh
# Sends notifications on CI/CD events

set -euo pipefail

input=$(cat)
event_type=$(echo "$input" | jq -r '.type')
message=$(echo "$input" | jq -r '.message')

# Send to notification service (Slack, Discord, etc.)
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"CI Event: $event_type - $message\"}"

exit 0
```

---

## Skills - Complete Templates

### Minimal Skill Template

```yaml
---
name: Processing Log Files
description: Extracts and analyzes information from application log files. Use when investigating issues, analyzing patterns, or generating reports from logs.
allowed-tools: [Read, Grep, Bash]
---

# Processing Log Files

Extract insights from application logs.

## Core Workflow

1. **Identify log location** (ask user if not specified)
2. **Parse log format** (JSON, structured text, etc.)
3. **Extract relevant entries** based on criteria:
   - Time range
   - Error level
   - Specific patterns
4. **Analyze patterns**:
   - Error frequency
   - Common issues
   - Performance metrics
5. **Generate report** with findings and recommendations

## Validation

- Verify log file exists and is readable
- Confirm log format matches expected structure
- Validate time range if specified

## Success Criteria

- Key issues identified
- Patterns documented
- Actionable recommendations provided
```

### Comprehensive Skill Template

```yaml
---
name: Debugging Production Issues
description: Systematically debugs production issues using logs, metrics, and code analysis. Use when investigating production incidents, performance degradation, or unexpected behavior.
allowed-tools: [Read, Grep, Bash, WebFetch]
---

# Debugging Production Issues

Systematic production debugging workflow.

## Core Workflow

### 1. Issue Triage

- Gather initial information:
  - Error messages
  - Time of occurrence
  - Affected users/services
  - Reproduction steps
- Assess severity and impact

### 2. Log Analysis

- Collect relevant logs from affected timeframe
- Identify error patterns and stack traces
- Correlate events across services
- Extract debugging information

### 3. Metric Analysis

- Check system metrics (CPU, memory, network)
- Review application metrics (request rates, latency)
- Identify anomalies and correlations
- Compare with baseline

### 4. Code Analysis

- Review recent deployments
- Analyze relevant code paths
- Check for known issues
- Review related bug reports

### 5. Hypothesis Formation

- Develop theories based on evidence
- Prioritize by likelihood and impact
- Plan verification steps

### 6. Verification

- Test hypotheses systematically
- Collect additional evidence
- Refine understanding

### 7. Resolution Planning

- Document root cause
- Propose fixes (immediate and long-term)
- Identify prevention measures
- Create action items

## Validation

- All relevant logs reviewed
- Metrics analyzed for correlation
- Root cause identified (not just symptoms)
- Reproduction steps documented

## Success Criteria

- Root cause identified and documented
- Resolution plan with clear steps
- Prevention measures proposed
- Runbook updated for similar issues

## Reference

See [reference.md](reference.md) for detailed debugging techniques and tool usage.
```

---

## Settings - Advanced Configuration

### Multi-Environment Configuration

**Development (.claude/settings.local.json)**:

```json
{
  "permissions": {
    "allow": ["*"]
  },
  "env": {
    "ENVIRONMENT": "development",
    "DEBUG": "true",
    "API_ENDPOINT": "http://localhost:3000"
  },
  "model": "claude-sonnet-4-5"
}
```

**Production (.claude/settings.json)**:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Grep",
      "Glob",
      "Bash(git status)",
      "Bash(git diff)",
      "Bash(npm run lint)"
    ],
    "deny": [
      "Write(production/*)",
      "Edit(production/*)",
      "Bash(rm.*)",
      "Read(.env)",
      "Read(secrets/*)"
    ]
  },
  "env": {
    "ENVIRONMENT": "production",
    "DEBUG": "false"
  }
}
```

### Tool-Specific Permissions

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)",
      "Bash(docker ps)",
      "Bash(docker logs)",
      "Write(src/**/*.ts)",
      "Write(tests/**/*.test.ts)",
      "Edit(*.md)"
    ],
    "deny": [
      "Bash(sudo.*)",
      "Bash(rm -rf)",
      "Write(node_modules/*)",
      "Write(.git/*)",
      "Read(.env.production)"
    ]
  }
}
```

### Plugin Configuration

```json
{
  "plugins": {
    "mcp-context7": {
      "enabled": true,
      "config": {
        "cache_ttl": 3600
      }
    },
    "mcp-serena": {
      "enabled": true,
      "config": {
        "max_results": 50,
        "include_tests": true
      }
    }
  }
}
```

---

## Real-World Examples

### Example 1: Custom Git Workflow

**Command**: `.claude/commands/create-feature.md`

```markdown
---
name: Create Feature Branch
tags: [git, workflow]
---

Create new feature branch following project conventions:

1. Verify on main branch and up to date
2. Create branch: `feature/<issue-number>-<description>`
3. Push to remote with tracking
4. Create draft PR
5. Display next steps
```

**Hook**: PreToolUse validation for git operations

```bash
#!/bin/bash
# Ensure git operations follow workflow
input=$(cat)
command=$(echo "$input" | jq -r '.arguments.command // empty')

if [[ "$command" =~ git\ push.*--force[^-] ]]; then
  echo '{"error": "Force push without --force-with-lease is not allowed"}' >&2
  exit 2
fi
```

### Example 2: Code Quality Pipeline

**Skill**: `.claude/skills/ensuring-code-quality/SKILL.md`

```yaml
---
name: Ensuring Code Quality
description: Runs comprehensive code quality checks including linting, type checking, and testing. Use before commits or when validating code changes.
allowed-tools: [Bash, Read, Grep]
---

# Ensuring Code Quality

Run quality checks in sequence, stopping on failures.

## Workflow

1. **Formatting**
   - Run formatter (prettier, rustfmt, etc.)
   - Auto-fix issues

2. **Linting**
   - Run linter with auto-fix
   - Report unfixable issues

3. **Type Checking**
   - Run type checker
   - Report type errors

4. **Testing**
   - Run test suite
   - Generate coverage report
   - Fail if coverage below threshold

5. **Security**
   - Run security audit
   - Report vulnerabilities

## Success Criteria

All checks pass with no errors
```

**Agent**: `.claude/agents/code-reviewer.md`

```markdown
---
name: Code Quality Reviewer
description: Performs detailed code review focusing on maintainability, performance, and best practices. Use proactively after code changes.
---

Review code changes for quality issues using static analysis and pattern detection.

Provide specific, actionable feedback with code examples.
```

### Example 3: Documentation Generation

**Skill**: `.claude/skills/generating-api-docs/SKILL.md`

```yaml
---
name: Generating API Documentation
description: Generates API documentation from code comments and type definitions. Use when creating or updating API documentation.
allowed-tools: [Read, Write, Grep, Bash]
---

# Generating API Documentation

Extract API documentation from source code.

## Workflow

1. **Discover API endpoints**
   - Find route definitions
   - Extract HTTP methods and paths

2. **Extract metadata**
   - Parameter types and descriptions
   - Response schemas
   - Error codes

3. **Generate documentation**
   - OpenAPI/Swagger format
   - Markdown format
   - Include code examples

4. **Validate**
   - Check all endpoints documented
   - Verify examples are correct
   - Test links and references
```

---

## Troubleshooting Guide

### Configuration Not Loading

**Symptom**: Changes to configuration files not reflected in Claude behavior

**Diagnosis**:

```bash
# Check file syntax
cat .claude/settings.json | jq .  # Validate JSON

# Check file location
ls -la .claude/

# Verify settings hierarchy
cat ~/.claude/settings.json
cat .claude/settings.json
cat .claude/settings.local.json
```

**Solutions**:

- Fix JSON/YAML syntax errors
- Ensure files are in correct locations
- Check settings precedence (local overrides shared)
- Restart Claude Code session

### Hooks Not Executing

**Symptom**: Hooks defined in settings.json but not running

**Diagnosis**:

```bash
# Enable debug mode
claude --debug

# Check hook permissions
ls -l .claude/hooks/*.sh

# Test hook manually
echo '{"tool_name": "Write", "arguments": {"file_path": "test.txt"}}' | \
  .claude/hooks/your-hook.sh
```

**Solutions**:

- Make hooks executable: `chmod +x .claude/hooks/*.sh`
- Fix matcher patterns (use regex)
- Verify hook script exits correctly (0 or 2)
- Check hook timeout settings

### Skills Not Being Invoked

**Symptom**: Skill exists but Claude doesn't use it

**Diagnosis**:

- Read skill description
- Check for keywords that match use case
- Verify YAML frontmatter is valid

**Solutions**:

- Make description more specific and action-oriented
- Include trigger keywords in description
- Test invocation by describing exact use case
- Ensure skill name uses gerund form

### Permission Denied Errors

**Symptom**: Tool use blocked by permissions

**Diagnosis**:

```bash
# Check current permissions
cat .claude/settings.json | jq '.permissions'

# Check all settings files
for f in ~/.claude/settings.json .claude/settings.json .claude/settings.local.json; do
  echo "=== $f ==="
  cat "$f" 2>/dev/null | jq '.permissions' || echo "Not found"
done
```

**Solutions**:

- Add tool to `allow` list
- Remove tool from `deny` list
- Check for managed policy restrictions
- Use more specific patterns (e.g., `Bash(git.*)` instead of `Bash`)

### Agent Not Activating

**Symptom**: Agent defined but not being used for tasks

**Diagnosis**:

- Review agent description
- Check if task matches agent's stated purpose
- Verify agent file syntax

**Solutions**:

- Make description more specific about when to use
- Include specific keywords (e.g., "code review", "debugging")
- Test by explicitly requesting agent by name
- Ensure description is in third person

### Command Not Found

**Symptom**: `/command-name` not recognized

**Diagnosis**:

```bash
# List available commands
ls .claude/commands/

# Check file structure
cat .claude/commands/your-command.md
```

**Solutions**:

- Verify file is in `.claude/commands/` directory
- Ensure filename matches command name (kebab-case)
- Check YAML frontmatter syntax
- Verify `name` field in frontmatter

---

## Best Practices Summary

### Commands

- ✅ Use for manual workflows
- ✅ Include clear step-by-step instructions
- ✅ Tag appropriately for discoverability
- ❌ Don't use for autonomous tasks (use agents/skills)

### Agents

- ✅ One clear responsibility per agent
- ✅ Detailed autonomous workflow instructions
- ✅ Specific description for invocation matching
- ❌ Don't overlap with other agents

### Hooks

- ✅ Validate all inputs
- ✅ Use proper exit codes (0 or 2)
- ✅ Keep execution fast (set timeouts)
- ✅ Log important operations
- ❌ Never trust hook input data
- ❌ Don't block on long-running operations

### Skills

- ✅ Gerund naming ("Processing", "Analyzing")
- ✅ Under 500 lines in SKILL.md
- ✅ Progressive disclosure (reference.md)
- ✅ Clear when-to-use in description
- ❌ Don't include common knowledge
- ❌ Don't nest references deeply

### Settings

- ✅ Use specific permissions (not wildcards)
- ✅ Separate dev and prod configurations
- ✅ Document permission rationale
- ❌ Don't allow overly broad permissions
- ❌ Don't commit settings.local.json

---

## Migration Guide

### From Unstructured to Structured Configuration

**Before**: Ad-hoc instructions in CLAUDE.md

```markdown
# CLAUDE.md

When I ask you to create a feature:
1. Create branch
2. Write tests
3. Implement code
4. Create PR
```

**After**: Structured command

```markdown
# .claude/commands/create-feature.md
---
name: Create Feature
tags: [workflow, tdd]
---

Create feature following TDD workflow:
1. Create feature branch
2. Write failing tests
3. Implement minimal code
4. Refactor
5. Create PR
```

### From Manual to Automated Validation

**Before**: Manual checking

```bash
# Developer manually runs checks before commit
npm run lint
npm test
git commit
```

**After**: Hook-based validation

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git commit.*)",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-commit-checks.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Quick Reference

### File Locations

| Type     | Location                     | Naming                                 |
| -------- | ---------------------------- | -------------------------------------- |
| Commands | `.claude/commands/`          | `command-name.md`                      |
| Agents   | `.claude/agents/`            | `agent-name.md`                        |
| Hooks    | `.claude/hooks/`             | `hook-name.sh` (executable)            |
| Skills   | `.claude/skills/skill-name/` | `SKILL.md`                             |
| Settings | `.claude/`                   | `settings.json`, `settings.local.json` |

### Quick Commands

```bash
# Create command
cat > .claude/commands/my-command.md << 'EOF'
---
name: My Command
---
Instructions here
EOF

# Create agent
cat > .claude/agents/my-agent.md << 'EOF'
---
name: My Agent
description: What it does and when to use
---
Detailed instructions
EOF

# Create skill
mkdir -p .claude/skills/my-skill
cat > .claude/skills/my-skill/SKILL.md << 'EOF'
---
name: Doing Something
description: What it does and when to use
---
# Core workflow
EOF

# Create hook
cat > .claude/hooks/my-hook.sh << 'EOF'
#!/bin/bash
input=$(cat)
# Process input
exit 0
EOF
chmod +x .claude/hooks/my-hook.sh

# Update settings
cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": ["Read", "Write"]
  }
}
EOF
```

### Validation Commands

```bash
# Validate JSON
jq . .claude/settings.json

# Test hook
echo '{"test": "data"}' | .claude/hooks/hook.sh

# Count skill lines
wc -l .claude/skills/*/SKILL.md

# List all commands
ls .claude/commands/*.md | xargs -n1 basename -s .md

# Debug mode
claude --debug
```
