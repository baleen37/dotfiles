---
name: planning
description: "Flexible planning: requirement analysis → deep exploration → execution plan (project/feature/task level)"
agents: []
---

# /planning - Flexible Planning & Analysis

**Purpose**: Analyze requirements and create execution plans. Deep codebase exploration and strategic planning only.

## Process

1. **Analyze**: Break down requirements and scope
2. **Explore**: Deep codebase investigation  
3. **Plan**: Create concrete execution steps
4. **Deliver**: Present actionable plan


## Usage Examples

```bash
# Project-level planning
/planning "build user authentication system"
→ Presents phases, seeks approval

# Feature-level planning  
/planning "add rate limiting to API"
→ Creates implementation cycles, ready for /implement

# Task-level planning
/planning "fix login bug when email has spaces"
→ Provides immediate action plan, may proceed to implementation
```

## Output

- Clear implementation steps
- Technical approach and constraints  
- Success criteria
- Ready for `/implement`

## TDD Detection

When "TDD" or "test-first" mentioned, automatically plans test-driven approach.
