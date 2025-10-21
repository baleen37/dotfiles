---
name: Generating Skills
description: Generates new Claude skills with proper structure, validation, and best practices. Use when creating new skills or improving existing skill workflows.
allowed-tools: [Read, Write, Bash, Glob, Grep]
---

# Skill Creator

Creates well-structured Claude skills following official best practices.

## Core Workflow

### 1. Analyze Requirements

When the user requests a new skill:

1. Extract skill name and purpose from request
2. Verify name uses gerund form (verb + -ing): "Processing PDFs", "Analyzing Code"
3. Confirm description is specific and explains WHEN to use the skill
4. Identify required tools the skill will need

### 2. Validate Inputs

Check that:

- **Name**: Under 64 characters, gerund form, no vague terms like "Helper" or "Utils"
- **Description**: Under 1024 characters, third person, includes usage triggers
- **Purpose**: Single, focused capability (not multi-purpose)

If inputs are unclear, ask the user for clarification.

### 3. Create Directory Structure

```bash
mkdir -p .claude/skills/{skill-name}/scripts
```

Create subdirectories as needed:

- `scripts/` - For utility scripts
- `templates/` - For template files (if needed)

### 4. Generate SKILL.md

Create the main skill file with:

**Required YAML Frontmatter:**

```yaml
---
name: {Gerund Form Name}
description: {Specific description with usage context}
allowed-tools: [{Tool1}, {Tool2}, ...]
---
```

**Core Content Structure:**

1. **Single-line Purpose Statement** - What this skill does
2. **Core Workflow Section** - Sequential steps Claude should follow
3. **Validation/Feedback Steps** - Error handling and quality checks
4. **Examples (Optional)** - Concrete input/output examples if needed

**Key Constraints:**

- Keep under 500 lines
- Only include information Claude doesn't already know
- Use consistent terminology throughout
- Be prescriptive, not open-ended
- Include explicit error handling steps

### 5. Apply Best Practices

**Conciseness:**

- Challenge each piece: "Does Claude really need this explanation?"
- Remove common knowledge Claude already has
- Move detailed examples to separate `reference.md` if > 500 lines

**Structure:**

- Use clear headings for workflow steps
- Number sequential steps
- Use bullet points for lists
- Use code blocks for examples with proper syntax highlighting

**Progressive Disclosure:**

- Core workflow in SKILL.md (< 500 lines)
- Detailed examples in `reference.md` (optional)
- Templates in `templates/` directory (optional)
- Scripts in `scripts/` directory (optional)

**Avoid:**

