---
name: plan
description: "Create implementation blueprints with LLM-ready code generation prompts"
tools: [TodoWrite, Task, Write]
---

# /plan - Code Generation Blueprint

**Purpose**: Draft a detailed, step-by-step blueprint for building this project. Break the plan into small, iterative chunks that build on each other, with specific prompts for code generation.

## Methodology

1. **Draft** detailed project blueprint
2. **Break down** into small, iterative chunks
3. **Review and refine** steps:
   - Small enough to implement safely
   - Big enough to move project forward
4. **Create prompts** for LLM to implement each step
5. **Prioritize** best practices and incremental progress
6. **Integrate** code without orphaned segments

## Output

Creates `plan.md` with implementation blueprint:

```markdown
# Project Implementation Plan

## Phase 1: Foundation
### Step 1.1: Project Setup
```code
Create basic project structure with package.json, .gitignore, and README.md
Initialize with essential dependencies for React and Node.js
```

### Step 1.2: Database Schema  
```code
Design and implement user table schema in PostgreSQL
Include fields: id, email, password_hash, created_at, updated_at
Create migration file and run initial setup
```

## Phase 2: Authentication
### Step 2.1: User Model
```code
Create User model with password hashing using bcrypt
Implement validation for email format and password strength
Add methods for password comparison and JWT token generation
```
```

## Key Requirements

### Code Generation Focus
- Each step includes specific prompts for LLM implementation
- Use ```code``` tags to mark prompt sections
- Include context about what's been built so far
- Ensure each prompt builds on previous work

### Integration Continuity  
- No orphaned code segments
- Clear interfaces between components
- Build each step on previous foundations
- Test integration at each step

### Step Sizing
- Small enough: implement safely without breaking things
- Big enough: meaningful progress toward project goals
- Review and iterate until steps feel right-sized

## Usage

```bash
/plan "Build a task management API with authentication"
```

The plan creates ready-to-use prompts that an LLM can implement step-by-step, with each phase building systematically on the previous work.
