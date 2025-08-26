---
name: flow
description: "Plan generator - creates phase-based execution plans for /do-plan"
agents: [system-architect]
---

# /flow - Plan Generator

**Purpose**: 요구사항을 받아서 `/do-plan`이 실행할 수 있는 Phase별 계획을 생성

## Core Workflow

```
/flow "feature" → Phase-based Plan → /do-plan → Execute
```

## Usage

```bash
/flow "user authentication"
/flow "fix database performance"  
/flow "add dark mode"
/flow "deploy to production"
```

## Output Format

`/do-plan`이 기대하는 정확한 형식으로 출력:

```
Phase 1: Foundation [Estimated: time]
- [ ] Specific actionable task
- [ ] Another task with clear criteria

Phase 2: Implementation [Estimated: time]
- [ ] Core functionality task
- [ ] Integration task

Phase 3: Quality [Estimated: time]
- [ ] Testing task
- [ ] Documentation task
```

## Examples

### Feature Plan
```bash
Input: /flow "user login system"

Output:
Phase 1: Setup [2-3 hours]
- [ ] Install authentication dependencies
- [ ] Create user database table
- [ ] Set up environment variables

Phase 2: Implementation [1-2 days]  
- [ ] Build registration endpoint
- [ ] Create login/logout functionality
- [ ] Add password hashing

Phase 3: Integration [4-6 hours]
- [ ] Connect frontend login form
- [ ] Add auth middleware to routes
- [ ] Test user flows
```

### Bug Fix Plan
```bash
Input: /flow "fix slow queries"

Output:
Phase 1: Investigation [1-2 hours]
- [ ] Enable query logging
- [ ] Identify slow queries
- [ ] Analyze execution plans

Phase 2: Optimization [3-4 hours]
- [ ] Add database indexes
- [ ] Fix N+1 queries
- [ ] Implement caching

Phase 3: Validation [1 hour]
- [ ] Run performance tests
- [ ] Monitor improvements
```

## Key Features

- **Simple**: Just requirements → executable plan
- **Compatible**: Perfect `/do-plan` integration
- **Focused**: Plan generation only, execution handled by `/do-plan`

---

**The Missing `/plan` Command**: `/flow` generates the structured plans that `/do-plan` needs to execute