- Deeply nested file references
- Windows-style paths (use Unix `/` not `\`)
- Magic numbers without justification
- Time-sensitive information
- Offering too many options (be prescriptive)
- Punting error handling to Claude

### 6. Validation Checklist

Before completing, verify:

- [ ] Name uses gerund form (verb + -ing)
- [ ] Description is specific and in third person
- [ ] SKILL.md is under 500 lines
- [ ] Workflow is clear and sequential
- [ ] No unnecessary explanations
- [ ] Consistent terminology throughout
- [ ] References appropriate tools via allowed-tools
- [ ] Includes validation/feedback steps
- [ ] Unix-style paths only
- [ ] Error handling is explicit

### 7. Test Invocation

After creating the skill:

1. Describe a scenario that should trigger the skill
2. Verify Claude can access the skill
3. Check that workflow steps are clear and actionable
4. Iterate based on usage observations

## Skill Categories

Choose appropriate category for naming:

- **Processing**: Transform or analyze specific file types
- **Analyzing**: Deep inspection and reporting on code/systems
- **Debugging**: Systematic issue identification and resolution
- **Generating**: Create artifacts following patterns
- **Coordinating**: Orchestrate multi-step workflows
- **Validating**: Check quality, compliance, correctness

## Example Skill Structure

```yaml
---
name: Processing Test Results
description: Analyzes test output files and generates quality reports. Use when reviewing test execution results.
allowed-tools: [Read, Write, Bash]
---

# Test Results Processor

Analyzes test output and generates actionable quality reports.

## Core Workflow

### 1. Locate Test Files

1. Use Read to check for test output files
2. Identify test framework from file structure
3. Extract test results data

### 2. Analyze Results

1. Count total tests, passes, failures
2. Identify flaky tests (if multiple runs available)
3. Extract failure messages and stack traces

### 3. Generate Report

1. Create summary with pass/fail rates
2. List all failures with context
3. Suggest next steps based on failure patterns

### 4. Validate Output

1. Verify all test files were processed
2. Check report contains actionable information
3. Confirm no test results were missed
```

## Common Patterns

### File Processing Skills

```markdown
## Core Workflow

### 1. Validate Input
- Check file exists
- Verify file format

### 2. Process Content
- Extract data
- Transform as needed

### 3. Generate Output
- Write results
- Validate output
```

### Analysis Skills

```markdown
## Core Workflow

### 1. Gather Data
- Read relevant files
- Extract metrics

### 2. Analyze
- Apply analysis patterns
- Identify issues

### 3. Report Findings
- Summarize results
- Provide recommendations
```

### Code Generation Skills

```markdown
## Core Workflow

### 1. Understand Requirements
- Parse user request
- Identify patterns

### 2. Generate Code
- Follow project conventions
- Apply templates

### 3. Validate Output
- Check syntax
- Verify completeness
```

## Reference Files (Optional)

If SKILL.md exceeds 400 lines, create `reference.md`:

### Structure for reference.md

```markdown
# {Skill Name} Reference

## Detailed Examples

{Comprehensive examples with full context}

## Troubleshooting

{Common issues and solutions}

## Advanced Usage

{Complex scenarios and edge cases}

## Tool-Specific Guidance

{Detailed tool usage patterns}
```

Keep references one level deep from SKILL.md.

## Scripts (Optional)

For deterministic operations, create utility scripts in `scripts/`:

**Script Guidelines:**

- Include explicit error handling
- Use Unix-style paths
- Add helpful error messages
- Make scripts executable: `chmod +x scripts/script-name.sh`
- Document expected inputs/outputs

**Example Script:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# validate-skill.sh - Validates skill structure

SKILL_DIR="${1:?Error: Skill directory required}"

if [[ ! -f "$SKILL_DIR/SKILL.md" ]]; then
    echo "Error: SKILL.md not found in $SKILL_DIR"
    exit 1
fi

# Check line count
line_count=$(wc -l < "$SKILL_DIR/SKILL.md")
if [[ $line_count -gt 500 ]]; then
    echo "Warning: SKILL.md has $line_count lines (max: 500)"
    exit 1
fi

echo "Skill validation passed"
```

## Quality Standards

### Frontmatter Requirements

```yaml
---
name: {Must be gerund form, under 64 chars}
description: {Third person, specific purpose + usage context, under 1024 chars}
allowed-tools: [{Optional: list of permitted tools}]
---
```

### Content Requirements

1. **Clear Purpose** - Single sentence explaining what the skill does
2. **Sequential Workflow** - Numbered steps in logical order
3. **Validation Steps** - Explicit error checking and quality verification
4. **Consistent Terms** - Same terminology throughout
5. **Concrete Examples** - Show expected formats (when helpful)

### Anti-Patterns

Avoid these common mistakes:

- ❌ Vague names: "Helper Skill", "Utility Functions"
- ❌ Nested references: SKILL.md → reference.md → advanced.md → examples.md
- ❌ Too many options: "Choose A, B, C, or D..." (be prescriptive)
- ❌ Common knowledge: Explaining basic programming concepts
- ❌ Windows paths: `C:\Users\...` (use `/Users/...`)
- ❌ Magic numbers: `sleep 42` without explanation
- ❌ Vague errors: "Something went wrong" (be specific)
- ❌ Assuming tools: Check tool availability before use

## Testing Your Skill

After creation:

1. **Invoke Test** - Describe scenario that should trigger the skill
2. **Workflow Test** - Verify steps are clear and actionable
3. **Error Test** - Try edge cases and verify error handling
4. **Refinement** - Iterate based on actual usage

## Output Format

After creating the skill, provide:

1. **Success confirmation** with skill location
2. **Invocation trigger** - Example of what to say to trigger the skill
3. **Quick validation** - Confirm structure follows best practices

Example output:

```
✓ Created skill: .claude/skills/processing-test-results/SKILL.md
✓ Line count: 287 (within 500 limit)
✓ Validation: All checks passed

Invocation trigger: "Analyze the test results file"
```
