---
name: brainstorm
description: "Transform vague ideas into concrete requirements through codebase analysis and targeted questions"
mcp-servers: [sequential, context7]
tools: [Read, Grep, Glob, TodoWrite, Task]
---

# /brainstorm - Smart Requirements Discovery

**Purpose**: Convert fuzzy ideas into actionable specifications using codebase intelligence

## Usage

```bash
/brainstorm <idea>           # Full discovery with codebase analysis
/brainstorm --brief <idea>   # Quick requirements without interaction
/brainstorm --tech <idea>    # Technical architecture focus
```

## 3-Phase Process

### Phase 1: Codebase Intelligence

- Scan project files for tech stack, patterns, and architecture
- Detect existing tools, frameworks, and conventions
- Identify integration points and constraints
- Present findings: "Based on your codebase using [X, Y, Z], I see [patterns]"

### Phase 2: Essential Decisions

Ask 3 core questions with simple A/B/C choices:

**Platform**: Web app (A) | Mobile app (B) | CLI tool (C)
**Scale**: Personal/team (A) | Department (B) | Public (C)  
**Priority**: Speed (A) | Stability (B) | Features (C)

### Phase 3: Actionable Output

Generate structured deliverables:
- **User Stories**: "As [user], I want [goal] so that [benefit]"
- **Acceptance Criteria**: Specific, testable requirements
- **Priority Queue**: P0 (must have) → P1 (should have) → P2 (nice to have)
- **Next Steps**: Concrete tasks to start implementation

## MCP Integration

- **Sequential**: Systematic thinking through requirement analysis phases
- **Context7**: Tech stack validation and framework best practices

## Examples

```bash
/brainstorm "team task tracker"     # Full discovery with codebase scan
/brainstorm --tech "user auth"      # Technical implementation focus  
/brainstorm --brief "mobile idea"   # Quick spec without questions
```

## Workflow

1. **Codebase Scan**: Analyze existing code → present tech stack findings
2. **Quick Choices**: 3 A/B/C questions → capture core requirements  
3. **Structured Output**: Generate user stories + priorities + next steps
